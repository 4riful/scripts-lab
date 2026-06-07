#!/usr/bin/env bash
set -euo pipefail

CONFIG="${CONFIG:-/root/cliproxyapi/config.yaml}"
SERVICE="${SERVICE:-cliproxyapi}"
PORT="${PORT:-8317}"
API_KEY_COUNT="${API_KEY_COUNT:-3}"
EXPOSE_PUBLIC="${EXPOSE_PUBLIC:-yes}"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this as root."
  exit 1
fi

if [[ ! -f "$CONFIG" ]]; then
  echo "Config not found: $CONFIG"
  exit 1
fi

if ! command -v openssl >/dev/null 2>&1; then
  echo "openssl is required to generate keys."
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required to update $CONFIG safely."
  exit 1
fi

detect_public_ip() {
  local ip=""
  ip="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{
    for (i=1; i<=NF; i++) if ($i=="src") { print $(i+1); exit }
  }' || true)"

  if [[ -z "$ip" ]]; then
    ip="$(curl -4fsS https://api.ipify.org 2>/dev/null || true)"
  fi

  if [[ -z "$ip" ]]; then
    ip="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"
  fi

  echo "${ip:-UNKNOWN}"
}

restart_service() {
  if systemctl restart "$SERVICE" >/dev/null 2>&1; then
    systemctl status "$SERVICE" --no-pager || true
    return 0
  fi

  if systemctl --user restart "$SERVICE" >/dev/null 2>&1; then
    systemctl --user status "$SERVICE" --no-pager || true
    return 0
  fi

  echo "Could not restart $SERVICE automatically. Restart it manually after reviewing $CONFIG."
  return 1
}

PUBLIC_IP="$(detect_public_ip)"
BACKUP="${CONFIG}.bak.$(date +%Y%m%d-%H%M%S)"
cp "$CONFIG" "$BACKUP"

api_keys=()
for _ in $(seq 1 "$API_KEY_COUNT"); do
  api_keys+=("sk-$(openssl rand -hex 32)")
done

management_key="$(openssl rand -hex 32)"

case "${EXPOSE_PUBLIC,,}" in
  y|yes|true|1)
    host_value=""
    allow_remote="true"
    ;;
  n|no|false|0)
    host_value="127.0.0.1"
    allow_remote="false"
    ;;
  *)
    echo "EXPOSE_PUBLIC must be yes or no."
    exit 1
    ;;
esac

if [[ "$allow_remote" == "true" ]] && command -v ufw >/dev/null 2>&1; then
  ufw allow OpenSSH >/dev/null 2>&1 || ufw allow 22/tcp >/dev/null 2>&1 || true
  ufw allow "${PORT}/tcp" >/dev/null 2>&1 || true

  if ufw status | grep -qi "Status: inactive"; then
    ufw --force enable >/dev/null
  else
    ufw reload >/dev/null 2>&1 || true
  fi
fi

python3 - "$CONFIG" "$host_value" "$allow_remote" "$management_key" "${api_keys[@]}" <<'PY'
from pathlib import Path
import sys

config = Path(sys.argv[1])
host_value = sys.argv[2]
allow_remote = sys.argv[3]
management_key = sys.argv[4]
api_keys = sys.argv[5:]

lines = config.read_text().splitlines()


def section_end(items, start_index):
    i = start_index + 1
    while i < len(items):
        line = items[i]
        if line and not line.startswith((" ", "\t")):
            break
        i += 1
    return i


def replace_top_level_scalar(items, key, value):
    prefix = f"{key}:"
    replacement = f"{key}: {value}"
    for i, line in enumerate(items):
        if line.startswith(prefix) and not line.startswith((" ", "\t")):
            items[i] = replacement
            return items
    return [replacement] + items


def replace_top_level_list(items, key, values):
    prefix = f"{key}:"
    block = [prefix] + [f'  - "{value}"' for value in values]
    for i, line in enumerate(items):
        if line == prefix and not line.startswith((" ", "\t")):
            end = section_end(items, i)
            return items[:i] + block + items[end:]
    return items + ["", *block]


def set_mapping_value(items, section, key, value):
    section_prefix = f"{section}:"
    key_prefix = f"{key}:"

    for i, line in enumerate(items):
        if line == section_prefix and not line.startswith((" ", "\t")):
            end = section_end(items, i)
            for j in range(i + 1, end):
                stripped = items[j].strip()
                if stripped.startswith(key_prefix):
                    indent = items[j][: len(items[j]) - len(items[j].lstrip())] or "  "
                    items[j] = f"{indent}{key}: {value}"
                    return items
            return items[: i + 1] + [f"  {key}: {value}"] + items[i + 1 :]

    return items + ["", section_prefix, f"  {key}: {value}"]


host_yaml = '""' if host_value == "" else f'"{host_value}"'
lines = replace_top_level_scalar(lines, "host", host_yaml)
lines = replace_top_level_list(lines, "api-keys", api_keys)
lines = set_mapping_value(lines, "remote-management", "allow-remote", allow_remote)
lines = set_mapping_value(lines, "remote-management", "secret-key", f'"{management_key}"')

text = "\n".join(lines) + "\n"
if "your-api-key-" in text:
    raise SystemExit("Template API key still found in config after update.")

config.write_text(text)
PY

restart_service || true

echo
echo "Updated:       $CONFIG"
echo "Backup:        $BACKUP"
echo "VPS IP:        $PUBLIC_IP"
echo "API URL:       http://$PUBLIC_IP:$PORT"
echo "Management UI: http://$PUBLIC_IP:$PORT/management.html"
echo
echo "Client API keys:"
for key in "${api_keys[@]}"; do
  echo "  $key"
done
echo
echo "Management key:"
echo "  $management_key"
echo
echo "Use one client API key in OpenCode or any OpenAI-compatible client."
echo "Use the management key only for the CLIProxyAPI management UI."

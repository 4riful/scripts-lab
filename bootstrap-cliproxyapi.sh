#!/usr/bin/env bash
set -euo pipefail

CONFIG="${1:-${CONFIG:-}}"
SERVICE="${SERVICE:-cliproxyapi}"
PORT="${PORT:-8317}"
API_KEY_COUNT="${API_KEY_COUNT:-3}"
EXPOSE_PUBLIC="${EXPOSE_PUBLIC:-yes}"
INSTALL_IF_MISSING="${INSTALL_IF_MISSING:-yes}"
INSTALL_DIR="${INSTALL_DIR:-/root/cliproxyapi}"
COMPOSE_FILE="${COMPOSE_FILE:-}"
UPSTREAM_RAW="${UPSTREAM_RAW:-https://raw.githubusercontent.com/router-for-me/CLIProxyAPI/main}"

find_config() {
  local candidate=""
  local candidates=(
    "/root/cliproxyapi/config.yaml"
    "/root/CLIProxyAPI/config.yaml"
    "/root/CLI-Proxy-API/config.yaml"
    "/root/cli-proxy-api/config.yaml"
    "/opt/cliproxyapi/config.yaml"
    "/etc/cliproxyapi/config.yaml"
  )

  for candidate in "${candidates[@]}"; do
    if [[ -f "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  done

  candidate="$(find /root /opt /etc -maxdepth 4 -type f -name config.yaml 2>/dev/null | while read -r path; do
    if grep -Eq '^(api-keys|remote-management|host):' "$path" 2>/dev/null; then
      echo "$path"
      break
    fi
  done)"

  if [[ -n "$candidate" ]]; then
    echo "$candidate"
    return 0
  fi

  return 1
}

install_cli_proxy_api_files() {
  case "${INSTALL_IF_MISSING,,}" in
    y|yes|true|1) ;;
    *) return 1 ;;
  esac

  if ! command -v curl >/dev/null 2>&1; then
    echo "curl is required to download CLIProxyAPI files."
    return 1
  fi

  echo "CLIProxyAPI config not found. Downloading CLIProxyAPI files into $INSTALL_DIR ..."
  mkdir -p "$INSTALL_DIR/auths" "$INSTALL_DIR/logs"

  if [[ ! -f "$INSTALL_DIR/config.yaml" ]]; then
    curl -fsSL "$UPSTREAM_RAW/config.example.yaml" -o "$INSTALL_DIR/config.yaml"
  fi

  if [[ ! -f "$INSTALL_DIR/docker-compose.yml" ]]; then
    curl -fsSL "$UPSTREAM_RAW/docker-compose.yml" -o "$INSTALL_DIR/docker-compose.yml"
  fi

  CONFIG="$INSTALL_DIR/config.yaml"
  COMPOSE_FILE="$INSTALL_DIR/docker-compose.yml"
  echo "Downloaded config: $CONFIG"
  echo "Downloaded compose: $COMPOSE_FILE"
}

install_docker_if_needed() {
  if command -v docker >/dev/null 2>&1 && { docker compose version >/dev/null 2>&1 || command -v docker-compose >/dev/null 2>&1; }; then
    systemctl enable --now docker >/dev/null 2>&1 || true
    return 0
  fi

  if ! command -v apt-get >/dev/null 2>&1; then
    echo "Docker Compose is not installed. Install Docker manually, then run this script again."
    return 1
  fi

  echo "Docker Compose not found. Installing Docker from the distribution repositories ..."
  apt-get update
  apt-get install -y docker.io
  apt-get install -y docker-compose-plugin \
    || apt-get install -y docker-compose-v2 \
    || apt-get install -y docker-compose \
    || true
  systemctl enable --now docker >/dev/null 2>&1 || true

  if docker compose version >/dev/null 2>&1 || command -v docker-compose >/dev/null 2>&1; then
    return 0
  fi

  echo "Docker installed, but Docker Compose is still unavailable. Install Docker Compose manually, then run this script again."
  return 1
}

compose_up() {
  if docker compose version >/dev/null 2>&1; then
    CLI_PROXY_CONFIG_PATH="$CONFIG" \
    CLI_PROXY_AUTH_PATH="$(dirname "$CONFIG")/auths" \
    CLI_PROXY_LOG_PATH="$(dirname "$CONFIG")/logs" \
      docker compose -f "$COMPOSE_FILE" up -d
    return 0
  fi

  CLI_PROXY_CONFIG_PATH="$CONFIG" \
  CLI_PROXY_AUTH_PATH="$(dirname "$CONFIG")/auths" \
  CLI_PROXY_LOG_PATH="$(dirname "$CONFIG")/logs" \
    docker-compose -f "$COMPOSE_FILE" up -d
}

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this as root."
  exit 1
fi

if [[ -z "$CONFIG" ]]; then
  CONFIG="$(find_config || true)"
fi

if [[ -z "$CONFIG" || ! -f "$CONFIG" ]]; then
  install_cli_proxy_api_files || true
fi

if [[ -z "$CONFIG" || ! -f "$CONFIG" ]]; then
  echo "CLIProxyAPI config.yaml was not found."
  echo
  echo "Install/start CLIProxyAPI first so it creates a config.yaml, or rerun with the real config path:"
  echo "  CONFIG=/path/to/config.yaml $0"
  echo "  $0 /path/to/config.yaml"
  echo
  echo "To search manually:"
  echo "  find /root /opt /etc -name config.yaml 2>/dev/null"
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
  if [[ -z "$COMPOSE_FILE" && -f "$(dirname "$CONFIG")/docker-compose.yml" ]]; then
    COMPOSE_FILE="$(dirname "$CONFIG")/docker-compose.yml"
  fi

  if [[ -n "$COMPOSE_FILE" && -f "$COMPOSE_FILE" ]]; then
    if install_docker_if_needed; then
      compose_up
      return 0
    fi
  fi

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
echo "Key rotation:  generated fresh client keys and management key for this run"
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

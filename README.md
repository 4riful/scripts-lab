# scripts-lab

Collection of utility scripts for system setup, proxy management, bug bounty workflows, and notifications.

## Scripts

| Script | Description |
|--------|-------------|
| [`setup-terminal.sh`](setup-terminal.sh) | Automated terminal setup — installs Zsh, Oh My Zsh, plugins (autosuggestions, syntax-highlighting), optionally installs VS Code Server with systemd service, and configures UFW |
| [`wsl2-clash-proxy.sh`](wsl2-clash-proxy.sh) | Manage Clash proxy on WSL2 — detects WSL2 IP and starts/stops/checks proxy via `http_proxy`/`https_proxy` environment variables |
| [`url-fetcher.sh`](url-fetcher.sh) | Bug bounty URL gathering tool — uses `waybackurls` and `gau` to collect endpoints from a domain list, sorts unique results to `fetchedurls.txt` |
| [`send-to-chat.sh`](send-to-chat.sh) | Send files or results to Discord or Telegram using the `notify` provider config (`~/.config/notify/provider-config.yaml`) |
| [`bootstrap-cliproxyapi.sh`](bootstrap-cliproxyapi.sh) | Root-only CLIProxyAPI bootstrap for VPS use — downloads CLIProxyAPI files if missing, opens port `8317/tcp`, generates client API keys, sets the management key, binds the proxy, starts/restarts the service, and prints the OpenCode-ready URL |
| [`wsl2-storage-maintenance.md`](wsl2-storage-maintenance.md) | Guide for cleaning and compacting WSL2 VHDX disks on Windows 11 Home — includes cleanup steps, diskpart compaction, and full export/import rebuild |

## CLIProxyAPI VPS bootstrap

Use this on the VPS as `root`. Downloading the script avoids shell paste/heredoc corruption.

If CLIProxyAPI is not installed yet, the script downloads the official `config.example.yaml` and `docker-compose.yml` into `/root/cliproxyapi`, configures them, and starts the service with Docker Compose.

Every run generates fresh random client API keys and a fresh management key, then replaces the old values in `config.yaml`. Save the printed keys after each run.

```bash
mkdir -p /root/cliproxyapi
curl -fsSL https://raw.githubusercontent.com/4riful/scripts-lab/main/bootstrap-cliproxyapi.sh \
  -o /root/cliproxyapi/bootstrap-cliproxyapi.sh
chmod +x /root/cliproxyapi/bootstrap-cliproxyapi.sh
/root/cliproxyapi/bootstrap-cliproxyapi.sh
```

It updates `/root/cliproxyapi/config.yaml` by default. Override paths or behavior with environment variables if needed:

```bash
CONFIG=/root/cliproxyapi/config.yaml \
SERVICE=cliproxyapi \
PORT=8317 \
API_KEY_COUNT=3 \
EXPOSE_PUBLIC=yes \
INSTALL_IF_MISSING=yes \
INSTALL_DIR=/root/cliproxyapi \
/root/cliproxyapi/bootstrap-cliproxyapi.sh
```

If the script says `CLIProxyAPI config.yaml was not found`, CLIProxyAPI has not created a config at `/root/cliproxyapi/config.yaml` yet, or it is installed somewhere else. Find the real config and rerun with that path:

```bash
find /root /opt /etc -name config.yaml 2>/dev/null
/root/cliproxyapi/bootstrap-cliproxyapi.sh /path/to/config.yaml
```

After it runs, use the printed values in OpenCode or any OpenAI-compatible client:

- **Base URL:** `http://YOUR_VPS_IP:8317`
- **API key:** one of the generated client API keys

The management key is separate and should only be used at `/management.html`.

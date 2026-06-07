# scripts-lab

Collection of utility scripts for system setup, proxy management, bug bounty workflows, and notifications.

## Scripts

| Script | Description |
|--------|-------------|
| [`setup-terminal.sh`](setup-terminal.sh) | Automated terminal setup — installs Zsh, Oh My Zsh, plugins (autosuggestions, syntax-highlighting), optionally installs VS Code Server with systemd service, and configures UFW |
| [`wsl2-clash-proxy.sh`](wsl2-clash-proxy.sh) | Manage Clash proxy on WSL2 — detects WSL2 IP and starts/stops/checks proxy via `http_proxy`/`https_proxy` environment variables |
| [`url-fetcher.sh`](url-fetcher.sh) | Bug bounty URL gathering tool — uses `waybackurls` and `gau` to collect endpoints from a domain list, sorts unique results to `fetchedurls.txt` |
| [`send-to-chat.sh`](send-to-chat.sh) | Send files or results to Discord or Telegram using the `notify` provider config (`~/.config/notify/provider-config.yaml`) |
| [`bootstrap-cliproxyapi.sh`](bootstrap-cliproxyapi.sh) | Root-only CLIProxyAPI bootstrap for VPS use — opens port `8317/tcp`, generates client API keys, sets the management key, binds the proxy, restarts the service, and prints the OpenCode-ready URL |
| [`wsl2-storage-maintenance.md`](wsl2-storage-maintenance.md) | Guide for cleaning and compacting WSL2 VHDX disks on Windows 11 Home — includes cleanup steps, diskpart compaction, and full export/import rebuild |

## CLIProxyAPI VPS bootstrap

Use this on the VPS as `root`. Downloading the script avoids shell paste/heredoc corruption.

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
/root/cliproxyapi/bootstrap-cliproxyapi.sh
```

After it runs, use the printed values in OpenCode or any OpenAI-compatible client:

- **Base URL:** `http://YOUR_VPS_IP:8317`
- **API key:** one of the generated client API keys

The management key is separate and should only be used at `/management.html`.

# scripts-lab

Collection of utility scripts for system setup, proxy management, bug bounty workflows, and notifications.

## Scripts

| Script | Description |
|--------|-------------|
| [`setup-terminal.sh`](setup-terminal.sh) | Automated terminal setup — installs Zsh, Oh My Zsh, plugins (autosuggestions, syntax-highlighting), optionally installs VS Code Server with systemd service, and configures UFW |
| [`wsl2-clash-proxy.sh`](wsl2-clash-proxy.sh) | Manage Clash proxy on WSL2 — detects WSL2 IP and starts/stops/checks proxy via `http_proxy`/`https_proxy` environment variables |
| [`url-fetcher.sh`](url-fetcher.sh) | Bug bounty URL gathering tool — uses `waybackurls` and `gau` to collect endpoints from a domain list, sorts unique results to `fetchedurls.txt` |
| [`send-to-chat.sh`](send-to-chat.sh) | Send files or results to Discord or Telegram using the `notify` provider config (`~/.config/notify/provider-config.yaml`) |
| [`wsl2-storage-maintenance.md`](wsl2-storage-maintenance.md) | Guide for cleaning and compacting WSL2 VHDX disks on Windows 11 Home — includes cleanup steps, diskpart compaction, and full export/import rebuild |

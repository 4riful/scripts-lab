<div align="center">

# scripts-lab

Practical shell scripts for VPS bootstrap, WSL maintenance, proxy workflows, bug bounty URL collection, and chat notifications.

<p>
  <img src="https://img.shields.io/badge/Shell-Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white" alt="Bash">
  <img src="https://img.shields.io/badge/Linux-Operations-FCC624?style=for-the-badge&logo=linux&logoColor=111111" alt="Linux operations">
  <img src="https://img.shields.io/badge/WSL2-Windows%20Linux-0078D4?style=for-the-badge&logo=windows&logoColor=white" alt="WSL2">
  <img src="https://img.shields.io/badge/VPS-Automation-0EA5E9?style=for-the-badge&logo=digitalocean&logoColor=white" alt="VPS automation">
  <img src="https://img.shields.io/badge/Security-Workflow-111827?style=for-the-badge&logo=hackthebox&logoColor=9FEF00" alt="Security workflow">
</p>

<p>
  <a href="https://github.com/4riful/scripts-lab/stargazers"><img src="https://img.shields.io/github/stars/4riful/scripts-lab?style=flat-square&color=0EA5E9" alt="Stars"></a>
  <a href="https://github.com/4riful/scripts-lab/network/members"><img src="https://img.shields.io/github/forks/4riful/scripts-lab?style=flat-square&color=22C55E" alt="Forks"></a>
  <a href="https://github.com/4riful/scripts-lab/commits/main"><img src="https://img.shields.io/github/last-commit/4riful/scripts-lab?style=flat-square&color=6366F1" alt="Last commit"></a>
  <img src="https://img.shields.io/badge/scripts-7-111827?style=flat-square" alt="Script count">
</p>

Small scripts. Real use cases. No framework overhead.

</div>

---

## Overview

`scripts-lab` is a compact utility repo for repeatable tasks I do often: preparing fresh VPS boxes, making WSL behave, collecting bug bounty URLs, forwarding results to chat, and bootstrapping proxy/API services quickly.

The goal is simple: keep useful operational scripts documented, portable, and easy to run when I need them again.

## Script Index

| Script | Purpose | Best for |
|---|---|---|
| [`bootstrap-cliproxyapi.sh`](bootstrap-cliproxyapi.sh) | Bootstrap CLIProxyAPI, generate API keys, open firewall, start service | OpenCode/OpenAI-compatible proxy on VPS |
| [`install-sub2api.sh`](install-sub2api.sh) | Deploy Sub2API with Docker and UFW rules | Fast subscription API deployment |
| [`setup-terminal.sh`](setup-terminal.sh) | Install Zsh, Oh My Zsh, plugins, optional code-server, UFW | Fresh Linux/VPS terminal setup |
| [`wsl2-clash-proxy.sh`](wsl2-clash-proxy.sh) | Start, stop, and check Clash proxy variables inside WSL2 | WSL2 proxy workflow |
| [`url-fetcher.sh`](url-fetcher.sh) | Collect historical URLs using `waybackurls` and `gau` | Bug bounty endpoint discovery |
| [`send-to-chat.sh`](send-to-chat.sh) | Send result files to Telegram or Discord | Recon/result notification |
| [`wsl2-storage-maintenance.md`](wsl2-storage-maintenance.md) | Clean, compact, and rebuild WSL2 VHDX disks | Windows 11 Home WSL maintenance |

## Quick Clone

```bash
git clone https://github.com/4riful/scripts-lab.git
cd scripts-lab
```

## Safety Notes

<p>
  <img src="https://img.shields.io/badge/read-before_running-F97316?style=flat-square" alt="Read before running">
  <img src="https://img.shields.io/badge/root_changes-system_sensitive-DC2626?style=flat-square" alt="Root sensitive">
  <img src="https://img.shields.io/badge/secrets-never_commit-7C3AED?style=flat-square" alt="Never commit secrets">
</p>

- Read each script before running it on a server.
- Several scripts are intended for `root` and can change Docker, firewall, systemd, shell, or config files.
- Do not paste generated API keys, management keys, webhooks, bot tokens, or provider configs into public issues, commits, screenshots, or shared terminals.
- `bootstrap-cliproxyapi.sh` generates fresh API keys every run. Save the printed values immediately.

---

## Script Guides

### bootstrap-cliproxyapi.sh

<p>
  <img src="https://img.shields.io/badge/CLIProxyAPI-bootstrap-111827?style=flat-square" alt="CLIProxyAPI bootstrap">
  <img src="https://img.shields.io/badge/OpenCode-ready-0EA5E9?style=flat-square" alt="OpenCode ready">
  <img src="https://img.shields.io/badge/port-8317-22C55E?style=flat-square" alt="Port 8317">
</p>

One-shot CLIProxyAPI bootstrap for a clean VPS.

It downloads CLIProxyAPI config/compose files if missing, generates fresh API keys, enables remote access when requested, opens the API port, starts the container, and prints connection details for OpenCode or another OpenAI-compatible client.

**What it does**

- Downloads official CLIProxyAPI `config.example.yaml` and `docker-compose.yml` into `/root/cliproxyapi` if no config exists.
- Creates `/root/cliproxyapi/auths` and `/root/cliproxyapi/logs`.
- Replaces the active top-level `api-keys` block with fresh `sk-...` client keys.
- Sets `remote-management.secret-key` to a fresh management key.
- Sets `host: ""` and `remote-management.allow-remote: true` by default.
- Opens `8317/tcp` in UFW when public exposure is enabled.
- Installs Docker/Compose on apt-based systems if missing.
- Starts CLIProxyAPI through Docker Compose.

**Run on a VPS**

```bash
mkdir -p /root/cliproxyapi
curl -fsSL https://raw.githubusercontent.com/4riful/scripts-lab/main/bootstrap-cliproxyapi.sh \
  -o /root/cliproxyapi/bootstrap-cliproxyapi.sh
chmod +x /root/cliproxyapi/bootstrap-cliproxyapi.sh
/root/cliproxyapi/bootstrap-cliproxyapi.sh
```

**Run with explicit options**

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

**Use a custom config path**

```bash
/root/cliproxyapi/bootstrap-cliproxyapi.sh /path/to/config.yaml
```

**Local-only mode**

```bash
EXPOSE_PUBLIC=no /root/cliproxyapi/bootstrap-cliproxyapi.sh
```

That sets:

```yaml
host: "127.0.0.1"
remote-management:
  allow-remote: false
```

**OpenCode values**

- Base URL: `http://YOUR_VPS_IP:8317`
- API key: one generated client API key
- Management page: `http://YOUR_VPS_IP:8317/management.html`

Use the management key only for the management page.

---

### install-sub2api.sh

<p>
  <img src="https://img.shields.io/badge/Sub2API-deploy-2563EB?style=flat-square" alt="Sub2API deploy">
  <img src="https://img.shields.io/badge/Docker-compose-2496ED?style=flat-square&logo=docker&logoColor=white" alt="Docker Compose">
  <img src="https://img.shields.io/badge/port-8080-22C55E?style=flat-square" alt="Port 8080">
</p>

VPS helper for deploying Sub2API with Docker.

**What it does**

- Detects the public IP with `api.ipify.org`.
- Installs Docker from Docker's Ubuntu repository if missing.
- Allows SSH and `8080/tcp` through UFW when available.
- Downloads Sub2API's `docker-deploy.sh` into `~/sub2api`.
- Starts the Docker Compose stack.
- Prints container status, access URL, and admin credential hints.

**Use it**

```bash
curl -fsSL https://raw.githubusercontent.com/4riful/scripts-lab/main/install-sub2api.sh -o install-sub2api.sh
chmod +x install-sub2api.sh
./install-sub2api.sh
```

**After it runs**

```bash
docker ps
cd ~/sub2api
sudo docker compose logs --tail=200
```

Open:

```text
http://YOUR_VPS_IP:8080
```

---

### setup-terminal.sh

<p>
  <img src="https://img.shields.io/badge/terminal-setup-111827?style=flat-square" alt="Terminal setup">
  <img src="https://img.shields.io/badge/Zsh-Oh_My_Zsh-4EAA25?style=flat-square&logo=gnubash&logoColor=white" alt="Zsh">
  <img src="https://img.shields.io/badge/code--server-optional-007ACC?style=flat-square&logo=visualstudiocode&logoColor=white" alt="code-server">
</p>

Root terminal setup for fresh Linux machines.

**What it does**

- Installs `zsh`, `git`, `curl`, `gnupg`, and `ufw` on apt-based systems.
- Installs Oh My Zsh for root.
- Installs `zsh-autosuggestions` and `zsh-syntax-highlighting`.
- Prompts for an Oh My Zsh theme.
- Updates `/root/.zshrc` with plugins and SSH agent auto-load logic.
- Optionally installs and configures `code-server` on port `8080`.
- Creates a systemd service for code-server when selected.
- Allows SSH and `8080/tcp` through UFW.
- Sets Zsh as the default root shell.

**Use it**

```bash
curl -fsSL https://raw.githubusercontent.com/4riful/scripts-lab/main/setup-terminal.sh -o setup-terminal.sh
chmod +x setup-terminal.sh
sudo ./setup-terminal.sh
```

**Notes**

- Run it on a server you control.
- If you enable code-server, choose a strong password.
- Make sure your VPS provider firewall also allows the ports you intend to use.

---

### wsl2-clash-proxy.sh

<p>
  <img src="https://img.shields.io/badge/WSL2-proxy-0078D4?style=flat-square&logo=windows&logoColor=white" alt="WSL2 proxy">
  <img src="https://img.shields.io/badge/Clash-port_7890-7C3AED?style=flat-square" alt="Clash port 7890">
  <img src="https://img.shields.io/badge/curl-check-06B6D4?style=flat-square" alt="curl check">
</p>

WSL2 helper for managing Clash proxy environment variables.

**What it does**

- Uses PowerShell from WSL to detect the WSL2 virtual network IP.
- Supports `start`, `stop`, and `check` commands.
- Exports `http_proxy` and `https_proxy` to point at Clash port `7890`.
- Checks proxy connectivity with `curl`.

**Use it**

```bash
chmod +x wsl2-clash-proxy.sh
./wsl2-clash-proxy.sh start
./wsl2-clash-proxy.sh check
./wsl2-clash-proxy.sh stop
```

**Notes**

- This is intended for WSL2 on Windows.
- Clash should be running and listening on port `7890`.
- Environment variable exports only affect the current shell process and child processes.

---

### url-fetcher.sh

<p>
  <img src="https://img.shields.io/badge/bug_bounty-URL_collection-DC2626?style=flat-square" alt="Bug bounty URL collection">
  <img src="https://img.shields.io/badge/waybackurls-required-F97316?style=flat-square" alt="waybackurls">
  <img src="https://img.shields.io/badge/gau-required-6366F1?style=flat-square" alt="gau">
</p>

Bug bounty URL collection helper.

**What it does**

- Takes a domain list as the first argument.
- Runs `waybackurls` against the list.
- Runs `gau` against the list.
- Deduplicates results into `fetchedurls.txt`.
- Sends completion notifications through `notify` when available.

**Requirements**

- `waybackurls`
- `gau`
- `pv`
- `notify` optional, for notifications

**Use it**

```bash
chmod +x url-fetcher.sh
./url-fetcher.sh domains.txt
```

Input example:

```text
example.com
sub.example.com
```

Output:

```text
fetchedurls.txt
```

---

### send-to-chat.sh

<p>
  <img src="https://img.shields.io/badge/Telegram-send_file-26A5E4?style=flat-square&logo=telegram&logoColor=white" alt="Telegram">
  <img src="https://img.shields.io/badge/Discord-webhook-5865F2?style=flat-square&logo=discord&logoColor=white" alt="Discord">
  <img src="https://img.shields.io/badge/notify-config-111827?style=flat-square" alt="notify config">
</p>

Send a file to Telegram or Discord using a ProjectDiscovery `notify`-style provider config.

**What it does**

- Reads `~/.config/notify/provider-config.yaml`.
- Detects Telegram config and sends the file as a Telegram document.
- Detects Discord config and uploads the file to a Discord webhook.
- Adds the hostname in the message so you know which machine sent it.

**Use it**

```bash
chmod +x send-to-chat.sh
./send-to-chat.sh fetchedurls.txt
```

**Expected config path**

```text
~/.config/notify/provider-config.yaml
```

The config should contain Telegram or Discord provider credentials compatible with `notify`.

---

### wsl2-storage-maintenance.md

<p>
  <img src="https://img.shields.io/badge/WSL2-storage-0078D4?style=flat-square&logo=windows&logoColor=white" alt="WSL2 storage">
  <img src="https://img.shields.io/badge/VHDX-compact-14B8A6?style=flat-square" alt="VHDX compact">
  <img src="https://img.shields.io/badge/Windows_11_Home-guide-2563EB?style=flat-square" alt="Windows 11 Home guide">
</p>

Checklist for reducing WSL2 disk bloat on Windows 11 Home.

**What it covers**

- Checking real Linux disk usage with `df` and `du`.
- Cleaning apt cache, journal logs, root cache, and Docker junk.
- Shutting down WSL safely.
- Finding the distro `ext4.vhdx` path through the Windows registry.
- Compacting the VHDX with `diskpart`.
- Rebuilding a bloated distro through `wsl --export`, `wsl --unregister`, and `wsl --import`.

**Read it**

```text
wsl2-storage-maintenance.md
```

---

## Suggested Workflow

```text
scripts-lab/
+-- pick the script that matches the task
+-- read the script and safety notes
+-- run it on a controlled machine
+-- save generated credentials somewhere private
+-- keep the useful output, delete temporary junk
```

## License

Use these scripts at your own risk. Review before running, especially on production servers.

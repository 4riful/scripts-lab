# scripts-lab

Practical shell scripts and notes for VPS setup, WSL maintenance, proxy workflows, bug bounty URL collection, and chat notifications.

This repo is not a framework. It is a small lab of scripts I keep around because they solve real operational problems quickly.

## What is inside

- `bootstrap-cliproxyapi.sh` - one-shot CLIProxyAPI installer and VPS bootstrap for OpenCode/OpenAI-compatible clients.
- `install-sub2api.sh` - VPS helper for deploying Sub2API with Docker.
- `setup-terminal.sh` - root terminal setup with Zsh, Oh My Zsh, plugins, optional code-server, and UFW rules.
- `wsl2-clash-proxy.sh` - WSL2 helper for starting, stopping, and checking Clash proxy environment variables.
- `url-fetcher.sh` - bug bounty URL collector using `waybackurls` and `gau`.
- `send-to-chat.sh` - send files to Telegram or Discord through a `notify` provider config.
- `wsl2-storage-maintenance.md` - Windows 11 Home checklist for cleaning and compacting WSL2 disks.

## Safety notes

- Read a script before running it on a server.
- Several scripts are meant to run as `root` and can change firewall, Docker, systemd, or shell settings.
- Do not paste secret keys into issues, commits, terminals you share, or screenshots.
- `bootstrap-cliproxyapi.sh` generates fresh client API keys and a fresh management key every run. Save the printed values.

---

## bootstrap-cliproxyapi.sh

One-shot CLIProxyAPI bootstrap for a clean VPS.

It downloads CLIProxyAPI config/compose files if missing, generates fresh API keys, enables remote access when requested, opens the API port, starts the container, and prints the connection details for OpenCode or another OpenAI-compatible client.

### What it does

- Downloads official CLIProxyAPI `config.example.yaml` and `docker-compose.yml` into `/root/cliproxyapi` if no config exists.
- Creates `/root/cliproxyapi/auths` and `/root/cliproxyapi/logs`.
- Replaces the active top-level `api-keys` block with fresh `sk-...` client keys.
- Sets `remote-management.secret-key` to a fresh management key.
- Sets `host: ""` and `remote-management.allow-remote: true` by default.
- Opens `8317/tcp` in UFW when public exposure is enabled.
- Installs Docker/Compose on apt-based systems if missing.
- Starts CLIProxyAPI through Docker Compose.

### Use it

```bash
mkdir -p /root/cliproxyapi
curl -fsSL https://raw.githubusercontent.com/4riful/scripts-lab/main/bootstrap-cliproxyapi.sh \
  -o /root/cliproxyapi/bootstrap-cliproxyapi.sh
chmod +x /root/cliproxyapi/bootstrap-cliproxyapi.sh
/root/cliproxyapi/bootstrap-cliproxyapi.sh
```

### Use with explicit options

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

### Use with a custom config path

```bash
/root/cliproxyapi/bootstrap-cliproxyapi.sh /path/to/config.yaml
```

### Local-only mode

```bash
EXPOSE_PUBLIC=no /root/cliproxyapi/bootstrap-cliproxyapi.sh
```

That sets:

```yaml
host: "127.0.0.1"
remote-management:
  allow-remote: false
```

### OpenCode values

After the script finishes, use:

- Base URL: `http://YOUR_VPS_IP:8317`
- API key: one generated client API key

Use the management key only for:

```text
http://YOUR_VPS_IP:8317/management.html
```

---

## install-sub2api.sh

VPS helper for deploying Sub2API with Docker.

### What it does

- Detects the public IP with `api.ipify.org`.
- Installs Docker from Docker's Ubuntu repository if missing.
- Allows SSH and `8080/tcp` through UFW when UFW is available.
- Downloads Sub2API's `docker-deploy.sh` into `~/sub2api`.
- Starts the Docker Compose stack.
- Prints container status, access URL, and admin credential hints.

### Use it

```bash
curl -fsSL https://raw.githubusercontent.com/4riful/scripts-lab/main/install-sub2api.sh -o install-sub2api.sh
chmod +x install-sub2api.sh
./install-sub2api.sh
```

### After it runs

Check the service:

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

## setup-terminal.sh

Root terminal setup for fresh Linux machines.

### What it does

- Installs `zsh`, `git`, `curl`, `gnupg`, and `ufw` on apt-based systems.
- Installs Oh My Zsh for root.
- Installs `zsh-autosuggestions` and `zsh-syntax-highlighting`.
- Prompts for an Oh My Zsh theme.
- Updates `/root/.zshrc` with plugins and SSH agent auto-load logic.
- Optionally installs and configures `code-server` on port `8080`.
- Creates a systemd service for code-server when selected.
- Allows SSH and `8080/tcp` through UFW.
- Sets Zsh as the default root shell.

### Use it

```bash
curl -fsSL https://raw.githubusercontent.com/4riful/scripts-lab/main/setup-terminal.sh -o setup-terminal.sh
chmod +x setup-terminal.sh
sudo ./setup-terminal.sh
```

### Notes

- Run it on a server you control.
- If you enable code-server, choose a strong password.
- Make sure your VPS provider firewall also allows the ports you intend to use.

---

## wsl2-clash-proxy.sh

WSL2 helper for managing Clash proxy environment variables.

### What it does

- Uses PowerShell from WSL to detect the WSL2 virtual network IP.
- Supports `start`, `stop`, and `check` commands.
- Exports `http_proxy` and `https_proxy` to point at Clash port `7890`.
- Checks proxy connectivity with `curl`.

### Use it

```bash
chmod +x wsl2-clash-proxy.sh
./wsl2-clash-proxy.sh start
./wsl2-clash-proxy.sh check
./wsl2-clash-proxy.sh stop
```

### Notes

- This is intended for WSL2 on Windows.
- Clash should be running and listening on port `7890`.
- Environment variable exports only affect the current shell process and children.

---

## url-fetcher.sh

Bug bounty URL collection helper.

### What it does

- Takes a domain list as the first argument.
- Runs `waybackurls` against the list.
- Runs `gau` against the list.
- Deduplicates results into `fetchedurls.txt`.
- Sends completion notifications through `notify` when available.

### Requirements

- `waybackurls`
- `gau`
- `pv`
- `notify` optional, for notifications

### Use it

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

## send-to-chat.sh

Send a file to Telegram or Discord using ProjectDiscovery `notify`-style provider config.

### What it does

- Reads `~/.config/notify/provider-config.yaml`.
- Detects Telegram config and sends the file as a Telegram document.
- Detects Discord config and uploads the file to a Discord webhook.
- Adds the hostname in the message so you know which machine sent it.

### Use it

```bash
chmod +x send-to-chat.sh
./send-to-chat.sh fetchedurls.txt
```

### Expected config path

```text
~/.config/notify/provider-config.yaml
```

The config should contain Telegram or Discord provider credentials compatible with `notify`.

---

## wsl2-storage-maintenance.md

Checklist for reducing WSL2 disk bloat on Windows 11 Home.

### What it covers

- Checking real Linux disk usage with `df` and `du`.
- Cleaning apt cache, journal logs, root cache, and Docker junk.
- Shutting down WSL safely.
- Finding the distro `ext4.vhdx` path through the Windows registry.
- Compacting the VHDX with `diskpart`.
- Rebuilding a bloated distro through `wsl --export`, `wsl --unregister`, and `wsl --import`.

### Read it

Open the checklist:

```text
wsl2-storage-maintenance.md
```

---

## Clone

```bash
git clone https://github.com/4riful/scripts-lab.git
cd scripts-lab
```

## License

Use these scripts at your own risk. Review before running, especially on production servers.

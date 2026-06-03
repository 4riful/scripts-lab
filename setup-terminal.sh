#!/usr/bin/env bash
# Automated Terminal Setup Script
# -------------------------------
# - Installs Zsh + Oh My Zsh + plugins (autosuggestions, syntax-highlighting)
# - Prompts for a minimal-theme choice
# - Optionally installs VS Code Server (code-server) with password authentication
#   and sets up a systemd service to keep it running
# - Sets up UFW to allow SSH and code-server ports
# - Switches the default shell to Zsh

set -eo pipefail

# Ensure script is run with superuser privileges
if [[ $EUID -ne 0 ]]; then
  echo "Error: This script must be run as root or with sudo."
  exit 1
fi

# Prompt with default
default_prompt() {
  local prompt_msg="$1"
  local default_val="$2"
  read -p "$prompt_msg [$default_val]: " input
  echo "${input:-$default_val}"
}

yes_no_prompt() {
  local prompt_msg="$1"
  local default_val="$2"
  while true; do
    read -p "$prompt_msg (y/n) [$default_val]: " yn
    yn="${yn:-$default_val}"
    case "$yn" in
      [Yy]*) echo "yes"; return;;
      [Nn]*) echo "no"; return;;
      *) echo "Please answer y or n.";;
    esac
  done
}

# 1) Install prerequisites
echo "==> Installing prerequisites (zsh, git, curl, gnupg, ufw)..."
if command -v apt-get >/dev/null; then
  apt-get update -y
  apt-get install -y zsh git curl gnupg ufw
elif command -v yum >/dev/null; then
  yum install -y zsh git curl gnupg
  echo "Warning: UFW not available on this distro. Please configure your firewall manually."
else
  echo "Unsupported package manager. Please install prerequisites manually."
  exit 1
fi

# 2) Install Oh My Zsh
echo "==> Installing Oh My Zsh..."
OH_MY_ZSH_DIR="/root/.oh-my-zsh"
if [[ ! -d "$OH_MY_ZSH_DIR" ]]; then
  export RUNZSH=no CHSH=no
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "Oh My Zsh already installed. Skipping."
fi

# 3) Install Zsh plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-/root/.oh-my-zsh/custom}"
install_plugin() {
  local plugin_name="$1"
  local repo_url="$2"
  local dest="$ZSH_CUSTOM/plugins/$plugin_name"
  if [[ -d "$dest" ]]; then
    echo "Plugin '$plugin_name' already installed."
  else
    echo "==> Installing plugin: $plugin_name"
    git clone "$repo_url" "$dest"
  fi
}
install_plugin zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions.git
install_plugin zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting.git

# 4) Configure ~/.zshrc
ZSHRC="/root/.zshrc"
if [[ ! -f "$ZSHRC" ]]; then
  cp "$OH_MY_ZSH_DIR/templates/zshrc.zsh-template" "$ZSHRC"
fi

echo "==> Customizing .zshrc with minimal theme and plugins"
theme=$(default_prompt "Choose a minimal Oh My Zsh theme" "minimal")
if grep -q '^ZSH_THEME=' "$ZSHRC"; then
  sed -i "s/^ZSH_THEME=.*/ZSH_THEME=\"$theme\"/" "$ZSHRC"
else
  echo "ZSH_THEME=\"$theme\"" >> "$ZSHRC"
fi
if grep -q '^plugins=' "$ZSHRC"; then
  sed -i "s/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/" "$ZSHRC"
else
  echo "plugins=(git zsh-autosuggestions zsh-syntax-highlighting)" >> "$ZSHRC"
fi
if ! grep -q 'ssh-agent auto-load' "$ZSHRC"; then
  cat << 'EOF' >> "$ZSHRC"

# SSH agent auto-load
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
  eval "$(ssh-agent -s)"
fi
ssh-add -l &>/dev/null || ssh-add ~/.ssh/id_ed25519
EOF
fi

# 5) Optionally install code-server and systemd service
if [[ "$(yes_no_prompt 'Install and configure VS Code Server (code-server)?' 'y')" == "yes" ]]; then
  echo "==> Installing VS Code Server..."
  if ! command -v code-server >/dev/null; then
    curl -fsSL https://code-server.dev/install.sh | sh
  else
    echo "code-server already installed. Skipping."
  fi
  # Prompt for code-server password
  echo "Set up code-server authentication"
  read -rsp "Enter a password for code-server: " cs_password
echo
  mkdir -p /root/.config/code-server
  cat > /root/.config/code-server/config.yaml <<EOF
bind-addr: 0.0.0.0:8080
auth: password
password: $cs_password
cert: false
EOF
  # Create systemd service
  echo "==> Creating systemd service for code-server..."
  cat > /etc/systemd/system/code-server.service <<EOF
[Unit]
Description=VS Code Server
After=network.target

[Service]
Type=simple
User=root
Environment=PASSWORD=$cs_password
ExecStart=/usr/bin/code-server --bind-addr 0.0.0.0:8080 --auth password
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable --now code-server.service
  echo "code-server service started and enabled."
fi

# 6) Configure UFW
echo "==> Configuring UFW firewall..."
if command -v ufw >/dev/null; then
  ufw allow OpenSSH
  ufw allow 8080/tcp
  ufw --force enable
  echo "UFW enabled: SSH and port 8080 allowed."
else
  echo "UFW not available; ensure ports 22 and 8080 are open."
fi

# 7) Change default shell to Zsh
echo "==> Setting Zsh as default shell..."
chsh -s "$(which zsh)" root || true

cat << 'EOF'

Setup complete!
- Re-open or log in to start using Zsh with your chosen theme/plugins.
- If installed, code-server is running as a systemd service on port 8080.
EOF

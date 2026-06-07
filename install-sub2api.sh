bash <(cat <<'EOF'
set -euo pipefail

echo "========================================="
echo " Sub2API VPS Auto Installer"
echo "========================================="

# Detect public IP
PUBLIC_IP=$(curl -4 -s https://api.ipify.org || true)

echo
echo "[INFO] Public IP: ${PUBLIC_IP:-Unknown}"
echo

# Install Docker if needed
if ! command -v docker >/dev/null 2>&1; then
    echo "[STEP] Installing Docker..."

    sudo apt update
    sudo apt install -y ca-certificates curl

    sudo install -m 0755 -d /etc/apt/keyrings

    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        -o /etc/apt/keyrings/docker.asc

    sudo chmod a+r /etc/apt/keyrings/docker.asc

    . /etc/os-release

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${UBUNTU_CODENAME:-$VERSION_CODENAME} stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

    sudo apt update

    sudo apt install -y \
      docker-ce \
      docker-ce-cli \
      containerd.io \
      docker-buildx-plugin \
      docker-compose-plugin

    sudo systemctl enable docker
    sudo systemctl start docker
fi

echo "[OK] Docker installed"

# Configure UFW if present
if command -v ufw >/dev/null 2>&1; then
    echo "[STEP] Configuring firewall..."

    sudo ufw allow 22/tcp >/dev/null 2>&1 || true
    sudo ufw allow 8080/tcp >/dev/null 2>&1 || true

    if sudo ufw status | grep -q inactive; then
        echo "y" | sudo ufw enable >/dev/null 2>&1 || true
    fi

    echo "[OK] UFW configured"
fi

# Deploy Sub2API
mkdir -p ~/sub2api
cd ~/sub2api

echo "[STEP] Downloading deployment..."

curl -fsSL \
https://raw.githubusercontent.com/Wei-Shaw/sub2api/main/deploy/docker-deploy.sh \
-o docker-deploy.sh

chmod +x docker-deploy.sh

echo "[STEP] Running deployment..."
bash docker-deploy.sh

echo "[STEP] Starting containers..."

if [ -f docker-compose.yml ]; then
    sudo docker compose up -d
elif [ -f docker-compose.local.yml ]; then
    sudo docker compose -f docker-compose.local.yml up -d
fi

echo "[STEP] Waiting for startup..."
sleep 30

echo
echo "========================================="
echo " Container Status"
echo "========================================="
sudo docker ps || true

echo
echo "========================================="
echo " Admin Credentials"
echo "========================================="

PASSWORD=$(
(
sudo docker compose logs 2>/dev/null || true
sudo docker compose -f docker-compose.local.yml logs 2>/dev/null || true
) | grep -i "admin password" | tail -1 | sed 's/.*: //'
)

echo "Email: admin@sub2api.local"

if [ -n "$PASSWORD" ]; then
    echo "Password: $PASSWORD"
else
    echo "Password not found in logs."
    echo
    echo "Run:"
    echo "cd ~/sub2api"
    echo "sudo docker compose logs --tail=200"
fi

echo
echo "========================================="
echo " Access URL"
echo "========================================="

if [ -n "${PUBLIC_IP:-}" ]; then
    echo "http://$PUBLIC_IP:8080"
else
    echo "http://<YOUR_VPS_IP>:8080"
fi

echo
echo "========================================="
echo " Quick Health Checks"
echo "========================================="
echo "docker ps"
echo "cd ~/sub2api && sudo docker compose logs -f"
echo "ss -tulpn | grep 8080"
echo "========================================="
EOF
)

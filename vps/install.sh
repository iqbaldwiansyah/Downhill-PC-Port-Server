#!/usr/bin/env bash
# Automated setup script for Downhill Revived Online Server on Ubuntu/Debian Linux VPS.
set -euo pipefail

echo "=== Downhill Revived Online Server: VPS Setup ==="

# 1. Swap creation if less than 1GB swap
SWAP_TOTAL=$(free -m | awk '/^Swap:/ {print $2}')
if [ "$SWAP_TOTAL" -lt 1024 ] && [ ! -f /swapfile ]; then
    echo "[+] Creating 2GB swap file for build and memory stability..."
    fallocate -l 2G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=2048
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

# 2. Node.js 22 LTS installation
if ! command -v node >/dev/null 2>&1 || [ "$(node -v | cut -d'.' -f1 | tr -d 'v')" -lt 22 ]; then
    echo "[+] Installing Node.js 22 LTS..."
    apt-get update
    apt-get install -y ca-certificates curl gnupg build-essential nginx
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg --yes
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
    apt-get update
    apt-get install -y nodejs
else
    apt-get update && apt-get install -y nginx
fi

echo "[+] Node version: $(node -v), npm version: $(npm -v)"

# 3. Setup application directory
INSTALL_DIR="/opt/downhill-server"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_SRC="$(cd "$SCRIPT_DIR/.." && pwd)"

mkdir -p "$INSTALL_DIR"
echo "[+] Copying server files to $INSTALL_DIR..."
rm -rf "$INSTALL_DIR/src" "$INSTALL_DIR/test" "$INSTALL_DIR/tools"
cp -r "$SERVER_SRC/src" "$INSTALL_DIR/"
cp -r "$SERVER_SRC/test" "$INSTALL_DIR/"
cp -r "$SERVER_SRC/tools" "$INSTALL_DIR/"
cp "$SERVER_SRC/package.json" "$INSTALL_DIR/"
cp "$SERVER_SRC/package-lock.json" "$INSTALL_DIR/"
cp "$SERVER_SRC/tsconfig.json" "$INSTALL_DIR/"
cp "$SERVER_SRC/vitest.config.ts" "$INSTALL_DIR/"
cp "$SERVER_SRC/wrangler.jsonc" "$INSTALL_DIR/"

# 4. Install dependencies and run tests
echo "[+] Installing npm dependencies..."
cd "$INSTALL_DIR"
npm install
echo "[+] Running test suite..."
npm test

# 5. Setup systemd service
echo "[+] Setting up systemd service..."
cp "$SCRIPT_DIR/downhill-server.service" /etc/systemd/system/downhill-server.service
systemctl daemon-reload
systemctl enable downhill-server
systemctl restart downhill-server

# 6. Setup Nginx reverse proxy
echo "[+] Configuring Nginx..."
cp "$SCRIPT_DIR/nginx-downhill.conf" /etc/nginx/sites-available/default
nginx -t
systemctl enable nginx
systemctl restart nginx

# 7. Configure firewall if ufw is active
if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
    echo "[+] Opening ports 80, 443, 8787 in UFW..."
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw allow 8787/tcp
    ufw reload
fi

echo "=== Deployment Complete ==="
echo "Health check: curl http://127.0.0.1/v1/health"

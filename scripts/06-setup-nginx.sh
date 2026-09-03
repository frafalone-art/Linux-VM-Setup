#!/usr/bin/env bash
#
# 06-setup-nginx.sh
# Installs nginx and configures it as a reverse proxy in front of the
# FastAPI/uvicorn service (which listens on an internal port, e.g. 8000).
# No domain or SSL required — this serves plain HTTP on port 80.
# Run 07-setup-ssl.sh separately once you have a domain pointed at the VM.
#
# Usage: ./06-setup-nginx.sh <app_name> <upstream_port> [server_name]
# Example: ./06-setup-nginx.sh myapp 8000 myapp.example.com
# Example (no domain yet): ./06-setup-nginx.sh myapp 8000

set -euo pipefail

echo "=== [1/1] Setup Nginx Reverse Proxy ==="
echo "This script will:"
echo "  1. Install nginx (if not already installed)"
echo "  2. Create a reverse-proxy config pointing to the local uvicorn port"
echo "  3. Enable the site and reload nginx"
echo ""

if [ $# -lt 2 ]; then
    echo "Usage: $0 <app_name> <upstream_port> [server_name]" >&2
    echo "Example: $0 myapp 8000 myapp.example.com" >&2
    exit 1
fi

APP_NAME="$1"
UPSTREAM_PORT="$2"
SERVER_NAME="${3:-_}"   # "_" = catch-all, use when there's no domain yet

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root (use sudo)." >&2
    exit 1
fi

echo "--> Installing nginx..."
apt-get update -y
apt-get install -y nginx

CONFIG_PATH="/etc/nginx/sites-available/${APP_NAME}"

echo "--> Writing nginx config to $CONFIG_PATH..."
cat > "$CONFIG_PATH" <<EOF
server {
    listen 80;
    server_name ${SERVER_NAME};

    location / {
        proxy_pass http://127.0.0.1:${UPSTREAM_PORT};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

echo "--> Enabling site..."
ln -sf "$CONFIG_PATH" "/etc/nginx/sites-enabled/${APP_NAME}"

if [ -f /etc/nginx/sites-enabled/default ]; then
    echo "--> Removing default nginx site..."
    rm -f /etc/nginx/sites-enabled/default
fi

echo "--> Testing nginx configuration..."
nginx -t

echo "--> Reloading nginx..."
systemctl reload nginx
systemctl enable nginx

echo ""
echo "=== DONE: Nginx is proxying to 127.0.0.1:${UPSTREAM_PORT}. ==="
echo "Confirmation:"
systemctl status nginx --no-pager -l | head -5
echo ""
if [ "$SERVER_NAME" = "_" ]; then
    echo "NOTE: no domain set — nginx will answer any Host header on port 80."
    echo "      Once you have a domain pointed at this server's IP, re-run with:"
    echo "        $0 ${APP_NAME} ${UPSTREAM_PORT} yourdomain.com"
    echo "      then run 07-setup-ssl.sh to add HTTPS."
fi

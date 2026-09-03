#!/usr/bin/env bash
#
# 06-setup-nginx.sh
# Installs nginx and configures it as a reverse proxy in front of the
# FastAPI/uvicorn service (which listens on an internal port, e.g. 8000).
# No domain or SSL required — this serves plain HTTP on port 80.
# Run 07-setup-ssl.sh separately once you have a domain pointed at the VM.
#
# Usage: ./06-setup-nginx.sh [app_name] [upstream_port] [server_name]
# If arguments are omitted, you'll be prompted for them.
# Example: ./06-setup-nginx.sh myapp 8000 myapp.example.com
# Example (no domain yet): ./06-setup-nginx.sh myapp 8000

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="$SCRIPT_DIR/../templates/nginx.conf.template"

echo "=== [1/1] Setup Nginx Reverse Proxy ==="
echo "This script will:"
echo "  1. Install nginx (if not already installed)"
echo "  2. Render the nginx config from templates/nginx.conf.template"
echo "  3. Enable the site and reload nginx"
echo ""

if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "ERROR: template not found at $TEMPLATE_FILE" >&2
    exit 1
fi

if [ $# -ge 1 ]; then APP_NAME="$1"; else read -rp "Service/app name (e.g. myapp): " APP_NAME; fi
if [ $# -ge 2 ]; then UPSTREAM_PORT="$2"; else read -rp "Internal uvicorn port [8000]: " UPSTREAM_PORT; UPSTREAM_PORT="${UPSTREAM_PORT:-8000}"; fi
if [ $# -ge 3 ]; then
    SERVER_NAME="$3"
else
    read -rp "Domain name (leave empty if you don't have one yet): " SERVER_NAME
    SERVER_NAME="${SERVER_NAME:-_}"   # "_" = catch-all, use when there's no domain yet
fi

if [ -z "$APP_NAME" ]; then
    echo "ERROR: app name is required." >&2
    exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root (use sudo)." >&2
    exit 1
fi

echo "--> Installing nginx and gettext-base (for envsubst)..."
apt-get update -y
apt-get install -y nginx gettext-base

CONFIG_PATH="/etc/nginx/sites-available/${APP_NAME}"

echo "--> Rendering nginx config to $CONFIG_PATH..."
export SERVER_NAME UPSTREAM_PORT
# shellcheck disable=SC2016  # single quotes are intentional: envsubst needs the literal var list
envsubst '${SERVER_NAME} ${UPSTREAM_PORT}' < "$TEMPLATE_FILE" > "$CONFIG_PATH"

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

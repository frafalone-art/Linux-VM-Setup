#!/usr/bin/env bash
#
# 07-setup-firewall.sh
# Installs UFW (Uncomplicated Firewall), sets a default deny-incoming
# policy, and opens only the ports needed for a web server: 22 (SSH),
# 80 (HTTP), 443 (HTTPS). Everything else is blocked.

set -euo pipefail

echo "=== [1/1] Setup Firewall (UFW) ==="
echo "This script will:"
echo "  1. Install UFW (if not already installed)"
echo "  2. Set default policy: deny all incoming, allow all outgoing"
echo "  3. Allow ports: 22 (SSH), 80 (HTTP), 443 (HTTPS)"
echo "  4. Enable the firewall"
echo ""

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root (use sudo)." >&2
    exit 1
fi

echo "--> Installing UFW..."
apt-get update -y
apt-get install -y ufw

echo "--> Setting default policies (deny incoming, allow outgoing)..."
ufw default deny incoming
ufw default allow outgoing

echo "--> Allowing port 22 (SSH)..."
ufw allow 22/tcp comment 'SSH'

echo "--> Allowing port 80 (HTTP)..."
ufw allow 80/tcp comment 'HTTP'

echo "--> Allowing port 443 (HTTPS)..."
ufw allow 443/tcp comment 'HTTPS'

echo "--> Enabling UFW..."
ufw --force enable

echo ""
echo "=== DONE: Firewall is active. Only 22, 80, 443 are open. ==="
echo "Confirmation:"
ufw status verbose

echo ""
echo "IMPORTANT: before disconnecting, confirm port 22 works by opening a"
echo "NEW terminal and testing SSH login. If you get locked out, most cloud"
echo "providers offer a serial/web console to run 'ufw disable' as recovery."

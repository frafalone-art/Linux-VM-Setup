#!/usr/bin/env bash
#
# 08-setup-fail2ban.sh
# Installs fail2ban and enables the SSH jail: after repeated failed login
# attempts from the same IP, that IP is temporarily banned. This is an
# extra layer on top of the firewall, not a replacement for it.

set -euo pipefail

echo "=== [1/1] Setup Fail2Ban ==="
echo "This script will:"
echo "  1. Install fail2ban (if not already installed)"
echo "  2. Create a local jail config enabling SSH protection"
echo "  3. Set ban time, find time and retry limits"
echo "  4. Enable and start the fail2ban service"
echo ""

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root (use sudo)." >&2
    exit 1
fi

echo "--> Installing fail2ban..."
apt-get update -y
apt-get install -y fail2ban

CONFIG_PATH="/etc/fail2ban/jail.local"

echo "--> Writing jail config to $CONFIG_PATH..."
cat > "$CONFIG_PATH" <<'EOF'
[DEFAULT]
# Ban an IP for 1 hour after it exceeds maxretry
bantime = 1h
# Window of time in which failed attempts are counted
findtime = 10m
# Number of failed attempts before a ban
maxretry = 5

[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
EOF

echo "--> Enabling and restarting fail2ban..."
systemctl enable fail2ban
systemctl restart fail2ban

echo ""
echo "=== DONE: fail2ban is protecting SSH. ==="
echo "Confirmation:"
fail2ban-client status
fail2ban-client status sshd

echo ""
echo "Useful commands:"
echo "  sudo fail2ban-client status sshd     # see banned IPs"
echo "  sudo fail2ban-client unban <IP>      # manually unban an IP"

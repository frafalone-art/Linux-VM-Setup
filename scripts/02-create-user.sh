#!/usr/bin/env bash
#
# 02-create-user.sh
# Creates a non-root user with sudo privileges and copies the root user's
# authorized SSH keys to it. Does NOT disable root/password SSH login by
# itself — that is a separate, deliberate step you run manually once you've
# confirmed the new user can log in (see the printed instructions at the end).

set -euo pipefail

echo "=== [1/3] Create Non-Root User ==="
echo "This script will:"
echo "  1. Create a new user with sudo privileges"
echo "  2. Set up its home directory and .ssh folder"
echo "  3. Copy root's authorized_keys to the new user (if present)"
echo ""

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root (use sudo)." >&2
    exit 1
fi

read -rp "Enter the username to create: " NEW_USER

if id "$NEW_USER" &>/dev/null; then
    echo "NOTE: User '$NEW_USER' already exists, skipping creation."
else
    echo "--> Creating user '$NEW_USER' (SSH-key login only, no password set)..."
    adduser --disabled-password --gecos "" "$NEW_USER"
fi

echo "--> Adding '$NEW_USER' to the sudo group..."
usermod -aG sudo "$NEW_USER"

echo "--> Setting up SSH directory for '$NEW_USER'..."
USER_HOME=$(eval echo "~$NEW_USER")
mkdir -p "$USER_HOME/.ssh"
chmod 700 "$USER_HOME/.ssh"

if [ -f /root/.ssh/authorized_keys ]; then
    echo "--> Copying root's authorized_keys to '$NEW_USER'..."
    cp /root/.ssh/authorized_keys "$USER_HOME/.ssh/authorized_keys"
    chmod 600 "$USER_HOME/.ssh/authorized_keys"
else
    echo "NOTE: /root/.ssh/authorized_keys not found — no keys copied."
    echo "      Add your public key manually to $USER_HOME/.ssh/authorized_keys"
fi

chown -R "$NEW_USER":"$NEW_USER" "$USER_HOME/.ssh"

echo ""
echo "=== DONE: Non-root user created. ==="
echo "Confirmation:"
echo "  - User: $NEW_USER"
echo "  - Sudo group: yes"
echo "  - SSH key copied: $([ -f "$USER_HOME/.ssh/authorized_keys" ] && echo yes || echo no)"
echo ""
echo "IMPORTANT — do this before closing your current session:"
echo "  1. Open a NEW terminal and test: ssh $NEW_USER@<your-server-ip>"
echo "  2. Confirm you can log in AND run 'sudo whoami' successfully."
echo "  3. Only after that works, disable root SSH login by editing"
echo "     /etc/ssh/sshd_config:"
echo "       PermitRootLogin no"
echo "       PasswordAuthentication no"
echo "     then: sudo systemctl restart sshd"

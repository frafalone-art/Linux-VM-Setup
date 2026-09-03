#!/usr/bin/env bash
#
# 03-setup-swap.sh
# Creates and enables a swap file. Useful on small VMs (e.g. free-tier
# Oracle Cloud instances with 1GB RAM) where pip installs or builds can
# otherwise trigger an out-of-memory kill.

set -euo pipefail

SWAP_SIZE_GB="${1:-2}"
SWAP_FILE="/swapfile"

echo "=== [1/1] Setup Swap File ==="
echo "This script will:"
echo "  1. Create a ${SWAP_SIZE_GB}GB swap file at $SWAP_FILE"
echo "  2. Enable it and set correct permissions"
echo "  3. Make it persistent across reboots (via /etc/fstab)"
echo "  4. Set swappiness to a conservative value (10)"
echo ""

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root (use sudo)." >&2
    exit 1
fi

if [ -f "$SWAP_FILE" ]; then
    echo "NOTE: $SWAP_FILE already exists."
    if swapon --show | grep -q "$SWAP_FILE"; then
        echo "      It is already active. Nothing to do."
        swapon --show
        exit 0
    fi
else
    echo "--> Allocating ${SWAP_SIZE_GB}GB swap file..."
    fallocate -l "${SWAP_SIZE_GB}G" "$SWAP_FILE" || dd if=/dev/zero of="$SWAP_FILE" bs=1M count=$((SWAP_SIZE_GB * 1024))
    chmod 600 "$SWAP_FILE"
fi

echo "--> Formatting swap file..."
mkswap "$SWAP_FILE"

echo "--> Enabling swap..."
swapon "$SWAP_FILE"

if ! grep -q "$SWAP_FILE" /etc/fstab; then
    echo "--> Making swap persistent across reboots..."
    echo "$SWAP_FILE none swap sw 0 0" >> /etc/fstab
else
    echo "NOTE: /etc/fstab entry already present."
fi

echo "--> Setting swappiness to 10 (use swap conservatively)..."
sysctl vm.swappiness=10
if ! grep -q "vm.swappiness" /etc/sysctl.conf; then
    echo "vm.swappiness=10" >> /etc/sysctl.conf
fi

echo ""
echo "=== DONE: Swap file is active. ==="
echo "Confirmation:"
swapon --show
free -h

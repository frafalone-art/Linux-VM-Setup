#!/usr/bin/env bash
#
# 01-system-update.sh
# Updates the package index and upgrades all installed packages.
# Safe to re-run at any time (idempotent).

set -euo pipefail

echo "=== [1/1] System Update ==="
echo "This script will:"
echo "  1. Refresh the package index (apt update)"
echo "  2. Upgrade all installed packages (apt full-upgrade)"
echo "  3. Remove packages that are no longer needed (apt autoremove)"
echo "  4. Clean up downloaded package files (apt clean)"
echo ""

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root (use sudo)." >&2
    exit 1
fi

echo "--> Refreshing package index..."
apt-get update -y

echo "--> Upgrading installed packages..."
DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y

echo "--> Removing unused packages..."
apt-get autoremove -y

echo "--> Cleaning package cache..."
apt-get clean

echo ""
echo "=== DONE: System is up to date. ==="
echo "Confirmation:"
echo "  - Package index: refreshed"
echo "  - Installed packages: upgraded to latest available versions"
echo "  - Unused packages: removed"
echo "  - Package cache: cleaned"

if [ -f /var/run/reboot-required ]; then
    echo ""
    echo "NOTE: A reboot is required to apply some updates (e.g. kernel)."
    echo "      Run: sudo reboot"
fi

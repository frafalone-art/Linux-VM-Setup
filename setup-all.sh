#!/usr/bin/env bash
#
# setup-all.sh
# Runs all provisioning scripts in order to prepare a fresh Linux VM to
# host a FastAPI service behind nginx, managed by Supervisor, with a
# firewall and fail2ban enabled.
#
# Usage:
#   sudo ./setup-all.sh <new_username> <app_name> <app_dir> \
#        <requirements.txt> <module:app> [port] [server_name]
#
# Example:
#   sudo ./setup-all.sh deploy myapp /opt/myapp ./requirements.txt main:app 8000
#
# Steps can also be run individually from scripts/ — see the README.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "================================================"
echo " Linux VM Setup — Full Provisioning"
echo "================================================"
echo "This will run, in order:"
echo "  1. System update"
echo "  2. Create non-root user"
echo "  3. Setup swap file"
echo "  4. Setup Python venv + install dependencies"
echo "  5. Setup Supervisor (run the app in background)"
echo "  6. Setup nginx (reverse proxy)"
echo "  7. Setup firewall (allow only 22, 80, 443)"
echo "  8. Setup fail2ban (SSH brute-force protection)"
echo ""
echo "SSL/HTTPS is NOT included — it requires a domain pointed at this"
echo "server. Run scripts/06-setup-nginx.sh again with your domain, then"
echo "set up certbot separately once DNS is ready."
echo ""

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root (use sudo)." >&2
    exit 1
fi

if [ $# -lt 5 ]; then
    echo "Usage: $0 <new_username> <app_name> <app_dir> <requirements.txt> <module:app> [port] [server_name]" >&2
    echo "Example: $0 deploy myapp /opt/myapp ./requirements.txt main:app 8000" >&2
    exit 1
fi

NEW_USER="$1"
APP_NAME="$2"
APP_DIR="$3"
REQUIREMENTS_FILE="$4"
APP_MODULE="$5"
PORT="${6:-8000}"
SERVER_NAME="${7:-_}"

read -rp "Proceed with full setup using these values? [y/N] " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo ">>> STEP 1/8: System update"
"$SCRIPT_DIR/scripts/01-system-update.sh"

echo ""
echo ">>> STEP 2/8: Create non-root user"
echo "$NEW_USER" | "$SCRIPT_DIR/scripts/02-create-user.sh"

echo ""
echo ">>> STEP 3/8: Setup swap file"
"$SCRIPT_DIR/scripts/03-setup-swap.sh" 2

echo ""
echo ">>> STEP 4/8: Setup Python venv + dependencies"
"$SCRIPT_DIR/scripts/04-setup-venv.sh" "$APP_DIR" "$REQUIREMENTS_FILE"

echo ""
echo ">>> STEP 5/8: Setup Supervisor"
"$SCRIPT_DIR/scripts/05-setup-supervisor.sh" "$APP_NAME" "$APP_DIR" "$APP_MODULE" "$PORT" "$NEW_USER"

echo ""
echo ">>> STEP 6/8: Setup nginx"
"$SCRIPT_DIR/scripts/06-setup-nginx.sh" "$APP_NAME" "$PORT" "$SERVER_NAME"

echo ""
echo ">>> STEP 7/8: Setup firewall"
"$SCRIPT_DIR/scripts/07-setup-firewall.sh"

echo ""
echo ">>> STEP 8/8: Setup fail2ban"
"$SCRIPT_DIR/scripts/08-setup-fail2ban.sh"

echo ""
echo "================================================"
echo " ALL DONE"
echo "================================================"
echo "Summary:"
echo "  - Non-root user:     $NEW_USER (sudo enabled)"
echo "  - App directory:     $APP_DIR"
echo "  - Service name:      $APP_NAME (managed by Supervisor, runs as $NEW_USER)"
echo "  - Internal port:     $PORT"
echo "  - Reverse proxy:     nginx on port 80 -> 127.0.0.1:$PORT"
echo "  - Firewall:          UFW active, only 22/80/443 open"
echo "  - Brute-force guard: fail2ban active on SSH"
echo ""
echo "Next steps:"
echo "  1. Point your domain's DNS A record at this server's IP (if you have one)"
echo "  2. Re-run scripts/06-setup-nginx.sh with the domain as server_name"
echo "  3. Install certbot and run it to enable HTTPS"
echo "  4. Test the app: curl http://127.0.0.1:$PORT"

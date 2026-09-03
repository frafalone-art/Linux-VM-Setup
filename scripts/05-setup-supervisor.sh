#!/usr/bin/env bash
#
# 05-setup-supervisor.sh
# Installs Supervisor and configures it to run a FastAPI app (via uvicorn)
# as a background service that restarts automatically on crash or reboot.
#
# Usage: ./05-setup-supervisor.sh [app_name] [app_dir] [module:app] [port] [run_user]
# If arguments are omitted, you'll be prompted for them.
# Example: ./05-setup-supervisor.sh myapp /opt/myapp main:app 8000 deploy

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="$SCRIPT_DIR/../templates/supervisor.conf.template"

echo "=== [1/1] Setup Supervisor ==="
echo "This script will:"
echo "  1. Install Supervisor (if not already installed)"
echo "  2. Render the program config from templates/supervisor.conf.template"
echo "  3. Reload Supervisor and start the service"
echo ""

if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "ERROR: template not found at $TEMPLATE_FILE" >&2
    exit 1
fi

if [ $# -ge 1 ]; then APP_NAME="$1"; else read -rp "Service/app name (e.g. myapp): " APP_NAME; fi
if [ $# -ge 2 ]; then APP_DIR="$2"; else read -rp "Application directory (e.g. /opt/myapp): " APP_DIR; fi
if [ $# -ge 3 ]; then APP_MODULE="$3"; else read -rp "Uvicorn module:app (e.g. main:app): " APP_MODULE; fi
if [ $# -ge 4 ]; then PORT="$4"; else read -rp "Internal port [8000]: " PORT; PORT="${PORT:-8000}"; fi
if [ $# -ge 5 ]; then RUN_USER="$5"; else read -rp "User to run the service as [root]: " RUN_USER; RUN_USER="${RUN_USER:-root}"; fi

if [ -z "$APP_NAME" ] || [ -z "$APP_DIR" ] || [ -z "$APP_MODULE" ]; then
    echo "ERROR: app name, app directory and module:app are required." >&2
    exit 1
fi

if [ "$RUN_USER" = "root" ]; then
    echo "NOTE: no run_user given — the service will run as root."
    echo "      Consider passing the non-root user from 02-create-user.sh instead."
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root (use sudo)." >&2
    exit 1
fi

if [ ! -x "$APP_DIR/venv/bin/uvicorn" ]; then
    echo "ERROR: uvicorn not found at $APP_DIR/venv/bin/uvicorn" >&2
    echo "       Make sure uvicorn is in requirements.txt and 04-setup-venv.sh ran first." >&2
    exit 1
fi

echo "--> Installing Supervisor and gettext-base (for envsubst)..."
apt-get update -y
apt-get install -y supervisor gettext-base

CONFIG_PATH="/etc/supervisor/conf.d/${APP_NAME}.conf"
LOG_DIR="/var/log/${APP_NAME}"

echo "--> Creating log directory at $LOG_DIR..."
mkdir -p "$LOG_DIR"
chown "$RUN_USER" "$LOG_DIR" 2>/dev/null || true

echo "--> Rendering Supervisor config to $CONFIG_PATH..."
export APP_NAME APP_DIR APP_MODULE PORT RUN_USER LOG_DIR
# shellcheck disable=SC2016  # single quotes are intentional: envsubst needs the literal var list
envsubst '${APP_NAME} ${APP_DIR} ${APP_MODULE} ${PORT} ${RUN_USER} ${LOG_DIR}' < "$TEMPLATE_FILE" > "$CONFIG_PATH"

echo "--> Reloading Supervisor configuration..."
supervisorctl reread
supervisorctl update

echo "--> Starting/restarting the service..."
supervisorctl restart "${APP_NAME}" 2>/dev/null || supervisorctl start "${APP_NAME}"

echo ""
echo "=== DONE: Supervisor is managing '${APP_NAME}'. ==="
echo "Confirmation:"
supervisorctl status "${APP_NAME}"
echo ""
echo "Useful commands:"
echo "  sudo supervisorctl status ${APP_NAME}"
echo "  sudo supervisorctl restart ${APP_NAME}"
echo "  tail -f ${LOG_DIR}/${APP_NAME}.log"

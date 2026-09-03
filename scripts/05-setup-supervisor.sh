#!/usr/bin/env bash
#
# 05-setup-supervisor.sh
# Installs Supervisor and configures it to run a FastAPI app (via uvicorn)
# as a background service that restarts automatically on crash or reboot.
#
# Usage: ./05-setup-supervisor.sh <app_name> <app_dir> <module:app> [port] [run_user]
# Example: ./05-setup-supervisor.sh myapp /opt/myapp main:app 8000 deploy

set -euo pipefail

echo "=== [1/1] Setup Supervisor ==="
echo "This script will:"
echo "  1. Install Supervisor (if not already installed)"
echo "  2. Create a program config to run uvicorn under Supervisor"
echo "  3. Reload Supervisor and start the service"
echo ""

if [ $# -lt 3 ]; then
    echo "Usage: $0 <app_name> <app_dir> <module:app> [port] [run_user]" >&2
    echo "Example: $0 myapp /opt/myapp main:app 8000 deploy" >&2
    exit 1
fi

APP_NAME="$1"
APP_DIR="$2"
APP_MODULE="$3"
PORT="${4:-8000}"
RUN_USER="${5:-root}"

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

echo "--> Installing Supervisor..."
apt-get update -y
apt-get install -y supervisor

CONFIG_PATH="/etc/supervisor/conf.d/${APP_NAME}.conf"
LOG_DIR="/var/log/${APP_NAME}"

echo "--> Creating log directory at $LOG_DIR..."
mkdir -p "$LOG_DIR"
chown "$RUN_USER" "$LOG_DIR" 2>/dev/null || true

echo "--> Writing Supervisor config to $CONFIG_PATH..."
cat > "$CONFIG_PATH" <<EOF
[program:${APP_NAME}]
directory=${APP_DIR}
command=${APP_DIR}/venv/bin/uvicorn ${APP_MODULE} --host 0.0.0.0 --port ${PORT}
autostart=true
autorestart=true
startretries=3
user=${RUN_USER}
redirect_stderr=true
stdout_logfile=${LOG_DIR}/${APP_NAME}.log
stdout_logfile_maxbytes=10MB
stdout_logfile_backups=5
environment=PATH="${APP_DIR}/venv/bin"
EOF

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

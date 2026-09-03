#!/usr/bin/env bash
#
# 04-setup-venv.sh
# Creates the application directory, a Python virtual environment inside it,
# and installs dependencies from a requirements.txt file.
#
# Usage: ./04-setup-venv.sh <app_dir> <path_to_requirements.txt>
# Example: ./04-setup-venv.sh /opt/myapp ./requirements.txt

set -euo pipefail

echo "=== [1/1] Setup Python Environment ==="
echo "This script will:"
echo "  1. Create the application directory (if missing)"
echo "  2. Install python3-venv if not already present"
echo "  3. Create a virtual environment inside the app directory"
echo "  4. Install dependencies from requirements.txt"
echo ""

if [ $# -lt 2 ]; then
    echo "Usage: $0 <app_dir> <path_to_requirements.txt>" >&2
    exit 1
fi

APP_DIR="$1"
REQUIREMENTS_FILE="$2"

if [ ! -f "$REQUIREMENTS_FILE" ]; then
    echo "ERROR: requirements file not found: $REQUIREMENTS_FILE" >&2
    exit 1
fi

echo "--> Creating app directory: $APP_DIR"
mkdir -p "$APP_DIR"

echo "--> Ensuring python3-venv and python3-pip are installed..."
if [ "$(id -u)" -eq 0 ]; then
    apt-get update -y
    apt-get install -y python3-venv python3-pip
else
    sudo apt-get update -y
    sudo apt-get install -y python3-venv python3-pip
fi

echo "--> Creating virtual environment at $APP_DIR/venv..."
python3 -m venv "$APP_DIR/venv"

echo "--> Copying requirements file into the app directory..."
cp "$REQUIREMENTS_FILE" "$APP_DIR/requirements.txt"

echo "--> Upgrading pip inside the virtual environment..."
"$APP_DIR/venv/bin/pip" install --upgrade pip

echo "--> Installing dependencies from requirements.txt..."
"$APP_DIR/venv/bin/pip" install -r "$APP_DIR/requirements.txt"

echo ""
echo "=== DONE: Python environment ready. ==="
echo "Confirmation:"
echo "  - App directory: $APP_DIR"
echo "  - Virtual environment: $APP_DIR/venv"
echo "  - Python version: $("$APP_DIR/venv/bin/python" --version)"
echo "  - Installed packages:"
"$APP_DIR/venv/bin/pip" list --format=columns
echo ""
echo "To activate manually: source $APP_DIR/venv/bin/activate"

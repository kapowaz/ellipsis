#!/bin/bash
set -euo pipefail

REPO="kapowaz/ellipsis"
SCRIPT_NAME="ellipsis"

echo "Installing ellipsis..."

# Determine install directory
INSTALL_DIR=""
if echo "$PATH" | tr ':' '\n' | grep -q "^$HOME/bin$"; then
    INSTALL_DIR="$HOME/bin"
elif echo "$PATH" | tr ':' '\n' | grep -q "^$HOME/.local/bin$"; then
    INSTALL_DIR="$HOME/.local/bin"
else
    INSTALL_DIR="/usr/local/bin"
fi

echo "Install directory: $INSTALL_DIR"

# Create directory if needed
if [[ ! -d "$INSTALL_DIR" ]]; then
    if [[ "$INSTALL_DIR" == /usr/local/bin ]]; then
        sudo mkdir -p "$INSTALL_DIR"
    else
        mkdir -p "$INSTALL_DIR"
    fi
fi

# Download the script
DOWNLOAD_URL="https://raw.githubusercontent.com/${REPO}/main/${SCRIPT_NAME}"
DEST="${INSTALL_DIR}/${SCRIPT_NAME}"

if [[ "$INSTALL_DIR" == /usr/local/bin ]]; then
    sudo curl -fsSL "$DOWNLOAD_URL" -o "$DEST"
    sudo chmod +x "$DEST"
else
    curl -fsSL "$DOWNLOAD_URL" -o "$DEST"
    chmod +x "$DEST"
fi

echo ""
echo "Installed ellipsis to $DEST"
echo ""
echo "Next steps:"
echo "  1. Install yadm if you haven't: brew install yadm"
echo "  2. Set up your yadm repo: yadm init && yadm remote add origin <url>"
echo "  3. Run: ellipsis init"

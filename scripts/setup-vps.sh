#!/bin/bash
set -e

echo "🔧 Setting up VPS for automation system..."

# Update system and install required packages
echo "📦 Installing required packages..."
sudo apt update -y
sudo apt install -y podman git curl wget uidmap pipx

# Enable lingering to allow user services to run without login
echo "🔐 Enabling user lingering..."
sudo loginctl enable-linger "$(whoami)"

# Enable podman socket for user services
echo "🔌 Enabling Podman socket..."
systemctl --user enable --now podman.socket

# Install podman-compose (Debian PEP 668 safe)
echo "📦 Installing podman-compose..."
pipx ensurepath >/dev/null 2>&1 || true
export PATH="$HOME/.local/bin:$PATH"
pipx install -f podman-compose

# Set appropriate permissions (only if directory exists)
[ -d backups ] && chmod 700 backups

echo "✅ VPS setup completed for Step 1!"

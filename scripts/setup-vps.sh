#!/bin/bash
set -e

echo "🔧 Setting up VPS for automation system..."

# Update system and install required packages
echo "📦 Installing required packages..."
sudo apt update -y
sudo apt install -y podman podman-compose git curl wget

# Enable podman socket for user services
echo "🔌 Enabling Podman socket..."
systemctl --user enable --now podman.socket

# Enable lingering to allow user services to run without login
echo "🔐 Enabling user lingering..."
sudo loginctl enable-linger $(whoami)

# Set appropriate permissions
chmod 700 backups

echo "✅ VPS setup completed for Step 1!"

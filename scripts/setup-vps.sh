#!/usr/bin/env bash
set -euo pipefail

echo "🔧 Setting up VPS for automation system..."

if [[ "${EUID}" -eq 0 ]]; then
  echo "❌ Do not run this script as root. Run as a normal user with sudo access."
  exit 1
fi

echo "📦 Installing required packages..."
sudo apt update -y
sudo apt install -y \
  podman git curl wget uidmap pipx ca-certificates \
  nginx certbot python3-certbot-nginx

# Debian fix: Podman policy.json (required for image pulls)
if [[ ! -f /etc/containers/policy.json ]]; then
  echo "🛠 Creating /etc/containers/policy.json (Debian requirement for Podman)..."
  sudo mkdir -p /etc/containers
  sudo tee /etc/containers/policy.json >/dev/null <<'EOF'
{
  "default": [
    { "type": "insecureAcceptAnything" }
  ]
}
EOF
fi

echo "🔐 Enabling user lingering..."
sudo loginctl enable-linger "$(whoami)"

echo "🔌 Enabling Podman socket..."
systemctl --user enable --now podman.socket

echo "📦 Installing podman-compose..."
export PATH="$HOME/.local/bin:$PATH"
pipx ensurepath >/dev/null 2>&1 || true
pipx install -f podman-compose

echo "🌐 Enabling Nginx..."
sudo systemctl enable --now nginx

[ -d backups ] && chmod 700 backups

echo "✅ VPS setup completed!"
echo "Next: run 'make nginx' to configure reverse proxy + HTTPS."
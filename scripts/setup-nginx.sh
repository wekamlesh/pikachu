#!/usr/bin/env bash
set -euo pipefail

# Load env from repo root
if [[ ! -f ".env" ]]; then
  echo "❌ .env not found in current directory"
  exit 1
fi
set -a
source ".env"
set +a

DOMAIN="n8n.${BASE_DOMAIN}"
UPSTREAM="127.0.0.1:5678"

echo "🌐 Configuring Nginx for ${DOMAIN} -> ${UPSTREAM}"

sudo tee /etc/nginx/sites-available/n8n >/dev/null <<NGINX
server {
    listen 80;
    server_name ${DOMAIN};

    client_max_body_size 50m;

    location / {
        proxy_pass http://${UPSTREAM};
        proxy_http_version 1.1;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # WebSocket support (n8n UI)
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
NGINX

sudo ln -sf /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/n8n
sudo rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true

sudo nginx -t
sudo systemctl reload nginx

echo "🔐 Issuing HTTPS certificate via Certbot..."
sudo certbot --nginx -d "${DOMAIN}"

echo "✅ Nginx + HTTPS ready: https://${DOMAIN}"
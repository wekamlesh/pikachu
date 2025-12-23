#!/usr/bin/env bash
set -e

ENV_FILE=".env"
COMPOSE_DIR="podman"
COMPOSE_FILE="${COMPOSE_DIR}/compose.yml"

echo "🚀 Deploying n8n stack"
echo "======================"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "❌ .env file not found"
  exit 1
fi

if [[ ! -f "${COMPOSE_FILE}" ]]; then
  echo "❌ ${COMPOSE_FILE} not found"
  exit 1
fi

if ! command -v podman-compose >/dev/null 2>&1; then
  echo "❌ podman-compose not found. Run: make setup"
  exit 1
fi

set -a
source "${ENV_FILE}"
set +a
echo "✅ Environment loaded"

SERVICES="redis n8n"

echo "🔄 Starting containers: ${SERVICES}"
cd "${COMPOSE_DIR}"

podman-compose down || true
podman-compose up -d ${SERVICES}

cd ..

echo "⏳ Waiting for containers to start..."
sleep 20

echo "🔍 Checking containers..."
for container in redis n8n; do
  if podman ps --format "{{.Names}}" | grep -q "^${container}$"; then
    echo "✅ ${container} running"
  else
    echo "❌ ${container} not running"
    podman logs "${container}" || true
    exit 1
  fi
done

echo "🔍 Checking Redis..."
podman exec redis redis-cli -a "${REDIS_PASSWORD}" ping >/dev/null \
  && echo "✅ Redis OK" \
  || { echo "❌ Redis failed"; exit 1; }

echo "🌐 Checking n8n..."
curl -sf http://127.0.0.1:5678/healthz >/dev/null \
  && echo "✅ n8n healthy" \
  || { echo "❌ n8n unhealthy"; podman logs n8n; exit 1; }

echo "🌍 Checking public URL via Nginx (best effort)..."
curl -sf "https://n8n.${BASE_DOMAIN}/healthz" >/dev/null \
  && echo "✅ Public n8n OK" \
  || echo "⚠️ Public n8n not reachable yet (run: make nginx)"

echo ""
echo "🎉 Deployment complete!"
echo ""

podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "🔗 Access:"
echo "  https://n8n.${BASE_DOMAIN}"
echo ""
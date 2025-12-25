#!/usr/bin/env bash
set -euo pipefail
umask 077

# ------------------------------------------------------------
# n8n Backup Script (Local + pCloud)
#
# - Timestamped folder: YYYY-MM-DD_HH-MM-SS
# - Local: /var/backups/n8n/<timestamp>/
# - Cloud: pcloud:Apps/rclone/n8n_backup/<timestamp>/
# - Retention: 7 days (local + cloud)
# - Logs: ./logs/n8n_backup.log
# ------------------------------------------------------------

TS="$(date +'%F_%H-%M-%S')"   # uses server timezone (IST if configured)
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

LOG_DIR="${PROJECT_ROOT}/logs"
LOG_FILE="${LOG_DIR}/n8n_backup.log"

BACKUP_ROOT="/var/backups/n8n"
BACKUP_DIR="${BACKUP_ROOT}/${TS}"

ALPINE_IMAGE="docker.io/alpine:3.20"

# Compose volume names (from compose.yml)
COMPOSE_N8N_VOL="n8n-data"
COMPOSE_REDIS_VOL="redis_data"

# pCloud rclone remote + fixed visible path
REMOTE="pcloud"
CLOUD_BASE="n8n_backup"

# ------------------------------------------------------------
# Setup logging
# ------------------------------------------------------------
mkdir -p "${LOG_DIR}"
exec >>"${LOG_FILE}" 2>&1

echo "===================================================="
echo "🕛 Backup started at $(date)"
echo "📦 Backup folder: ${TS}"
echo "===================================================="

# ------------------------------------------------------------
# Detect actual Podman volume names
# ------------------------------------------------------------
N8N_VOL="$(podman volume ls --format '{{.Name}}' | grep -E "(^|_)${COMPOSE_N8N_VOL}$" | head -n1 || true)"
REDIS_VOL="$(podman volume ls --format '{{.Name}}' | grep -E "(^|_)${COMPOSE_REDIS_VOL}$" | head -n1 || true)"

if [[ -z "${N8N_VOL}" || -z "${REDIS_VOL}" ]]; then
  echo "❌ Could not detect Podman volumes"
  podman volume ls
  exit 1
fi

echo "✅ Using volumes:"
echo "  - n8n   → ${N8N_VOL}"
echo "  - redis → ${REDIS_VOL}"

# ------------------------------------------------------------
# Prepare local backup directory
# ------------------------------------------------------------
sudo mkdir -p "${BACKUP_DIR}"
sudo chown "$(whoami):$(whoami)" "${BACKUP_ROOT}" "${BACKUP_DIR}"

# ------------------------------------------------------------
# Backup n8n volume
# ------------------------------------------------------------
echo "📦 Backing up n8n volume..."
podman run --rm --pull=missing \
  -v "${N8N_VOL}":/data:ro \
  -v "${BACKUP_DIR}":/backup \
  "${ALPINE_IMAGE}" \
  tar czf "/backup/n8n_data_${TS}.tar.gz" -C /data .

# ------------------------------------------------------------
# Backup redis volume
# ------------------------------------------------------------
echo "📦 Backing up redis volume..."
podman run --rm --pull=missing \
  -v "${REDIS_VOL}":/data:ro \
  -v "${BACKUP_DIR}":/backup \
  "${ALPINE_IMAGE}" \
  tar czf "/backup/redis_data_${TS}.tar.gz" -C /data .

# ------------------------------------------------------------
# Backup .env file
# ------------------------------------------------------------
if [[ -f "${PROJECT_ROOT}/.env" ]]; then
  cp "${PROJECT_ROOT}/.env" "${BACKUP_DIR}/env_${TS}.env"
fi

# ------------------------------------------------------------
# Copy log snapshot into backup folder
# ------------------------------------------------------------
cp "${LOG_FILE}" "${BACKUP_DIR}/backup_log_${TS}.log"

# ------------------------------------------------------------
# Upload to pCloud (FIXED PATH)
# ------------------------------------------------------------
echo "☁️ Uploading to pCloud → ${REMOTE}:${CLOUD_BASE}/${TS}"
rclone copy "${BACKUP_DIR}" "${REMOTE}:${CLOUD_BASE}/${TS}" --progress

# ------------------------------------------------------------
# Retention: local backups older than 7 days
# ------------------------------------------------------------
echo "🧹 Cleaning local backups older than 7 days..."
find "${BACKUP_ROOT}" -mindepth 1 -maxdepth 1 -type d -mtime +7 -exec rm -rf {} \;

# ------------------------------------------------------------
# Retention: cloud backups older than 7 days
# ------------------------------------------------------------
echo "🧹 Cleaning cloud backups older than 7 days..."
rclone delete "${REMOTE}:${CLOUD_BASE}" --min-age 7d
rclone rmdirs "${REMOTE}:${CLOUD_BASE}" --leave-root

echo "✅ Backup completed successfully at $(date)"
echo
#!/usr/bin/env bash
set -euo pipefail
umask 077

# ------------------------------------------------------------
# Backup n8n + redis volumes
# - Folder name includes timestamp: YYYY-MM-DD_HH-MM-SS
# - Local backups: /var/backups/n8n/<timestamp>/
# - Cloud backups: <REMOTE>:n8n_backup/<timestamp>/
# - Retention: 7 days local + remote
# - Logs: ./logs/n8n_backup.log (and copied into each backup)
# ------------------------------------------------------------

TS="$(date +'%F_%H-%M-%S')"   # uses server timezone (set to Asia/Kolkata for IST)
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

LOG_DIR="${PROJECT_ROOT}/logs"
LOG_FILE="${LOG_DIR}/n8n_backup.log"

BACKUP_ROOT="/var/backups/n8n"
BACKUP_DIR="${BACKUP_ROOT}/${TS}"

ALPINE_IMAGE="docker.io/alpine:3.20"

# Compose volume names from compose.yml
COMPOSE_N8N_VOL="n8n-data"
COMPOSE_REDIS_VOL="redis_data"

# ✅ Cloud destination folder name requested by you
CLOUD_FOLDER="n8n_backup"

# 🔧 CHANGE THIS to your rclone remote name (examples: pcloud, gdrive, s3, onedrive)
# Example: REMOTE="pcloud"
REMOTE="${RCLONE_REMOTE:-pcloud}"

# Create logs folder and redirect all output to log file
mkdir -p "${LOG_DIR}"
exec >>"${LOG_FILE}" 2>&1

echo "===================================================="
echo "🕛 Backup started at $(date)"
echo "📦 Backup folder: ${TS}"
echo "===================================================="

# Detect actual podman volume names (podman-compose may prefix them)
N8N_VOL="$(podman volume ls --format '{{.Name}}' | grep -E "(^|_)${COMPOSE_N8N_VOL}$" | head -n1 || true)"
REDIS_VOL="$(podman volume ls --format '{{.Name}}' | grep -E "(^|_)${COMPOSE_REDIS_VOL}$" | head -n1 || true)"

if [[ -z "${N8N_VOL}" || -z "${REDIS_VOL}" ]]; then
  echo "❌ Could not detect volumes."
  echo "Expected volumes ending with:"
  echo "  - ${COMPOSE_N8N_VOL}"
  echo "  - ${COMPOSE_REDIS_VOL}"
  echo "Existing volumes:"
  podman volume ls
  exit 1
fi

echo "✅ Using volumes:"
echo "  - n8n   → ${N8N_VOL}"
echo "  - redis → ${REDIS_VOL}"

# Prepare local backup directory
sudo mkdir -p "${BACKUP_DIR}"
sudo chown "$(whoami):$(whoami)" "${BACKUP_ROOT}" "${BACKUP_DIR}"

# Backup n8n volume
echo "📦 Backing up n8n volume..."
podman run --rm --pull=missing \
  -v "${N8N_VOL}":/data:ro \
  -v "${BACKUP_DIR}":/backup \
  "${ALPINE_IMAGE}" \
  tar czf "/backup/n8n_data_${TS}.tar.gz" -C /data .

# Backup redis volume
echo "📦 Backing up redis volume..."
podman run --rm --pull=missing \
  -v "${REDIS_VOL}":/data:ro \
  -v "${BACKUP_DIR}":/backup \
  "${ALPINE_IMAGE}" \
  tar czf "/backup/redis_data_${TS}.tar.gz" -C /data .

# Backup env file (repo root)
if [[ -f "${PROJECT_ROOT}/.env" ]]; then
  cp "${PROJECT_ROOT}/.env" "${BACKUP_DIR}/env_${TS}.env"
fi

# Copy log into backup folder (snapshot of this run)
cp "${LOG_FILE}" "${BACKUP_DIR}/backup_log_${TS}.log"

# Upload to cloud
echo "☁️ Uploading to cloud: ${REMOTE}:${CLOUD_FOLDER}/${TS}"
rclone copy "${BACKUP_DIR}" "${REMOTE}:${CLOUD_FOLDER}/${TS}" --progress

# Retention: local backups older than 7 days
echo "🧹 Cleaning local backups older than 7 days..."
find "${BACKUP_ROOT}" -mindepth 1 -maxdepth 1 -type d -mtime +7 -exec rm -rf {} \;

# Retention: cloud backups older than 7 days
echo "🧹 Cleaning cloud backups older than 7 days..."
rclone delete "${REMOTE}:${CLOUD_FOLDER}" --min-age 7d
rclone rmdirs "${REMOTE}:${CLOUD_FOLDER}" --leave-root

echo "✅ Backup completed successfully at $(date)"
echo
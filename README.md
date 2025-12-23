# n8n Podman Stack

Deployment scripts for running n8n behind Nginx on a VPS using Podman + podman-compose with Redis for queues/cache and an external PostgreSQL (e.g. Aiven).

## Prerequisites
- Debian/Ubuntu host with sudo
- DNS `n8n.${BASE_DOMAIN}` pointing to the VPS
- Podman + podman-compose, Nginx, Certbot (installed via `make setup`)

## Quick start
1) Copy env template and fill secrets (strong randoms for `N8N_PASSWORD`, `N8N_ENCRYPTION_KEY`, `REDIS_PASSWORD`):
   ```bash
   cp .env.example .env
   ```
2) Prep the server (installs deps, enables lingering + podman socket, Nginx):
   ```bash
   make setup
   ```
3) Deploy the containers:
   ```bash
   make deploy
   ```
4) Provision HTTPS + reverse proxy:
   ```bash
   make nginx
   ```

## What gets deployed
- `n8n` (latest) bound to `127.0.0.1:5678` with basic auth enabled
- `redis:7-alpine` for queue/cache (auth required)
- Health checks for both services; resource limits set on containers

## Management
- `podman ps` to inspect running containers
- `podman logs n8n` / `podman logs redis` for diagnostics
- `podman-compose -f podman/compose.yml down` to stop the stack

## Notes
- `WEBHOOK_URL` should match the public HTTPS endpoint (`https://n8n.${BASE_DOMAIN}`) so webhooks work.
- PostgreSQL credentials/SSL flags are loaded from `.env` and passed directly to n8n.
- If Certbot fails (rate limits/DNS), rerun `make nginx` after fixing DNS.

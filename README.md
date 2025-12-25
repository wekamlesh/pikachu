```markdown
# 🚀 n8n Podman Stack

Production-ready setup for running **n8n** on a VPS using **Podman + podman-compose**, **Redis** (queue/cache), **external PostgreSQL** (e.g. Aiven), **Nginx** on the host, and **automated backups to pCloud**.

---

## 🏗️ Architecture Overview

```
🌐 Internet
    ↓
🔒 Nginx (host, :80/:443, HTTPS)
    ↓
⚡ n8n (Podman, 127.0.0.1:5678)
    ↓
💾 Redis (Podman, queue/cache)
    ↓
🗄️ External PostgreSQL (Aiven)
```

---

## ✅ Prerequisites

- 🖥️ Debian/Ubuntu VPS with `sudo`
- 🌍 DNS record: `n8n.${BASE_DOMAIN}` → VPS public IP
- ☁️ pCloud account with `rclone` configured
- 🔌 Internet access from VPS to PostgreSQL provider

**Required variables:**
- `BASE_DOMAIN`
- `N8N_USER`
- `N8N_PASSWORD`
- `N8N_ENCRYPTION_KEY`
- `REDIS_PASSWORD`
- PostgreSQL credentials (Aiven or similar)

---

## 🛠️ Setup

### 1️⃣ Prepare the VPS

Installs:
- Podman + podman-compose
- Nginx + Certbot
- Required system configuration

```bash
make setup
```

### 2️⃣ Deploy containers

Starts n8n and Redis:

```bash
make deploy
```

### 3️⃣ Configure HTTPS + reverse proxy

Creates Nginx config and provisions Let's Encrypt certificate:

```bash
make nginx
```

🎉 **Access n8n at:** `https://n8n.${BASE_DOMAIN}`

---

## 📦 What Gets Deployed

### 🐳 Containers

**⚡ n8n**
- Bound to `127.0.0.1:5678`
- Basic auth enabled
- Redis queue mode enabled
- External PostgreSQL backend

**💾 Redis**
- Password protected
- Used for queue + cache

### 🖥️ Host Services

- **🔒 Nginx** (host-level, reverse proxy)
- **🔐 Certbot** for automatic HTTPS

---

## 💾 Backups (Local + pCloud)

### 📂 What is backed up

- n8n volume (`n8n-data`)
- Redis volume (`redis_data`)
- `.env` file (snapshot)
- Backup log snapshot

### 📁 Backup Format

Each backup creates a timestamped folder:

```
YYYY-MM-DD_HH-MM-SS/
```

**Example:**

```
2025-12-26_00-00-01/
├── n8n_data_2025-12-26_00-00-01.tar.gz
├── redis_data_2025-12-26_00-00-01.tar.gz
├── env_2025-12-26_00-00-01.env
└── backup_log_2025-12-26_00-00-01.log
```

### 💻 Local Storage

```
/var/backups/n8n/<timestamp>/
```

### ☁️ Cloud Storage (pCloud)

```
pcloud:Apps/rclone/n8n_backup/<timestamp>/
```

Visible in pCloud UI: **Apps → rclone → n8n_backup**

### ▶️ Run Backup Manually

```bash
./scripts/backup.sh
```

**📋 View Logs:**

```bash
tail -n 50 ~/pikachu/logs/n8n_backup.log
```

### ⏰ Automatic Backups (cron)

Runs daily at **12:00 AM IST**:

```cron
0 0 * * * cd /home/tenzo/pikachu && ./scripts/backup.sh
```

**🗑️ Retention policy:**
- Local backups older than 7 days → deleted
- Cloud backups older than 7 days → deleted

---

## 🔄 Restore

Restore from a backup folder placed in the current directory.

**📁 Example Folder:**

```
./2025-12-26_00-00-01/
```

**🔧 Restore Command:**

```bash
./scripts/restore.sh 2025-12-26_00-00-01
```

**What restore does:**

1. ⏹️ Stops n8n + Redis
2. 🧹 Clears volumes
3. 📥 Restores data from backup
4. ▶️ Starts containers again

**📋 Check logs after restore:**

```bash
podman logs -f n8n
```

---

## ⚙️ Management Commands

**👀 View running containers:**

```bash
podman ps
```

**📋 View logs:**

```bash
podman logs n8n
podman logs redis
```

**⏹️ Stop stack:**

```bash
cd podman && podman-compose down
```

**▶️ Start stack:**

```bash
cd podman && podman-compose up -d
```

---

## ⚠️ Important Notes

- 🔗 `WEBHOOK_URL` must match the public HTTPS endpoint: `https://n8n.${BASE_DOMAIN}`
- 🔐 PostgreSQL SSL flags are passed directly via `.env`
- 🔒 Nginx handles all public traffic; containers are bound to `127.0.0.1`
- 📦 Backups use Podman volumes, not container filesystems

---

## ✨ Status

This setup is:

- ✅ Production-ready
- ✅ Rootless containers
- ✅ HTTPS enabled
- ✅ Automated backups
- ✅ Simple restore
- ✅ Low operational overhead

---

## 📚 Quick Reference

| Command | Description |
|---------|-------------|
| `make setup` | 🛠️ Initial VPS setup |
| `make deploy` | 🚀 Deploy containers |
| `make nginx` | 🔒 Setup HTTPS |
| `./scripts/backup.sh` | 💾 Manual backup |
| `./scripts/restore.sh <folder>` | 🔄 Restore backup |
| `podman ps` | 👀 List containers |
| `podman logs n8n` | 📋 View n8n logs |

---

**Made with ❤️ for production n8n deployments**
```
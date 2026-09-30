#!/usr/bin/env bash
# IronForge hardening on yarmuk — run ONCE after first deploy.
# - UFW: default deny incoming, allow SSH + the host's existing public :80 (nginx)
# - unattended-upgrades for security patches
# - nightly SQLite backup cron (14-day retention)
# Does NOT touch existing docker containers or user keys.
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then echo "run with sudo"; exit 1; fi

# Validate backup prerequisites before changing any host configuration.
PROJECT_DIR=$(cd "${IRONFORGE_DIR:-$(dirname "${BASH_SOURCE[0]}")/..}" && pwd)
DOCKER_BIN=$(command -v docker)
command -v crontab >/dev/null
[ -f "$PROJECT_DIR/server/docker-compose.yml" ] || { echo 'Set IRONFORGE_DIR to the deployment root' >&2; exit 1; }
# Cron treats % specially, even inside quotes.
if [[ "$PROJECT_DIR$DOCKER_BIN" == *[\'%$'\n']* ]]; then
  echo 'Unsupported quote, percent or newline in deployment/tool path' >&2
  exit 1
fi

echo "==> UFW"
ufw allow 22/tcp comment 'ssh'
ufw allow 80/tcp comment 'existing public web'
ufw default deny incoming
ufw --force enable
ufw status verbose

echo "==> unattended-upgrades"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq unattended-upgrades >/dev/null
dpkg-reconfigure -f noninteractive unattended-upgrades >/dev/null || true

echo "==> backup cron (nightly 02:00)"
CRON_LINE="0 2 * * * cd '$PROJECT_DIR/server' && '$DOCKER_BIN' compose exec -T ironforge node src/backup.js # ironforge-backup"
# Backups live in the named volume at /data/backups, NOT server/data on the host.
# Replace the broken legacy job; preserve unrelated jobs and support no crontab.
EXISTING_CRON=$(crontab -l 2>/dev/null || true)
KEPT_CRON=$(printf '%s\n' "$EXISTING_CRON" | grep -v -E 'ironforge-backup|docker compose.*ironforge.*db\.backup' || true)
{ printf '%s\n' "$KEPT_CRON"; printf '%s\n' "$CRON_LINE"; } | crontab -
echo 'cron installed/updated; verify a backup and restore before relying on it'
echo 'Copy /data/backups out of the container to independent storage for disaster recovery.'

echo "==> ssh password auth check (do NOT disable until you confirm key login from every device)"
if grep -q '^PasswordAuthentication yes' /etc/ssh/sshd_config.d/*.conf /etc/ssh/sshd_config 2>/dev/null; then
  echo "WARNING: PasswordAuthentication is enabled somewhere — consider disabling after verifying keys work"
else
  echo "PasswordAuthentication already disabled (key-only)"
fi

echo "==> done"

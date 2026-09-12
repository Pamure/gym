#!/usr/bin/env bash
# IronForge hardening on yarmuk — run ONCE after first deploy.
# - UFW: default deny incoming, allow SSH + the host's existing public :80 (nginx)
# - unattended-upgrades for security patches
# - nightly SQLite backup cron (14-day retention)
# Does NOT touch existing docker containers or user keys.
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then echo "run with sudo"; exit 1; fi

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
mkdir -p /home/gomango/ironforge/server/data/backups
CRON_LINE="0 2 * * * cd /home/gomango/ironforge && docker compose -f server/docker-compose.yml exec -T ironforge node -e \"const db=require('better-sqlite3')('/data/ironforge.db');db.backup('/data/backups/ironforge-' + new Date().toISOString().slice(0,10) + '.db');db.close()\" && find /home/gomango/ironforge/server/data/backups -name 'ironforge-*.db' -mtime +14 -delete"
if ! crontab -l 2>/dev/null | grep -q ironforge; then
  (crontab -l 2>/dev/null; echo "$CRON_LINE") | crontab -
  echo "cron installed"
else
  echo "cron already present"
fi

echo "==> ssh password auth check (do NOT disable until you confirm key login from every device)"
if grep -q '^PasswordAuthentication yes' /etc/ssh/sshd_config.d/*.conf /etc/ssh/sshd_config 2>/dev/null; then
  echo "WARNING: PasswordAuthentication is enabled somewhere — consider disabling after verifying keys work"
else
  echo "PasswordAuthentication already disabled (key-only)"
fi

echo "==> done"

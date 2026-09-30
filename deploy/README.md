# Deployment safety notes

These scripts change a remote server or host configuration. Review them and
obtain authorization before running them; automated regression tests only parse
and inspect them, never execute deployment/hardening.

## Deploy

- `deploy.sh --no-apk` does not upload or delete the remote `downloads/` directory.
  APK replacement occurs only after an explicit successful APK build, in its own
  upload step. This does not solve the existing Android release-signing setup.
- Put Flutter and rsync on `PATH`, or set `FLUTTER_BIN` / `RSYNC_BIN` to executable
  paths. `FLUTTER_ROOT/bin/flutter` and common home-directory SDK locations are
  fallbacks. Missing local tools or remote SSH/rsync/Docker/Compose fail preflight.
- Local `.env*`, `data/`, `node_modules/`, and `test/` never go through the server
  rsync. Remote secrets are protected from rsync deletion. `.dockerignore` also
  excludes env files and data from Docker build context. AI credentials must be
  configured deliberately on the remote host; no local key is copied implicitly.
- A missing remote `.env` requires explicit `--provision` and an interactive
  password. Existing files are never overwritten. Passwords are not printed,
  exported, passed as command-line arguments, or saved to local temporary files.
  A private-at-creation remote temporary file is published atomically without
  clobbering an existing `.env`, with trap cleanup on normal errors/signals.
- Provisioning writes only the bootstrap username and
  `BOOTSTRAP_PASSWORD_BASE64`. Base64 is **not encryption**: this value is a
  credential, but avoids Compose interpolation of `$`, quotes, `#`, spaces, etc.
  The server still accepts legacy `BOOTSTRAP_PASSWORD`. After confirming login,
  securely remove bootstrap password variables from the remote `.env`; password
  changes in the app do not remove those variables for you.
- Provisioning does not set an unused session secret or a provider key. Do not
  enable shell tracing (`bash -x`) around any credential-handling deployment.

## Backups and hardening

`harden.sh` retains its existing firewall/package operations. Its backup job now
runs `node src/backup.js` inside the application container. The helper awaits the
SQLite backup, verifies it, publishes it atomically, and only then expires backups
older than 14 days. Both snapshot creation and retention use `/data/backups` in
the named Docker volume. The script replaces the old broken inline backup job
and supports an initially empty crontab.

Run hardening from the deployed checkout, or explicitly set `IRONFORGE_DIR` to
its root (containing `server/docker-compose.yml`). Docker/crontab/path checks
happen before host changes. The application image must contain the new
`src/backup.js` before installing the job.

**A same-volume backup is not disaster recovery.** It does not protect against
volume loss, host loss, or compromise. Export verified snapshots from the
container's `/data/backups` to access-controlled independent storage. The host
`server/data/backups` directory is not the named-volume backup location. Arrange
monitoring for backup/cron failures, verify container-volume permissions on the
actual host, and rehearse a restore to a separate disposable database before
making production recovery guarantees. No production backup/restore, SSH,
Docker, rsync, firewall, package, or crontab operation was run as part of these
repairs.

#!/usr/bin/env bash
# IronForge deploy — build web + APK, rsync to yarmuk, docker compose up.
# Usage: ./deploy/deploy.sh [--no-apk] [--provision]
# --provision explicitly permits first-run credential creation (interactive only).
# Existing remote secrets are never replaced; local .env / AI keys never transfer.
set -euo pipefail
cd "$(dirname "$0")/.."
umask 077

SKIP_APK=0
PROVISION=0
for arg in "$@"; do
  case "$arg" in
    --no-apk) SKIP_APK=1 ;;
    --provision) PROVISION=1 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

# Respect PATH and explicit tool overrides; no machine-specific absolute paths.
FLUTTER_BIN="${FLUTTER_BIN:-flutter}"
RSYNC_BIN="${RSYNC_BIN:-rsync}"
if ! command -v "$FLUTTER_BIN" >/dev/null 2>&1; then
  for candidate in "${FLUTTER_ROOT:-}/bin/flutter" "$HOME/development/flutter/bin/flutter" "$HOME/flutter/bin/flutter" "$HOME/downloads/dev/flutter/bin/flutter"; do
    if [ -x "$candidate" ]; then FLUTTER_BIN="$candidate"; break; fi
  done
fi
for tool in "$FLUTTER_BIN" "$RSYNC_BIN" ssh node; do
  command -v "$tool" >/dev/null 2>&1 || { echo "Missing tool: $tool (set PATH, FLUTTER_BIN or RSYNC_BIN)" >&2; exit 1; }
done
# Resolve before the build's cd app, including overrides/relative PATH entries.
FLUTTER_BIN=$(command -v "$FLUTTER_BIN")
RSYNC_BIN=$(command -v "$RSYNC_BIN")
[[ "$FLUTTER_BIN" = /* ]] || FLUTTER_BIN="$PWD/$FLUTTER_BIN"
[[ "$RSYNC_BIN" = /* ]] || RSYNC_BIN="$PWD/$RSYNC_BIN"

REMOTE="yarmuk"
RDIR="~/ironforge"
# Check connectivity/tools separately: an SSH failure is NOT a first-run signal.
ssh "$REMOTE" 'command -v rsync >/dev/null && command -v docker >/dev/null && docker compose version >/dev/null' || {
  echo 'Remote preflight failed: verify SSH access, rsync, Docker and Docker Compose on the server.' >&2
  exit 1
}
ENV_STATUS=$(ssh "$REMOTE" 'if [ -f ~/ironforge/server/.env ]; then echo present; else echo absent; fi')
if [ "$ENV_STATUS" = absent ] && [ "$PROVISION" -ne 1 ]; then
  echo 'Remote .env is absent. Re-run interactively with --provision or provision it securely on the server.' >&2
  exit 1
fi
if [ "$ENV_STATUS" = absent ] && [ ! -t 0 ]; then
  echo 'First-run provisioning requires an interactive terminal; no password will be generated or printed.' >&2
  exit 1
fi

# Build before provisioning/syncing, so a failed build cannot change remote secrets.
echo "==> flutter pub get"
(cd app && "$FLUTTER_BIN" pub get >/dev/null)
echo "==> flutter build web --release"
(cd app && "$FLUTTER_BIN" build web --release)
if [ "$SKIP_APK" -eq 0 ]; then
  echo "==> flutter build apk --release --split-per-abi"
  (cd app && "$FLUTTER_BIN" build apk --release --split-per-abi)
fi

FIRST_RUN=0
if [ "$ENV_STATUS" = absent ]; then
  printf 'Create the app password (10-128 characters; not printed): '
  IFS= read -rs BOOTSTRAP_PASSWORD
  printf '\n'
  # Validate before opening the remote credential file. No local plaintext file,
  # password argument, inherited environment export, or automatic AI-key transfer.
  printf '%s' "$BOOTSTRAP_PASSWORD" | node deploy/bootstrap-env.mjs >/dev/null
  printf '%s' "$BOOTSTRAP_PASSWORD" | node deploy/bootstrap-env.mjs | ssh "$REMOTE" '
    set -eu
    umask 077
    mkdir -p ~/ironforge/server
    tmp=$(mktemp ~/ironforge/server/.env.provision.XXXXXX)
    trap '\''rm -f "$tmp"'\'' EXIT HUP INT TERM
    cat > "$tmp"
    test -s "$tmp"
    # Atomic, no-clobber publish; permissions are private from file creation.
    ln "$tmp" ~/ironforge/server/.env
  '
  unset BOOTSTRAP_PASSWORD
  FIRST_RUN=1
fi

echo "==> rsync to $REMOTE"
ssh "$REMOTE" 'mkdir -p ~/ironforge/server/web ~/ironforge/server/downloads ~/ironforge/server/media ~/ironforge/server/data'
# Exclusions also protect remote runtime/artifact files from --delete. APKs are
# managed exclusively by the explicit upload below, never by the server sync.
"$RSYNC_BIN" -avz --delete --exclude '.env*' --exclude /data/ --exclude /downloads/ \
  --exclude /node_modules/ --exclude /test/ --exclude /web/ \
  server/ "$REMOTE:$RDIR/server/"
"$RSYNC_BIN" -avz --delete app/build/web/ "$REMOTE:$RDIR/server/web/"
"$RSYNC_BIN" -avz app/assets/gifs/ "$REMOTE:$RDIR/server/media/"
if [ "$SKIP_APK" -eq 0 ]; then
  "$RSYNC_BIN" -avz app/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk \
    "$REMOTE:$RDIR/server/downloads/ironforge.apk"
fi

echo "==> docker compose up -d --build"
ssh "$REMOTE" 'cd ~/ironforge/server && docker compose up -d --build' 2>&1 | tail -3

echo "==> verify"
if ssh "$REMOTE" 'curl -sf http://127.0.0.1:8420/api/health' | grep -q '"ok":true'; then
  echo "DEPLOY OK"
  if [ "$FIRST_RUN" -eq 1 ]; then
    echo 'Next: open the configured site, log in as mjonir with the password you entered, and set your program start date.'
    echo 'After confirming login, remove BOOTSTRAP_PASSWORD_BASE64 from the remote .env; it is no longer needed.'
  fi
else
  echo "DEPLOY FAILED — check: ssh $REMOTE 'docker compose -f ~/ironforge/server/docker-compose.yml logs'"
  exit 1
fi

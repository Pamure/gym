#!/usr/bin/env bash
# IronForge deploy — build web + APK, rsync to yarmuk, docker compose up.
# Usage: ./deploy/deploy.sh [--no-apk]
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$PATH:/home/mjonir/downloads/dev/flutter/bin"

SKIP_APK=0
[ "${1:-}" = "--no-apk" ] && SKIP_APK=1

REMOTE="yarmuk"
RDIR="~/ironforge"

# ---------- first-run server secret provisioning ----------
FIRST_RUN=0
if ! ssh "$REMOTE" "[ -f ~/ironforge/server/.env ]"; then
  FIRST_RUN=1
  echo "==> First run on $REMOTE — provisioning secrets"
  ssh "$REMOTE" "mkdir -p $RDIR/server/{web,downloads,media,data}"
  SESSION_SECRET=$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")
  if [ -t 0 ]; then
    echo -n "Create the app password (min 10 chars, will only be stored on the server): "
    IFS= read -rs BOOTSTRAP_PASSWORD
    echo
  else
    BOOTSTRAP_PASSWORD=$(node -e "console.log(require('crypto').randomBytes(12).toString('base64url'))")
    echo "Generated initial password (printed once — change it in the app after first login):"
    echo "    $BOOTSTRAP_PASSWORD"
  fi
  cat > /tmp/if-env <<EOF
SESSION_SECRET=$SESSION_SECRET
BOOTSTRAP_USERNAME=mjonir
BOOTSTRAP_PASSWORD=$BOOTSTRAP_PASSWORD
EOF
  scp -q /tmp/if-env "$REMOTE:$RDIR/server/.env"
  rm -f /tmp/if-env
  ssh "$REMOTE" "chmod 600 $RDIR/server/.env"
fi

echo "==> flutter pub get"
(cd app && flutter pub get >/dev/null)

echo "==> flutter build web --release"
(cd app && flutter build web --release)

if [ "$SKIP_APK" -eq 0 ]; then
  echo "==> flutter build apk --release --split-per-abi"
  (cd app && flutter build apk --release --split-per-abi)
fi

echo "==> rsync to $REMOTE"
ssh "$REMOTE" "mkdir -p $RDIR/server/{web,downloads,media,data}"
rsync -avz --delete --exclude .env --exclude data \
  server/ "$REMOTE:$RDIR/server/"
rsync -avz --delete app/build/web/ "$REMOTE:$RDIR/server/web/"
rsync -avz app/assets/gifs/ "$REMOTE:$RDIR/server/media/"
if [ "$SKIP_APK" -eq 0 ]; then
  rsync -avz app/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk \
    "$REMOTE:$RDIR/server/downloads/ironforge.apk"
fi

echo "==> docker compose up -d --build"
ssh "$REMOTE" 'cd ~/ironforge/server && docker compose up -d --build' 2>&1 | tail -3

echo "==> verify"
if ssh "$REMOTE" 'curl -sf http://127.0.0.1:8420/api/health' | grep -q '"ok":true'; then
  echo "DEPLOY OK"
  if [ "$FIRST_RUN" -eq 1 ]; then
    echo
    echo "Next steps (do these now):"
    echo "  1. Open https://gym.abba-s.dev (your Cloudflare tunnel must point at localhost:8420)"
    echo "  2. Login: mjonir + the password above (interactive) / generated password"
    echo "  3. Settings -> Change password (if generated)"
    echo "  4. Settings -> Set program start date"
  fi
else
  echo "DEPLOY FAILED — check: ssh $REMOTE 'docker compose -f ~/ironforge/server/docker-compose.yml logs'"
  exit 1
fi

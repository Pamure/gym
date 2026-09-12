# 12 — Tech Stack & Deployment (All Decisions + Commands)

## Environment (verified 2026-09-05)

**Local machine (this WSL2):**
- Flutter 3.47.1 stable, Android SDK 36, Chrome, Linux toolchain — `flutter doctor` clean
- Flutter path: `/home/mjonir/downloads/dev/flutter/bin` (add to PATH before builds)
- Project root: `/home/mjonir/f/gym/`

**Server `yarmuk` (via `ssh yarmuk`):**
- Ubuntu 24.04.4 LTS, 4 CPU, 15 GB RAM, 194 GB free on /
- Docker 29.2.1, user `gomango` (in docker + sudo groups)
- cloudflared installed at `/usr/local/bin/cloudflared`
- Existing containers (DO NOT TOUCH): osrm-router (5000), nakama_server (7350-7360),
  nakama_postgres, sih_collab (3000), autoboard (3001), autoboard-db
- **Our port: 127.0.0.1:8420 — verified free**
- **Our folder: /home/gomango/ironforge/ — separate from everything existing**

## Stack decisions (boring = reliable)

| Choice | Why |
|---|---|
| Flutter one codebase → APK + web | You asked for app + website; Flutter ships both from one repo, mobile-responsive by default |
| Node.js 22 + Fastify | Tiny, fast, huge ecosystem, the agent knows it cold |
| better-sqlite3 | Zero-config DB, data in ONE file, trivial backup; perfect for single-user |
| argon2id password hashing | Current best practice, memory-hard |
| No framework on backend beyond Fastify | Fewer deps = fewer CVEs |
| Docker + compose | Reproducible, isolated from yarmuk's other services |
| Cloudflare Tunnel + Access | No inbound ports, edge authentication (knowledge/11) |
| localStorage in app + server sync | Works offline at the gym, syncs when online |

## Repository layout (`/home/mjonir/f/gym/`)
```
gym/
├── plan.md                  # master plan (read first)
├── knowledge/               # this research base — the app's content source
├── app/                     # Flutter project
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/  (dashboard, workout, progress, nutrition, learn, kegel, settings, login)
│   │   ├── data/program.dart    # generated from knowledge/01–03 — single source of truth
│   │   ├── services/api.dart    # dio client, cookie session, offline queue
│   │   └── state/               # riverpod providers
│   └── assets/gifs/         # bundled offline exercise animations
├── server/
│   ├── src/ (index.js, auth.js, routes.js, db.js)
│   ├── schema.sql
│   ├── web/                 # flutter build web output (rsynced in)
│   ├── downloads/ironforge.apk
│   ├── media/               # GIF mirror for web build
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── .env                 # chmod 600, NEVER in git
├── deploy/
│   ├── deploy.sh            # rsync + remote compose up
│   ├── harden.sh            # ufw, ssh check, unattended-upgrades, backup cron
│   └── fetch-media.sh       # downloads + verifies GIF assets
└── backups/                 # weekly rsync target from server
```

## Media (inbuilt exercise graphics)

**Primary — offline animated GIFs:** bundle from open-source datasets:
- `github.com/hasaneyldrm/exercises-dataset` — 1,324 exercises, GIFs + instructions, CC-BY-SA
- `github.com/omercotkd/exercises-gifs` — GIF mirror/backup host
- Fetch script: `deploy/fetch-media.sh` downloads only the 36 needed keys (list in
  knowledge/03), runs `file` type check + size sanity, strips metadata, copies to
  `app/assets/gifs/` + `server/media/`.
- Attribution: CC-BY-SA requires credit — the app's Learn tab gets an "Exercise media:
  community open datasets (CC-BY-SA)" line. Bundling in a personal-use app is fine.

**Secondary — embedded pro videos (need internet):** YouTube IDs per exercise in knowledge/02–03
(Jeff Nippard / Alan Thrall). Fallback if removed: in-app search link.

## Android signing (Phase 5)
```bash
keytool -genkey -v -keystore ~/ironforge-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
# android/key.properties: storePassword/keyPassword/keyAlias/storeFile — GITIGNORED
# build: flutter build apk --release --split-per-abi
```
BACK UP the .jks + passwords to your password manager immediately. Losing it = can never update the installed app.

## API contract
```
POST /api/auth/login     {username, password, totp?} → session cookie (rate-limited)
POST /api/auth/logout
GET  /api/me             → profile + program week
GET  /api/state          → full data dump (client cache refresh)
PUT  /api/state          → merge client state (offline queue flush)
POST /api/logs/workout   {date, week, day, exercise, sets:[{kg, reps}], notes}
POST /api/logs/weight    {date, kg}
POST /api/logs/measurements {date, waistCm, chestCm, armCm}
POST /api/logs/kegels    {date, sets, holdSeconds}
GET  /api/download/apk   → signed APK stream (auth required)
GET  /api/health         → {"ok":true} (only unauthenticated route)
```

## SQLite schema (`server/schema.sql`)
```sql
CREATE TABLE users (id INTEGER PRIMARY KEY, username TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL, totp_secret TEXT, created_at TEXT DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE sessions (id TEXT PRIMARY KEY, user_id INTEGER NOT NULL REFERENCES users(id),
  expires_at TEXT NOT NULL, created_at TEXT DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE workout_logs (id INTEGER PRIMARY KEY, user_id INTEGER NOT NULL,
  date TEXT NOT NULL, week INTEGER, day TEXT, exercise TEXT,
  set_number INTEGER, weight_kg REAL, reps INTEGER, notes TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE body_weight (id INTEGER PRIMARY KEY, user_id INTEGER NOT NULL,
  date TEXT NOT NULL, kg REAL NOT NULL, UNIQUE(user_id, date));
CREATE TABLE measurements (id INTEGER PRIMARY KEY, user_id INTEGER NOT NULL,
  date TEXT NOT NULL, waist_cm REAL, chest_cm REAL, arm_cm REAL, UNIQUE(user_id, date));
CREATE TABLE kegel_logs (id INTEGER PRIMARY KEY, user_id INTEGER NOT NULL,
  date TEXT NOT NULL, sets INTEGER, hold_seconds INTEGER, created_at TEXT DEFAULT CURRENT_TIMESTAMP);
CREATE INDEX idx_logs_user_date ON workout_logs(user_id, date);
```

## Deploy script (deploy/deploy.sh) — exact steps
```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$PATH:/home/mjonir/downloads/dev/flutter/bin"

# 1. build
(cd app && flutter build web --release)
(cd app && flutter build apk --release --split-per-abi)

# 2. sync to server
rsync -avz --delete --exclude .env server/ yarmuk:~/ironforge/server/
rsync -avz --delete app/build/web/ yarmuk:~/ironforge/server/web/
rsync -avz app/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk \
  yarmuk:~/ironforge/server/downloads/ironforge.apk
rsync -avz app/assets/gifs/ yarmuk:~/ironforge/server/media/

# 3. restart
ssh yarmuk 'cd ~/ironforge/server && docker compose up -d --build'

# 4. verify
ssh yarmuk 'curl -sf localhost:8420/api/health' | grep -q '"ok":true' \
  && echo "DEPLOY OK" || { echo "DEPLOY FAILED"; exit 1; }
```
First deploy additionally: `ssh yarmuk 'mkdir -p ~/ironforge'` and create `.env` interactively
(username + password + session secret), chmod 600. Password is typed by YOU directly on the
server, never stored in this repo.

## Deployment record (2026-09-05 — live)

- Container `ironforge` runs on yarmuk via docker compose (127.0.0.1:8420, healthy, mem 512m cap,
  read-only fs, non-root uid 10001). Existing containers untouched (verified: osrm, nakama,
  sih_collab, autoboard all still Up).
- Verified live on the server: login `{"ok":true}`, APK download 200 (21,929,355 B, auth-gated —
  401 without session), media GIF 200, web index 200, health ok.
- APK on server: `~/ironforge/server/downloads/ironforge.apk` (arm64-v8a, 21.9 MB).
- First-run provisioning: `deploy/deploy.sh` generates SESSION_SECRET + bootstrap credentials
  into `~/ironforge/server/.env` (chmod 600). After first login, change password in the app and
  delete `BOOTSTRAP_PASSWORD` from .env (done automatically by rotation).
- **Lesson 1 — CSP:** Flutter web (canvaskit/skwasm renderer) fetches engine assets from
  `https://www.gstatic.com` even when canvaskit is bundled locally (browser-variant fallback).
  CSP must allow: script-src gstatic + 'wasm-unsafe-eval', connect-src gstatic + fonts.gstatic,
  font-src fonts.gstatic, img-src https:. Locked-down equivalent is in server/src/index.js.
- **Lesson 2 — API contract:** `/api/state` returns workouts GROUPED with a `sets[]` array
  (client contract). Earlier flat per-set rows silently zeroed PRs/volume in the app. Smoke test
  asserts the grouped shape.
- **Lesson 3 — resource contention:** parallel flutter builds + gradle daemon + browser can hang
  dart2js on this machine (16 cores, but WSL I/O); run builds alone.

## Release 2 (2026-09-06) — coach, discipline, edit/delete

- **API additions:** `DELETE /api/logs/workout {date, exercise?}`, `DELETE /api/logs/weight {date}`,
  `DELETE /api/logs/measurements {date}`, `PUT|DELETE /api/logs/kegels {id,...}`, `POST|DELETE /api/checkins`,
  `GET|POST|DELETE /api/ai/chat`. `/api/state` returns checkins + kegel ids. `/api/me` returns full settings map.
- **AI coach:** server-side context builder (workouts, weight trend, kegels, check-ins, 3-week attendance,
  PRs, program week) + OpenRouter proxy. Env: `OPENROUTER_API_KEY`, `OPENROUTER_MODEL`
  (default `minimax/minimax-m3:free`), `AI_SEARCH=0/1` (tries `:online` search first, falls back).
  Rate limit 8/min/user, 800-char messages, history in `chat_messages` table. Key lives ONLY in server .env.
- **Notifications (Android):** flutter_local_notifications v22 + timezone + flutter_timezone; daily
  wake-up/gym/kegel reminders from Settings. Required Gradle change: core library desugaring
  (`isCoreLibraryDesugaringEnabled = true` + `desugar_jdk_libs:2.1.4`), manifest POST_NOTIFICATIONS +
  RECEIVE_BOOT_COMPLETED + the two ScheduledNotification receivers.
- **Lesson (Flutter web cache):** service worker + HTTP cache can serve a stale bundle after redeploys;
  hard-refresh twice (or purge caches in devtools) to see new builds.
- **Prod password note:** never assume the initial password still works — the user changes it from
  Settings; verify with a throwaway user (`ifverify`, insert hash via env var, delete after) instead.

## Cloudflare Tunnel wiring (your part, Phase 7)
1. Zero Trust → Networks → Tunnels → (your tunnel) → Public Hostnames → Add:
   - Subdomain: `gym` · Domain: `abba-s.dev` · Service: `http` `localhost:8420`
   - Full hostname: **`gym.abba-s.dev`**
2. Access → Applications → Add `gym.abba-s.dev` → policy: Allow, your email only.
3. Test from phone on mobile data: gate page → OTP → app login → dashboard.

## Cost & maintenance
- Everything is free/open-source. Server load: <100 MB RAM (SQLite + Node) — yarmuk won't notice.
- Update cycle: edit → `./deploy/deploy.sh` → 2–3 min. DB untouched by redeploys (volume).

# 12 — Tech stack, API and deployment boundaries

This describes the **current source**, not a verified live server. A September 2026 historical deployment report described a running host and APK; it does not establish the current production state. After the audit, the owner explicitly authorized a 30 September 2026 **web/server-only** deploy (`deploy/deploy.sh --no-apk`), verified as described in `renovation.md`. The APK and host-hardening changes were **not** deployed. Review `deploy/README.md` and obtain explicit authorization before further deployments or host-hardening operations.

## Components

- `app/`: one Flutter client for Android and web, using Dio for API calls, `shared_preferences` for a per-device cached snapshot/pending mutation queue, and local Android notifications. Web cold-start without network is **not** supported; an already open authenticated client can retain queued writes during API outage. An offline browser cache is not a database backup.
- `server/`: Node.js, Fastify, Argon2id and better-sqlite3. `server/schema.sql` is the authoritative schema. SQLite and its WAL/SHM reside in Docker's persistent named volume mounted at `/data`. Credential/session and workout data must not be tracked in Git.
- `server/web/`: copied local `flutter build web --release` output; this is a build artifact, not evidence of a published version. The web app is served by the Fastify origin at port 8420. `server/downloads/ironforge.apk` is managed independently from broad rsync.
- `knowledge/11-security-architecture.md`: security boundaries and the limits of local verification. Cloudflare Access is an **external** configuration, not automatically enabled by the application.

## API contract (as implemented in `server/src/routes.js`)

All routes except `/api/health` and login require a valid session unless the route explicitly handles authentication itself. Login is username/password only, with an HttpOnly Secure cookie; there is no current TOTP flow.

| Endpoint | Purpose |
|---|---|
| `POST /api/auth/login`, `POST /api/auth/logout`, `POST /api/auth/password` | Session and password management |
| `GET /api/me` | Username, units, saved program start and settings map (**not** computed program week) |
| `GET /api/state` | Full grouped workouts, body weights, measurements, pelvic-floor sessions (real IDs), check-ins; **no** `PUT /api/state` merge route |
| `POST`/`DELETE /api/logs/workout` | Save/replace or delete workout entry; POST `{date, week?, day?, exercise, sets:[{setNumber, weightKg, reps}], notes?}`. Replacing a workout removes omitted sets atomically. |
| `POST`/`DELETE /api/logs/weight` | `{date, kg}` or `{date}` |
| `POST`/`DELETE /api/logs/measurements` | `{date, waistCm?, chestCm?, armCm?}` or `{date}` |
| `POST`/`PUT`/`DELETE /api/logs/kegels` | Create `{date, sets, holdSeconds, clientId?}` returning `{ok:true,id}`, edit `{id,sets,holdSeconds}`, delete `{id}`. Stable `clientId` makes retries idempotent per user. |
| `POST /api/settings` | `{key,value}` for supported validated settings (see source). No interactive lb mode in the UI. |
| `POST`/`DELETE /api/checkins` | Dated check-ins |
| `GET`/`POST`/`DELETE /api/ai/chat` | Recent messages, optional external-provider question, clear history. Requires separate server key for POST. |
| `GET /api/download/apk`, `GET /api/health` | Authenticated download (only if an artifact is installed), unauthenticated health check |

Individual client writes are queued and retried; there is **no** whole-state upload/merge endpoint or general multi-device revision/conflict protocol. Look at the route schemas for exact numeric/date bounds and the latest response shape; do not infer APIs from older examples. SQLite `users` stores `password_hash`; there is no `totp_secret`. `kegel_requests` persists idempotency keys, and `chat_messages` records AI exchanges when enabled.

## Local verification and release prerequisites

```sh
cd app && flutter analyze && flutter test
cd app && flutter build web --release && flutter build apk --release
cd server && LOAD_LOCAL_ENV=0 npm test && LOAD_LOCAL_ENV=0 npm run smoke && npm audit --omit=dev
```

Run smoke/tests only with isolated temporary data and the local-env loader disabled; **never** run an extended script against production or a configured paid AI provider. The release APK currently uses Android's **debug signing key** (`app/android/app/build.gradle.kts`), even if `flutter build apk --release` succeeds. Set up and back up a durable private release keystore before distribution; do not ship or replace an installed package based on this build. External hardware/permissions, Android alarm delivery, UI screenshots, live Access, public cache behavior and release installation are not verified by these local commands.

`deploy/deploy.sh` and `deploy/harden.sh` change a remote host; **do not run them for tests**. Deploy preflights SSH/Docker/rsync/Flutter and excludes local secrets/data from synchronization; provisioning requires explicit action. `--no-apk` leaves the remote download alone. The hardened backup job writes verified SQLite snapshots to `/data/backups` within the named Docker volume, with same-volume retention; it does not automatically create an off-host backup. Check cron, container permissions and a disposable restore before relying on it. Never claim a production recovery time without a restore drill.

For full current provisioning, backup and permission notes, read `deploy/README.md`. Historical host paths/usernames in prior planning notes were environment-specific; do not blindly reuse them on this machine or point rsync at a live server without authorization.

# IRONFORGE

Personal training system: a Flutter app + Fastify server that run a beginner strength/stamina program (Delhi, UFC-style gym, start date 21 Sep 2026), with nutrition and form-verification knowledge baked in.

## Layout

| Path | Contents |
|------|----------|
| `knowledge/` | The source of truth — 12 documents: training program, push/legs + pull/core exercise libraries, form verification, nutrition, kegels, mobility/posture, progress timeline, risks/safety, security architecture, tech stack & deployment |
| `plan.md` | Execution plan (user context, trainer split, phases) |
| `renovation.md` | Renovation / rework log |
| `app/` | Flutter client (`ironforge`) — screens, state, services, theme |
| `server/` | `ironforge-server` — Fastify + better-sqlite3 + argon2, `src/`, `data/` (diet DB), `media/`, `test/` |
| `deploy/` | `deploy.sh`, `fetch-media.sh`, `harden.sh` |

## Running

```bash
# server
cd server && npm install && npm start          # smoke tests: npm run smoke

# app
cd app && flutter pub get && flutter run
```

## Not committed

- `app/build/`, `app/.dart_tool/`, `server/node_modules/` — regenerable; `flutter pub get` / `npm install` recreate them.
- `server/.env.example` **is** committed; a real `server/.env` is not.

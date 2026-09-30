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
cd server && npm install && npm start          # in another shell: npm run smoke

# app
cd app && flutter pub get && flutter run
```

## Not committed

- `app/build/`, `app/.dart_tool/`, `server/node_modules/` — regenerable; `flutter pub get` / `npm install` recreate them.
- `server/.env.example` **is** committed; a real `server/.env` is not.

The Android build requests Notifications and optional Alarms & reminders access for the 06:30 wake-up. Android can still delay or silence reminders; this is not a guaranteed alarm clock. Release APKs also need a real signing keystore before distribution.

### Local IronCoach key

Put the OpenRouter key only in:

```text
server/.env
```

The file is Git-ignored and should be mode `600`. Use:

```dotenv
OPENROUTER_API_KEY=your-key-here
OPENROUTER_MODEL=nvidia/nemotron-3-super-120b-a12b:free
AI_SEARCH=0
```

The server loads this local file at startup. Never put the key in Flutter code,
`--dart-define`, `API_BASE`, `server/web`, a screenshot or chat message. Set
provider spending/rate limits, and restart the server after changing the file.
IronCoach accepts only model IDs ending in `:free`. It falls back to the
verified `nvidia/nemotron-3-ultra-550b-a55b:free` if the primary provider
fails. `AI_SEARCH=1` is ignored because an online-search variant is not
verified as free. Free-model availability and daily/provider limits can change.

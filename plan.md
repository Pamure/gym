# IRONFORGE — Your 3-Month Gym Transformation System
**Master Plan** · Read this top to bottom once, then follow the phases.

> **What this is:** A complete system — a Flutter app (Android APK + website) that holds your
> personal 3-month science-based gym plan, tracks every workout, teaches you perfect form with
> built-in video/animation demos, and syncs your data to your own private server (`yarmuk`)
> that nobody else can access. This document is the single source of truth. Anyone (including
> future-you, or another AI) can pick this up and build/deploy the whole thing.

---

## 1. Your Profile (what the plan is built for)

| Fact | Value |
|---|---|
| Age | 18–22 |
| Height | under 5'7" |
| Weight | 68 kg |
| Experience | Complete beginner (~5–10 push-ups) |
| Gym | Okhla Vihar, Delhi — **closed Sundays** |
| Schedule | Mon–Fri training, 60 min/session, Sat active recovery, Sun rest |
| Diet | Non-vegetarian (chicken/eggs/fish OK) |
| Injuries | None — completely healthy |
| Goals | Full-body muscle, strength, stamina, aesthetics, posture, flexibility, lose love handles, kegels |

**Design consequences:**
- Beginner → form-first program, neurological gains come before visible muscle (weeks 1–4).
- 5 days available → Upper/Lower/Pull/Core/Full-Body split (better than full-body 5×/week for a beginner at 60 min/session).
- Love handles → slight calorie control + protein emphasis + training (spot reduction is a myth; the knowledge base explains).
- Posture concern ("don't want to look weird") → program has **balanced 1:1 push/pull volume**, face pulls every week, rear-delt and upper-back work, plus mobility day.
- No injuries → full compound lifts are safe to learn, but with the strict progression rules in `knowledge/08-risks-safety.md`.

---

## 2. The 3-Month Program (at a glance)

Full details, every exercise, sets/reps/cues/mistakes/videos: **`knowledge/01-training-program.md`**
and **`knowledge/02-exercise-library-push-legs.md`** + **`knowledge/03-exercise-library-pull-core.md`**.

| Month | Phase | Intensity (RIR) | Goal |
|---|---|---|---|
| 1 (Wk 1–4) | **Foundation** | 3 RIR | Learn perfect form, light weights, build habit |
| 2 (Wk 5–8) | **Development** | 2 RIR | Progressive overload, first visible changes |
| 3 (Wk 9–12) | **Push** | 1 RIR | Heaviest weights, maximum growth stimulus |

Weekly split (gym closed Sunday):

| Day | Session | Time |
|---|---|---|
| Mon | Upper Push (chest, shoulders, triceps) | ~60 min |
| Tue | Lower Body (quads, hamstrings, glutes, calves) | ~60 min |
| Wed | Pull / Back (deadlift, rows, lats, biceps, rear delts) | ~60 min |
| Thu | Core + Mobility + Kegels | ~45 min |
| Fri | Full-Body Compounds + Farmer's Walk | ~60 min |
| Sat | Active recovery (20 min light cardio + stretching + foam roll) | ~30 min |
| Sun | **REST** (gym closed) | — |

**Progression rule (double progression):** pick a weight you can lift for the bottom of the rep
range with perfect form → add reps each session until you hit the top of the range on all sets →
then add the smallest weight increment and drop back to the bottom. Never add weight if form breaks.

---

## 3. How You Will KNOW You're Doing It Right (your assurance system)

You're a beginner without a coach — so the system builds verification in. Full guide:
**`knowledge/04-form-verification.md`**. Summary:

1. **Watch the demo in the app before every exercise.** Each exercise has (a) an animated GIF
   bundled offline in the app showing the exact movement, and (b) an embedded pro video tutorial
   (Jeff Nippard / Alan Thrall — the most trusted science-based coaches).
2. **Film yourself.** Last set of each main lift, side view, phone on a tripod/water bottle.
   Compare against the checklist of form cues in the app (each exercise card shows them).
   Red flags = stop and lower the weight (list in knowledge/04).
3. **The 4 self-checks after every set:**
   - Did the muscle I'm targeting do the work (not momentum/my back)?
   - Was every rep identical in tempo and range?
   - Could I have done 1–3 more good reps? (= correct RIR)
   - Zero sharp/joint pain? (muscle burn = fine; sharp pain = stop)
4. **Weekly:** the app's progress charts should show weight or reps trending up. Flat for 2+ weeks → check sleep/food first (knowledge/08).
5. **Optional external check:** post a form video on r/formcheck, or book 1 trainer session at your gym to validate the big 3 (squat, bench, deadlift). Data checks: knowledge/08.

---

## 4. When You Will See Changes (realistic, science-based)

Full details: **`knowledge/08-progress-timeline.md`**

| When | What happens |
|---|---|
| Weeks 1–4 | Strength jumps fast (nervous system learning). Mirror: almost nothing yet. **Normal — don't quit.** |
| Weeks 5–8 | Slight definition, clothes fit differently, posture visibly better, energy up. |
| Weeks 8–12 | First clearly visible muscle changes. Expect ~1–2 lb muscle/month, 30–50% stronger on main lifts. |
| Continuous | Love handles shrink from diet + training, NOT ab exercises. Take progress photos every 4 weeks (same light/pose) — day-to-day mirror changes are invisible. |

---

## 5. Risks and How We Prevent Them

Full details: **`knowledge/09-risks-safety.md`**. The data: **55% of exercise injuries happen in the
first 3 months** — nearly all preventable. The program's built-in protections:

- **Form before weight** (ego lifting is the #1 injury cause) — app enforces "form check" prompts.
- **≤10% load increase per week** rule.
- **Warm-up protocol (RAMP)** before every session — in the app as a guided checklist.
- **Balanced programming** — 1:1 push/pull, face pulls, legs never skipped → no weird imbalances.
- **Overtraining watch** — resting heart rate, sleep, motivation signals; deload rules if they appear (knowledge/09).
- **Saturday = recovery**, Sunday = full rest. Non-negotiable.
- **Pain protocol:** sharp joint pain → stop that exercise, note it in the app, substitute.

---

## 6. The App System (what we're building)

```
┌─────────────────────┐         ┌──────────────────────────────────┐
│  ANDROID APK (you)  │         │  BROWSER (you) — Flutter Web     │
│  built-in GIFs +    │  HTTPS  │  same codebase                   │
│  video tutorials    ├────────►│                                  │
└─────────────────────┘         └──────────────┬───────────────────┘
                                               │
                    Cloudflare Zero Trust Tunnel (you set this up)
                    + Cloudflare Access (edge login gate)
                                               │
                              ┌────────────────▼─────────────────┐
                              │  yarmuk server (Ubuntu 24.04)    │
                              │  Docker container `ironforge`:   │
                              │   • Node.js + Fastify API        │
                              │   • Serves Flutter web build     │
                              │   • Serves APK download (auth)   │
                              │   • SQLite DB (all your data)    │
                              │   • binds 127.0.0.1:8420 ONLY    │
                              └──────────────────────────────────┘
```

**Why this architecture (boring = safe):**
- One Flutter codebase → Android APK + website. Mobile-responsive by default.
- Backend is one small Node.js app + SQLite file. No complex DB server to secure.
- **Zero inbound ports needed.** Cloudflare Tunnel makes an outbound connection only.
- Your data lives on YOUR server in ONE file (`/data/ironforge.db`) — easy to back up, easy to nuke.

### App screens
1. **Login** — single user (you), password-only, session cookie.
2. **Dashboard** — current week/phase ring, today's workout, streak, weight mini-chart, daily tip.
3. **Workout** — week selector → day tabs → exercise cards. Each card: bundled demo GIF, embedded
   pro video, form cues, common mistakes, set/rep logger (weight × reps per set).
4. **Progress** — bodyweight chart, measurements (waist/chest/arms), workout history, volume
   charts, personal records.
5. **Nutrition** — your Indian non-veg plan, protein tracker (110–140 g/day).
6. **Learn** — every gym term explained simply, warm-up/cool-down guides, kegel guide.
7. **Kegel timer** — guided hold/relax timer with daily logging.
8. **Settings** — export/import JSON, kg/lbs, program start date, change password.

### Exercise demos (inbuilt, as you asked)
- **Primary:** open-source animated exercise GIFs bundled into the app assets (offline-capable,
  no internet needed at the gym) — from the free exercise datasets researched in
  `knowledge/12-tech-stack-deployment.md` §Media.
- **Deep-dive:** embedded YouTube tutorials from verified coaches (needs internet).
- Each exercise also has a text form-cue checklist and a mistakes list, so even without any
  video you know exactly what right looks like.

---

## 7. Security Model (paramount — nobody but you gets in)

Full detail + copy-paste configs: **`knowledge/11-security-architecture.md`**. The layers:

1. **Edge gate (Cloudflare Access):** before anyone even SEES the app, Cloudflare requires your
   email OTP / Google login. Random internet scanners never reach your server. *(You configure
   this in your Zero Trust dashboard — steps in knowledge/11.)*
2. **No inbound ports:** the app container binds to `127.0.0.1:8420` only. Nothing is published
   to the network. Tunnel carries traffic.
3. **App auth:** single admin account, password hashed with **argon2id**, HttpOnly+Secure+
   SameSite=Strict session cookie, 16-byte random session IDs, login rate-limited to 5 attempts/min
   with exponential lockout. (TOTP was removed 2026-09-05 at user request — Cloudflare Access
   remains the mandatory second gate at the edge.)
4. **Container hardening:** non-root user inside container, read-only root filesystem, `no-new-privileges`,
   memory/CPU limits, only a `/data` volume writable.
5. **Server hardening:** SSH stays key-based only (password login disabled), UFW firewall denies
   all inbound except what's already needed, unattended security updates enabled.
6. **API hardening:** security headers (CSP, X-Frame-Options, nosniff), strict JSON schema
   validation on every input, parameterized SQL only (better-sqlite3 prepared statements), no eval.
7. **Secrets:** live only in `/home/gomango/ironforge/.env` with `chmod 600`, never in git.
8. **Backups:** nightly SQLite backup (cron), 14-day retention, weekly rsync copy to your PC.

**What you must NEVER do:** commit `.env`/keystore/tunnel tokens to git; share the tunnel URL
publicly; disable Access "for a quick test"; reuse your password elsewhere.

---

## 8. Build & Deploy Runbook (anyone can follow)

> **STATUS 2026-09-06 (release 2):** + AI coach (IronCoach on OpenRouter free model, reads all his
> server data), edit/delete for every log, daily check-ins, streak calendar, milestones, missed-day
> nudges, Android daily reminders, overflow/typography pass. Live on yarmuk, smoke 29/29.
>
> **STATUS 2026-09-05: Phases 1-6 DONE and verified.** Backend smoke 21/21, unit tests 5/5,
> web + APK built, deployed to yarmuk (Docker `ironforge`, 127.0.0.1:8420, healthy), login +
> APK download + media verified live on the server. Remaining = YOUR steps: Cloudflare tunnel
> route (Phase 7), harden.sh (Phase 8, needs sudo), first login + password change.

> Phase 0 is done (this research). Each later phase has acceptance criteria — don't move on until met.

### Phase 1 — Scaffold (local machine, `/home/mjonir/f/gym/`)
```bash
export PATH="$PATH:/home/mjonir/downloads/dev/flutter/bin"
cd /home/mjonir/f/gym
flutter create --org com.ironforge --project-name ironforge app
```
- Create folders: `app/` (Flutter), `server/` (Node.js), `deploy/` (scripts), `media/` (GIFs), `knowledge/` (done).
- ✅ `flutter doctor` shows no errors (already verified on this machine).

### Phase 2 — Backend (`server/`)
- Node 22 + Fastify + better-sqlite3. Files: `src/index.js`, `src/auth.js`, `src/routes.js`,
  `src/db.js`, `schema.sql`, `Dockerfile`, `docker-compose.yml`, `.env.example`.
- API (all behind auth except `/api/health`):
  - `POST /api/auth/login` (rate-limited, argon2id verify, optional TOTP)
  - `POST /api/auth/logout` · `GET /api/me`
  - `GET|PUT /api/state` (full-state sync) · `POST /api/logs/workout` · `POST /api/logs/weight`
  - `POST /api/logs/measurements` · `POST /api/logs/kegels`
  - `GET /api/download/apk` (streams the signed APK)
  - Static: serves `web/` (Flutter web build) and `media/`
- DB schema in `server/schema.sql`: `users, sessions, workout_logs, body_weight, measurements, kegel_logs, settings`.
- ✅ `npm test`-equivalent smoke: `curl localhost:8420/api/health` → `{"ok":true}`; login with wrong password fails; login with right password returns cookie; unauthenticated `/api/state` → 401.

### Phase 3 — Flutter app (`app/`)
- Packages: `flutter_riverpod`, `dio` (cookie-aware client), `shared_preferences` (local cache),
  `fl_chart` (progress charts), `youtube_player_iframe` (tutorials), `flutter_secure_storage` (session).
- All screens from §6.
- Program data is a Dart constant generated from `knowledge/01–03` (single source of truth).
- Offline-first: full local cache; syncs to backend when online.
- ✅ Runs on Android emulator + Chrome (`flutter run -d chrome`) with login → log workout → see chart.

### Phase 4 — Media pipeline (`media/`)
- Script `deploy/fetch-media.sh` downloads the ~35 needed exercise GIFs from the open dataset,
  verifies file types, strips metadata, copies into `app/assets/gifs/` and `server/media/`.
- ✅ Every exercise in the program has a local GIF + working YouTube ID (spot-check 5).

### Phase 5 — Build release artifacts
```bash
cd app
flutter build web --release                     # → build/web → copied to server/web
flutter build apk --release --split-per-abi     # signed APKs
```
- Android signing: generate `upload-keystore.jks` (see knowledge/12), `android/key.properties`,
  both **gitignored**. Back up the keystore to your password manager — lose it and you can never update the APK.
- ✅ APK installs on your phone; web build loads at localhost.

### Phase 6 — Deploy to yarmuk (`deploy/deploy.sh`)
```bash
# what the script does (rsync-based, no git needed on server):
rsync -avz --delete server/  yarmuk:~/ironforge/server/
rsync -avz --delete app/build/web/ yarmuk:~/ironforge/server/web/
rsync -avz app/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk \
  yarmuk:~/ironforge/server/downloads/ironforge.apk
ssh yarmuk 'cd ~/ironforge/server && docker compose up -d --build'
```
- Server folder: `/home/gomango/ironforge/` (separate from all existing projects).
- Port `127.0.0.1:8420` (verified free; nothing else uses it).
- ✅ `ssh yarmuk 'curl -s localhost:8420/api/health'` → `{"ok":true}` and `docker ps` shows
  existing containers (osrm, nakama, sih_collab, autoboard) untouched.

### Phase 7 — Cloudflare Tunnel (you do this part — you said you have it set up)
1. Zero Trust dashboard → Networks → Tunnels → your tunnel → add public hostname:
   `gym.<yourdomain>` → service `http://localhost:8420`.
2. Access → Applications → Add: protect `gym.<yourdomain>` with your email (OTP) as the only allowed identity.
3. ✅ From your phone browser (mobile data, not WiFi): `https://gym.<yourdomain>` → Cloudflare
   login gate → app login → dashboard loads. Incognito test: without Access auth you never see the app.
4. Download the APK from `https://gym.<yourdomain>` → Downloads → install on your Android phone.

### Phase 8 — Hardening & backups (final)
- Run `deploy/harden.sh` on yarmuk: enables UFW (allow 22 + existing 80 only), enables
  unattended-upgrades, sets up nightly DB backup cron.
- ✅ Restore test: copy a backup, open DB, data readable. Login lockout test: 6 wrong passwords → locked.

---

## 9. Daily Usage Loop (once deployed)

1. Open app → Dashboard shows today (e.g., "Tuesday — Lower Body, Week 3, Foundation").
2. Do the 5-min RAMP warm-up checklist in the app.
3. Each exercise: watch GIF → read 3 form cues → lift → log weight/reps per set.
4. End of session: app shows total volume, saves locally + syncs to server.
5. Thursday: guided kegel timer. Saturday: recovery checklist.
6. Every 4 weeks: progress photo + measurements entry.

---

## 10. Decided Inputs (collected 2026-09-05)

| Input | Value |
|---|---|
| Tunnel hostname | `gym.abba-s.dev` |
| Login username | `mjonir` (password typed directly on server at deploy — never written to any file) |
| 2FA | **None** — removed 2026-09-05 at user request (password only; Cloudflare Access stays the edge gate) |
| App name | **IronForge** |

All inputs collected — nothing blocks Phase 1+.

---

## 11. Knowledge Base Index (never research twice)

| File | Contents |
|---|---|
| `knowledge/01-training-program.md` | Full 12-week program, every day, sets/reps per month, progression rules, deload |
| `knowledge/02-exercise-library-push-legs.md` | Push + leg exercises: muscles, cues, mistakes, video IDs, GIF mapping |
| `knowledge/03-exercise-library-pull-core.md` | Pull + core + conditioning exercises, GIF asset key list |
| `knowledge/04-form-verification.md` | How to check your own form, filming guide, red flags, RIR explained |
| `knowledge/05-nutrition.md` | Protein targets, Indian non-veg meal plan, budget sources, hydration |
| `knowledge/06-kegels.md` | Complete kegel protocol for men, progression, mistakes |
| `knowledge/07-mobility-posture.md` | RAMP warm-up, posture correction plan, Saturday recovery routine |
| `knowledge/08-progress-timeline.md` | Newbie gains science, what changes when, how to track |
| `knowledge/09-risks-safety.md` | Injury stats, ego lifting, overtraining signs, pain protocol |
| `knowledge/10-glossary.md` | Every gym term in plain language (sets, reps, RIR, RPE, DOMS…) |
| `knowledge/11-security-architecture.md` | Full security design, Cloudflare setup steps, server hardening |
| `knowledge/12-tech-stack-deployment.md` | Flutter/backend/media/deployment technical decisions + commands |

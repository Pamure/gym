# IronForge audit and change log

**Workspace:** `/home/quilt/f/projects/gym`
**Repository:** `Pamure/gym`
**Date:** 20 September 2026
**Deployment/push:** initial audit was local only. On 30 September 2026 a later explicit user request authorized a web/server deployment; no Git push or APK upload was performed.

## User brief translated into product requirements

- A first-time lifter needs a clear “what do I do next?” flow, not six dense body-part screens.
- Each exercise must explain equipment identification, setup, form cues, mistakes, rest and an alternative.
- The same plan must be used by the workout screen, dashboard, reminders and IronCoach.
- Login should survive normal app use without an unnecessarily short session; explicit logout must stay explicit.
- Android should request notification/alarm permissions for a 06:30 wake-up, while honestly stating that Android/OEM settings can still delay or silence it.
- Web and Android should remain the same Flutter app; web does not have native push reminders.

## Findings and fixes completed in this pass

### P0 — build/data correctness

- **Fixed:** `app/lib/data/diet_database.dart` was Python syntax saved with a `.dart` extension, producing hundreds of analyzer errors. Replaced it with typed Dart food, search and budget-plan models. Prices and nutrition are explicitly approximate.
- **Fixed:** removed the zero-set `front-squat` month placeholder and moved the visible plan to three required full-body sessions with no zero-set cards.
- **Fixed:** repeated Save now replaces the local `(date, exercise)` log, matching the server upsert and preventing duplicate volume/history.
- **Fixed:** restored the persisted offline operation queue on startup.
- **Fixed:** invalid blank/zero-rep weight sets are rejected with a user-facing message.
- **Fixed:** most-recent exercise prefill now chooses the newest matching log instead of the oldest.

### P1 — beginner program and UX

- **Fixed:** canonical plan is Monday/Wednesday/Friday full-body strength; Tuesday/Thursday/Saturday are optional easy movement; Sunday is full rest.
- **Added:** `app/lib/data/exercise_guides.dart` with equipment, “find it”, setup, alternatives and self-checks for the main exercises.
- **Added:** expanded workout cards show a beginner flow, per-exercise rest, equipment notes and optional-activity completion.
- **Added:** Learn → Start here explains the weekly map, progression, coach-list migration and safety stop signals.
- **Updated:** nutrition copy no longer hardcodes an unsupported calorie/protein prescription for an unknown person.
- **Updated:** dashboard progress is `x / 3 strength sessions`, not the obsolete five/six-day target.
- **Removed:** punishment/extra-set language. Missed sessions are resumed, never punished.

### P1 — auth/session and sync

- **Fixed:** new accounts now persist the canonical start date locally immediately.
- **Fixed:** mobile logout clears the persisted cookie, cancels reminders, clears all local collections including check-ins, and writes a local logout tombstone so an offline logout cannot silently re-authenticate.
- **Fixed:** an API 401 during sync changes the app to logged-out instead of pretending that a server-expired session is offline.
- **Changed:** server session lifetime is 30 days (still HttpOnly, Secure and bounded); explicit logout/password change invalidates sessions.
- **Updated:** Settings describes the actual session and storage/reminder behavior.

### P1 — Android reminders

- **Fixed:** all old prep reminder IDs are cancelled; the old nested scheduling loop is gone.
- **Changed:** notifications align with required strength days and optional movement days, never Sunday.
- **Added:** exact-alarm permission request and manifest permission; fallback remains inexact when Android denies exact alarms.
- **Added:** cancellation on explicit logout.
- **Limitation:** no app can guarantee waking a powered-off phone, bypass Do Not Disturb, battery optimization or user notification settings. The app now says this clearly.

### P1 — web outlet

- **Updated locally:** rebuilt the Flutter web app and refreshed the tracked `server/web` bundle so the server's web route contains the same beginner plan and metadata as Android. This is an artifact update only, not a deployment.

### P1 — AI consistency

- **Updated:** `server/src/ai.js` uses the same canonical routine and 2026-09-21 → 2026-12-13 dates as the app. It no longer recommends punishment or claims an unverified 500-food database.
- **Safety:** AI is told not to invent health facts and to refer sharp/persistent symptoms to a qualified clinician.

## Research record

Sources reviewed for the program and platform behavior:

1. ACSM 2026 resistance-training position stand: https://pmc.ncbi.nlm.nih.gov/articles/PMC12965823/
2. Full-body vs split systematic review (2024): https://pubmed.ncbi.nlm.nih.gov/38595233/
3. Failure vs non-failure review: https://pmc.ncbi.nlm.nih.gov/articles/PMC9068575/
4. Rest intervals review (2024): https://www.frontiersin.org/journals/sports-and-active-living/articles/10.3389/fspor.2024.1429789/full
5. WHO activity guidance: https://www.who.int/publications/i/item/9789240015128
6. Android alarms: https://developer.android.com/develop/background-work/services/alarms
7. Android 14 exact alarms: https://developer.android.com/about/versions/14/changes/schedule-exact-alarms
8. Android notification permission: https://developer.android.com/develop/ui/compose/notifications/notification-permission

Research supports a range of effective routines. It does not establish a single perfect exercise list for every beginner; the app uses a conservative starting plan and same-pattern alternatives.

## Verification log

- `cd app && flutter analyze`: **passed — no issues found**.
- `cd app && flutter test`: **passed — 17 tests**.
- `cd app && flutter build web --release`: **passed**.
- `cd app && flutter build apk --debug`: **passed**; debug APK generated locally at `app/build/app/outputs/flutter-apk/app-debug.apk`.
- `cd server && npm run smoke`: **passed — 31 checks**, including malformed reminder/unit settings.
- `cd server && npm audit --omit=dev`: **0 vulnerabilities** after upgrading `@fastify/static`.
- `git diff --check`: **passed**.
- Debug APK and web artifacts were built locally for verification; no Android install, server deployment or GitHub push has been performed.

## Follow-up UI/error pass — 29 September 2026

- **Fixed:** inactive streak `RadialGradient` supplied two colors with three stops, which crashed Flutter web rendering. Active and inactive states now have matching color/stop lengths.
- **Changed theme:** replaced near-black/ember-orange with a calm navy + teal + coral palette. Text and primary accents were chosen with WCAG contrast guidance in mind; W3C recommends at least 4.5:1 for normal text. Source: https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html.
- **Fixed:** fresh web browsers no longer probe `/api/me` before the user has logged in, removing the expected noisy 401 during first load. Expired sessions still become logged out correctly.
- **Fixed:** YouTube sheets no longer instantiate the unreliable embedded player that showed Android error 152-4. Both web and Android now show a tappable thumbnail and open the official YouTube app/browser directly.
- **Improved:** AI 503/429 responses now become understandable in-app messages instead of raw Dio exceptions. Local workout/forms remain available when AI is not configured.
- **Improved:** notification details explicitly enable sound/vibration. Android manifest and runtime flow cover Internet, notifications, reboot rescheduling and optional exact-alarm access. No camera/location permission is requested because the app does not use those capabilities.
- **Added:** every strength exercise now has a real rest countdown beside its rest guidance. This is more useful on the gym floor than a static “90 seconds” label.
- **Fixed:** bundled Noto Color Emoji fallback for web/Android so workout-day icons and reminder emoji do not rely on a browser's missing-font set.
- **Critic correction:** Friday is now a distinct Full Body C (goblet squat, bench, row, leg curl, face pull, farmer walk) rather than repeating Monday A. Weekly movement coverage is more balanced while remaining three sessions.
- **Preview:** rebuilt web bundle and restarted a temporary local preview at `http://localhost:8420`; local demo credentials are intentionally not recorded in version control.

## Safe IronCoach key configuration — 30 September 2026

- Added `server/src/load-env.js`, which reads only the ignored local `server/.env` file and never overwrites an environment variable supplied by the shell/container.
- Added an empty `server/.env` placeholder with mode `600`; no secret was written. Git confirms it is ignored.
- Added `OPENROUTER_API_KEY`, `OPENROUTER_MODEL` and `AI_SEARCH` guidance to `server/.env.example` and `README.md`.
- The key remains server-side and is never included in Flutter, `server/web`, API responses or logs. Restart the server after editing the file.
- `npm run smoke` still passes all 31 checks after this change.
- Owner supplied a quoted key value; loader verification reported `configured=true` without printing its contents. Preview server restarted successfully at `http://localhost:8420`.

## Morning checklist for the owner

1. Run the tests below on the device/emulator and inspect the three required sessions.
2. Open Workout → expand an exercise → check the GIF, tutorial link, equipment note and alternative.
3. Enable reminders on Android; grant Notifications and, if desired, Alarms & reminders access. Test 06:30 with a temporary nearby time first.
4. Confirm the UFC gym coach demonstrates one light goblet squat, press, pulldown and hinge before loading weight.
5. Only after reviewing the diff and approving it should anyone build, deploy or push.

## Critic pass — screenshots, browser preview, product and plan

### What I inspected

- Supplied screenshots of Workout and IronCoach from `localhost:8420`.
- Refreshed local web bundle served by the preview server.
- Direct health, unauthenticated `/api/me`, demo login, authenticated state and YouTube thumbnail requests.
- Flutter analyzer/tests and Android/web release builds.
- A headless Brave attempt. Brave initialized Flutter/WebGL but did not exit or emit a screenshot in this environment, so I did not claim a clean automated visual pass. The supplied screenshots remain the visual evidence.

### Findings

1. **Critical rendering bug:** inactive streak glow had two colors and three stops. Fixed and covered by matching conditional lists.
2. **Visual hierarchy:** the prior near-black/orange design made secondary text and the gym-floor flow hard to scan. Replaced with navy surfaces, readable light text, teal primary actions and coral highlights. W3C contrast guidance is recorded above; key palette pairs exceed 4.5:1 by calculation.
3. **Video:** the supplied screenshots showed Android YouTube error 152-4. The player package was removed; both platforms now use a tappable thumbnail plus a prominent external YouTube action.
4. **Auth console noise:** a fresh browser used to call `/api/me` and show an expected 401 before login. New browsers now go directly to login; a real expired session still logs out safely.
5. **AI:** the local server has no `OPENROUTER_API_KEY`, so AI chat cannot work in the preview. This is now a clear in-app explanation rather than a raw 503 exception. The workout, form library and logging do not depend on AI.
6. **Plan:** the original six-day split was too complex for this beginner block. The revised 3-day plan is appropriate as a simple starting point, but it requires an in-person coach to check the first squat/hinge/press. Friday is now distinct Full Body C to avoid repeating one session pattern every week.
7. **What I deliberately did not add:** an “angry” coach or punishment system. Guilt and forced extra sets are poor coaching; the app uses calm, concrete next actions. Custom reminder times already exist, and native Android permission behavior still needs physical-device verification.
8. **Remaining usability opportunity:** a future “Gym floor mode” should show one exercise at a time with larger controls and hide the 12-week/day selector clutter. It is not claimed as shipped in this pass.

### Browser/API checks from the refreshed preview

- `/api/health` → `200 {"ok":true}`
- Fresh unauthenticated `/api/me` → `401 {"error":"unauthenticated"}` by design; no longer called on a brand-new local browser before the login screen.
- Demo login → `200`
- Authenticated `/api/state` → empty valid state
- YouTube thumbnail → `200`
- Preview index → `Cache-Control: no-store`

## Follow-up not silently claimed as complete

- Real-device Android alarm behavior across OEMs needs a physical-device test.
- The nutrition catalog is an offline planning aid, not 500 verified entries or a personalized meal prescription.
- Web has no native push reminder; an explicit in-app banner can be added if desired.
- Release signing still needs a real keystore before distribution.
- There is no automated browser/device screenshot test in this environment.

## 30 September 2026 — response to `pleasereadthis.md`

This is a local source/build/test pass, **not** a deployment, live-production audit, or Android-device/browser verification. The earlier note above about an *empty* `server/.env` describes the initial setup; the owner later populated an ignored, mode-600 local key. This pass did not read, copy, print, or send that key. All server tests ran with `LOAD_LOCAL_ENV=0` against disposable databases; no production data was touched.

### High-risk findings resolved

- **F01/F02/F07:** one API error path now rejects non-2xx responses for all reads and writes. Rejected client writes roll back; retryable failures stay queued. Mutation intent is persisted before any HTTP request, queued uploads are reconciled before a state pull, each acknowledgement is persisted, and Settings Sync now reports remaining pending changes rather than an unconditional success. Added transport-backed Flutter tests for a pending older weight across restart, a newer save, an in-flight save replay after simulated restart, a stale refresh racing a save, 400/401 rejection, and no loss on logout.
- **F03/F10:** each new pelvic-floor session has a distinct temporary client ID and server-assigned real ID. Server idempotency is persisted and user-scoped, so replay after a lost response does not create a second session; deletes reconcile with real or pending IDs. Multiple same-day sessions remain possible.
- **F04:** logout attempts to sync first; if writes remain, it refuses by default and the Settings UI requires an explicit warning and confirmation before intentionally discarding the only local copy. The UI no longer claims an offline write already exists on the server.
- **F05:** ignored runtime bootstrap JSON, SQLite DB/WAL/SHM, and downloadable APK were removed **from Git's index only**; local files were retained. `.gitignore` and `.dockerignore` now exclude them. This does **not** erase any already-published Git history; investigate exposure and rotate credentials/session material through a separately authorized procedure before any future publish.
- **F06:** backup now awaits the SQLite snapshot, validates the backup can reopen, writes to a mounted persistent location with retention applied to that same location, and does not create an empty source. Deploy/hardening scripts now check prerequisites, isolate temporary credentials, and protect the download artifact. Local isolated backup/restore and static script tests pass; cron/container recovery on the real host has **not** been verified.

### Other audit fixes

- **F08/F09:** server workout replacement is atomic, including deletion of omitted sets; the state endpoint returns complete check-in/kegel history instead of silent 60/90-row truncation.
- **F11/F12/F13:** cached reminder choices survive offline restarts; logged-out startup cannot reschedule, same-process login reapplies settings, and exact-alarm permission does not repeatedly prompt on startup. The gym schedule excludes Sunday, while daily wake/recovery nudges honestly say they can still run Sunday. Local JSON export includes check-ins, settings and a pending-operation count (not replayable commands), and is clearly labelled as **not** a full server backup (chat history is not included).
- **F14–F17/F19/F20/F22:** completed strength sessions require at least three distinct planned loaded lifts rather than one logged activity, optional days do not penalize required-session streaks, heatmap scores actual categories, optional cardio shows the program's target duration, all programmed floor moves have guidance, unsafe movement-pattern substitutions were corrected, chart week labels and week-preview-vs-save identity are corrected. Timed carries are excluded from kg×reps volume and labelled in seconds in history.
- **F21/F23:** the logbook now describes only its actual edit/delete affordances. Weight/measurement inputs still use kg/cm; `lb` remains an incomplete legacy API preference, **not** a supported UI unit mode.
- **F24–F29/F32/F33/F35:** CSP permits the web tutorial thumbnail fetch; coach HTTP errors are classified by status; the AI prompt uses saved plan dates and local Delhi dates, omits pre-enrolment/today/post-program false missed sessions, and has a bounded total deadline. External AI data transfer is disclosed in login/coach copy; selected-state text contrast and some icon/field/heatmap accessibility labels were corrected. Entry scripts have non-stale cache headers.
- **F36/F37/F39/F40/F41/F42/F43:** deploy now excludes the APK from broad rsync and securely serializes temporary bootstrap credentials; docs were revised to distinguish implemented auth/backups from unverified Cloudflare/host claims and correct API shapes. Literal-only Flutter tests were replaced with behavioral tests; the isolated server suite checks persistence/validation/security boundaries without calling an AI provider. Empty mini-heatbar scaffolding was removed.
- **Extra validation:** impossible dates, zero-rep sets, arbitrary reminder flags/times and unknown JSON fields are rejected by the server. `npm update fast-uri` updated vulnerable transitive package versions within their compatible major lines, with no dependencies requiring a major-version override.

### Explicitly deferred / not proven

- **F18 (partial):** carry seconds and volume labels are corrected, but guided pelvic-floor repetitions still share the legacy `sets` database field with older set-based records. UI calls the old count “recorded holds/sets”; a schema migration plus per-set/repetition timer model would be required to preserve exact semantics. Floor moves marked done still use synthetic completion sets, not measured time/reps.
- **F23:** displaying and converting a true lb preference consistently needs a full input/chart/history migration; the user-facing app remains kg/cm.
- **F30/F31:** nutrition remains static; the typed search/budget helpers are not an interactive screen and are not typo-tolerant. Detailed health/nutrition/sexual-health copy needs a separate expert content reconciliation; do not treat price, protein, pelvic-floor outcomes or hydration targets as personalized advice.
- **F34:** an already open web app can queue changes during API failure, but a fully offline browser cold reload remains unsupported (service worker unregisters itself). Native Android assets bundle with the APK; Android offline/notification behavior has not been tested on physical hardware.
- **F42:** the legacy `server/test/extended.sh` is still unsafe to run on a real server or configured AI provider; it was not executed. Use the new isolated regression tests and smoke fixture instead.
- **F38:** release APKs still use the debug signing config; configure a durable private release keystore before distribution. A successful local build is not release-signing readiness.
- Multi-device concurrent edits have no server revision/conflict-resolution protocol. Offline writes must remain on the same device until synced; clearing browser storage can lose them. The settings export is not a SQLite restore image. Historical Git exposure, Android alarms, live backups, external AI responses, cloud access rules and visual browser/device regression were not verified by these tests.

### Verification for this pass

- Flutter transport/behavior tests use an in-memory HTTP adapter and mocked preferences; no external network or DB. Flutter `analyze` and tests: **18 passed, zero analyzer issues** after the final UI edits.
- Server `LOAD_LOCAL_ENV=0 npm test`: **16 passed**, covering backup/restore, atomic replacement, idempotency, validation, authentication and AI program-date context. `LOAD_LOCAL_ENV=0 npm run smoke`: **31 checks passed**, isolated data only.
- `npm audit --omit=dev`: **0 vulnerabilities** after compatible `fast-uri` lockfile updates. `bash -n deploy/deploy.sh deploy/harden.sh` and `git diff --check`: passed; deployment and hardening scripts were **not run**.
- `flutter build web --release`: passed; updated `server/web` bundle locally during this audit pass. `flutter build apk --release`: passed locally; **debug-signed**, not distribution-ready. Build warnings noted: Flutter's future Kotlin Gradle Plugin compatibility warning for `flutter_timezone`, Android SDK XML tool-version mismatch, and 19 newer pub packages outside current constraints. No install or push during the audit pass.

## Authorized deployment — 30 September 2026 (after the audit pass)

The owner then explicitly requested running the deploy script. Preflight confirmed local Flutter/rsync, remote SSH/rsync/Docker Compose and an existing remote `.env`. Both rsync dry runs reported **no deletions**. Ran `./deploy/deploy.sh --no-apk` once: Flutter web build passed, server/web files synchronized, Docker rebuilt/recreated the application container, and the script reported **DEPLOY OK**. `--provision` and `deploy/harden.sh` were **not** run; local secrets and runtime database files were excluded from rsync. The remote APK was deliberately not replaced because release builds still use a debug signing key. No Git push occurred.

Post-deploy read-only checks on the remote host: container `running`, `/data` mounted as a Docker `volume`, remote `.env` mode `600`, `/api/health` returned `200 {"ok":true}`, unauthenticated `/api/state` returned `401`, `/main.dart.js` returned `Cache-Control: no-store`, and the deployed `main.dart.js` SHA-256 matched the just-built local web artifact. These checks do **not** verify login, real user data migration, AI provider responses, live backup restoration, public Cloudflare Access behavior, or physical-device Android functionality. Do not treat the debug-signed local APK as distribution-ready.

## Free-only IronCoach repair and fresh web/server deploy — 30 September 2026

With explicit owner authorization, checked OpenRouter's public model list and ran a small number of **`:free`-only** requests using the key already injected in the remote container. The key was never printed, copied, or sent to Flutter. The old remote override `minimax/minimax-m3:free` was no longer listed. Qwen3.8-27B and Gemma 4 26B returned 429; Lightning timed out; some other free variants returned empty/provider errors. `nvidia/nemotron-3-super-120b-a12b:free` returned short, appropriate safety answers in roughly 3–5 seconds, including a synthetic beginner-gym scenario. `nvidia/nemotron-3-ultra-550b-a55b:free` also answered in roughly 10 seconds. OpenRouter key diagnostics reported available free daily quota; current provider capacity remains variable.

Updated `server/src/ai.js` to choose verified Super first and Ultra as fallback, silently migrate **only** the retired Minimax override without editing the secret-bearing remote `.env`, refuse any model ID not ending in `:free`, and ignore `AI_SEARCH` because an online suffix has not been established as free. `server/.env.example` and `README.md` explain this. `LOAD_LOCAL_ENV=0 npm test` **17/17**, isolated smoke **31 checks**, `npm audit --omit=dev` **0 vulnerabilities**, and `git diff --check` passed.

Ran `./deploy/deploy.sh --no-apk` again after a dry run showed no deletions. Script reported **DEPLOY OK**; container is running, `/api/health` returned `200`, unauthenticated `/api/state` returned `401`, script cache headers remained `no-store`, and the running AI source SHA-256 matched the new local source. Public site GET returned HTTP `200`; deployed web JS matched the freshly built output. The remote environment key remained configured without being exposed. Finally, inside the fresh container, an authenticated Fastify `POST /api/ai/chat` using a **disposable `/tmp` database, synthetic user and synthetic question** returned HTTP `200` with a nonempty, relevant answer from `nvidia/nemotron-3-super-120b-a12b:free` in about 5 seconds. The temporary test database was deleted. No real account, personal history, production database, release APK, host hardening, Git push or paid/untagged model was used. Free-tier limits/provider availability can still change; actual phone/browser login was not exercised.

## Coach-plan and responsive UI pass — local only

I inspected the supplied WhatsApp screenshots in the project root. They confirmed the reported problems: Save was clipped in a narrow workout card, dense side-by-side rows pushed actions off-screen, large horizontal selectors hid context, and Android YouTube showed error 152-4. The settings screenshot also showed a tall native time picker; that is platform UI rather than app copy.

- Added a runtime **Gym trainer plan** based on the supplied six-day UFC Okhla list, preserving the trainer's original labels and written targets. The Workout screen defaults to this plan and offers a clearly labelled **Starter guidance** switch for the conservative three-day IronForge plan.
- Added catalog entries and equipment/alternative guidance for the missing movements: decline bench, dumbbell fly, chest press machine, pec deck, front/reverse raise, shrugs, seated cable row, close-grip pull, back extension, barbell/cable/preacher/hammer curls, triceps extensions/skull crushers, leg extension and other aliases.
- Unclear trainer names are visibly marked **ASK TRAINER**: “Revers” is marked likely reverse fly, “Seated”, “Close grip” and “One-arm machine” require confirmation, and “Roughf nd toughf” remains a clarification placeholder. “Behind lat pull” is not implemented literally; it uses a front-of-neck pulldown and is marked **SAFER REPLACEMENT**. The app offers mainstream dumbbell, bodyweight, cable or simpler alternatives in every relevant guide.
- Coach targets such as 4 × 12 remain visible, but the first-month app dose starts at one set and builds only when technique/recovery are good. This keeps the trainer plan recognizable without telling a new lifter to complete the full written volume immediately.
- Redesigned the Workout header with a compact plan toggle plus dropdowns for week/day instead of two long chip strips. Primary logging actions are full-width and stacked; tutorial/media, rest controls and coach notes wrap safely on narrow phones. Dashboard quick actions, Learn weekly rows, kegel actions and small-screen navigation now adapt instead of forcing long rows.
- Removed the global emoji font fallback that could make normal body text render with abnormal spacing. The app remains on the platform sans-serif for normal copy.
- Removed `youtube_player_iframe`; the video sheet is now scrollable, has a tappable thumbnail and a full-width “Open in YouTube” button. This avoids the broken embedded player rather than displaying a known failure state.

Current local checks after this pass: Flutter analyzer **passed with no issues**, Flutter tests **21 passed**, `flutter build web --release` passed, and `flutter build apk --release` passed. The latest APK is local at `app/build/app/outputs/flutter-apk/app-release.apk`; it is still debug-signed. The built web bundle was refreshed in `server/web` locally, but this UI/coach-plan pass was **not deployed**. A physical Android small-screen/font-scale test and real gym walk-through remain required.

## Authorized deployment of coach-plan/UI pass — 30 September 2026

The owner explicitly authorized the latest site deployment. Ran `./deploy/deploy.sh --no-apk`; local/remote preflight passed and the only dry-run deletion was the obsolete `youtube_player_iframe` web player asset. Web/server files were synchronized, the container was rebuilt/recreated, and the script reported **DEPLOY OK**. The APK was not uploaded or changed; the remote APK remained 22,803,940 bytes. Remote `.env` and `/data` were protected by the deployment exclusions.

Read-only post-deploy checks passed: container `running`, `/data` Docker volume mounted, `.env` mode `600`, health `200`, unauthenticated state `401`, entry JavaScript `Cache-Control: no-store`, public `https://gym.abba-s.dev/` HTTP `200`, and the deployed web bundle SHA-256 matched the local build. The obsolete embedded-player asset is gone. No production data was read or mutated, no host-hardening script ran, and no Git push occurred.

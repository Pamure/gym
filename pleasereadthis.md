# Please read this — IronForge issues, mismatches, and browser audit

**Audit date: 30 September 2026**

## Scope and evidence

This is an audit, not a repair. I did not edit application, backend, deployment, or test source. No fixes were applied. This file is the requested deliverable.

I reviewed the Flutter client, state/API/reminder contracts, backend routes and schema, deployment scripts, existing tests, and relevant knowledge/change-log claims. I also exercised the actual Flutter web application in Chromium.

### How the application was tested

- Ran the existing Fastify application on an isolated loopback port, `127.0.0.1:18431`, against a new temporary database outside the repository. The existing preview and repository database were not used for test mutations.
- Used the refreshed, existing `server/web` bundle. Its `main.dart.js` was dated **03:22:26**, newer than the inspected workout and theme changes. The earlier observation that the bundle was stale no longer describes this snapshot.
- Tested desktop **1280 × 900**, phone **390 × 844**, and narrow-phone **320 × 640** layouts.
- Used actual browser controls for login, workout entry, empty-set validation, offline/online edits, manual sync, weight logging, two guided kegel sessions, deletion, navigation, export, and coach messages.
- Used authenticated browser requests to test API boundaries, seed clearly isolated fixtures, and compare server state with the application cache.
- Tested backend-unavailable startup and a fully offline browser reload separately.
- Ran disposable, local probes for the SQLite backup command and fresh-crontab installation pipeline. No real crontab, firewall, SSH configuration, container, or deployment was changed.
- Kept the AI key empty: the coach tests exercised local 503/429 handling, not paid or external model completions.
- Closed the audit browser tabs and stopped the isolated audit server afterward.

### Evidence labels

- **Browser-confirmed:** reproduced through the real application UI, with screenshots and/or browser network/cache inspection.
- **Runtime-confirmed:** exercised directly against the isolated API or in a disposable command probe.
- **Source-confirmed:** the implementation or configuration is directly visible. Any unexercised runtime consequence is marked **[INFERENCE]**.

**High** means data-loss, confidentiality, or recovery risk. **Medium** means incorrect behavior, misleading product guarantees, or an important consistency problem. **Low** means a narrower usability/documentation/maintenance issue.

This is not an exhaustive security certification or a medical review. Android scheduling, production Cloudflare configuration, physical-device playback, OEM battery behavior, and release installation were not tested.

## Highest-priority findings

1. **F01:** An older queued offline edit overwrites a newer successful online save after restart.
2. **F02:** Several API methods treat HTTP 400/401/404 as success; the UI can show data as saved when the server rejected it.
3. **F03:** Newly created kegel sessions all have local ID `0`; deleting one removes multiple local sessions while deleting none on the server.
4. **F04:** Explicit logout discards unsynced data while its confirmation says the data remains safe on the server.
5. **F05:** Bootstrap and SQLite runtime files are tracked by Git.
6. **F06:** The promised backup path has multiple independent failures, including a reproduced database-close race.

---

## A. Persistence, synchronization, and recovery

### F01 — Older offline edits overwrite newer online data; replay also leaves a stale local snapshot

**Severity: High. Browser-confirmed.**

**Files:** `app/lib/state/app_state.dart:144-145,185-186,329-409,421-435,684-691`.

**Actual reproduction:**

1. Saved Leg Press with `40 kg × 10` for each of two sets through the Workout screen.
2. Took the browser offline and changed set 1 to `45 kg`. The operation was persisted in `flutter.if_pending_v1`.
3. Reconnected and changed set 1 to `50 kg`. `/api/state` now returned `50`; the old queued `45` operation was still present.
4. Reloaded the app and waited for startup/replay to finish.
5. The server now returned **45**, the pending queue was empty, but the local cache still contained **50**.

There are two related contract failures: new direct writes do not supersede/drain older pending writes, and startup pulls/caches server state **before** replay without reconciling afterward. A server value and the visible cache can disagree while the app claims nothing is waiting to sync.

**Required behavior:** preserve mutation order or supersede obsolete operations, then reconcile local state with the committed result. The same design also puts deletions and corrections at risk; those additional paths are **[INFERENCE]**, not separately reproduced.

### F02 — HTTP rejections are silently acknowledged as successful writes

**Severity: High. Browser-confirmed; additional status-code consequences are [INFERENCE].**

**Files:** `app/lib/services/api.dart:20-27,78-127,145-152`; `app/lib/state/app_state.dart:438-487,496-608,623-634`; `app/lib/screens/dashboard_screen.dart:483-485`; `app/lib/screens/progress_screen.dart:420-431`.

Dio accepts every status from 200 through 499. Methods that call `_body()` convert errors into `ApiException`; most `Future<void>` write/delete methods do not. Those calls therefore resolve normally on a rejected request.

**Actual reproduction:** entered **-1 kg** in Home → Log weight → Save.

- The server returned **400**.
- The dashboard displayed **-1.0 kg** as the last weight.
- The local cache contained that value.
- Server `bodyWeight` was empty.
- The pending queue was `[]`.

F03 independently reproduced the same problem for a rejected DELETE. For other methods, **[INFERENCE]**: a 401 can be treated as success without changing the app to logged-out, and rejected replay operations can be removed from the queue despite never being committed.

**Required behavior:** check every HTTP response consistently; distinguish validation failure, expired authentication, and retryable connectivity failure. Local success copy must not imply server acknowledgement.

### F03 — Kegel creation never reconciles real IDs; deleting one fresh session deletes both locally

**Severity: High. Browser-confirmed.**

**Files:** `app/lib/state/app_state.dart:475-487,541-573`; `app/lib/services/api.dart:106-118`; `server/src/routes.js:90-99,230-237,375-392`.

Every new local entry is `KegelEntry(0, ...)`. The POST response returns only `{ok:true}`, not the new row ID, and the client does not refresh/remap it.

**Actual reproduction:** ran and saved two one-hold sessions from the real guided timer, then deleted one in Progress without refreshing first.

- The server had IDs **1** and **2**.
- Both local entries had ID **0**.
- DELETE returned **400**, because IDs must be at least 1.
- The UI showed a deletion success message and removed **both** local entries.
- Both rows still existed on the server; no deletion was queued.

**Required behavior:** stable distinct client identities, server-assigned ID reconciliation, and correct handling of edits/deletes before synchronization. Multiple legitimate sessions on one day are not themselves a duplication defect.

### F04 — Logout can permanently discard unsynced records

**Severity: High. Source-confirmed; loss scenario [INFERENCE].**

**Files:** `app/lib/state/app_state.dart:196-207,771-786`; `app/lib/screens/settings_screen.dart:219-242`.

Logout ignores a failed server request, clears local collections, deletes the cache and pending queue, and then writes the logout tombstone. The confirmation nevertheless says: **“Your data stays safe on the server.”**

**Scenario to address:** make an offline workout/check-in, then log out before it uploads. `_wipeLocal()` removes the only saved copy and its queued operation. A later login cannot recover data the server never received.

Clearing private local data on logout is defensible; claiming unsynced data is already safe is not. The user needs an explicit pending-data warning and a deliberate preservation/discard decision.

### F05 — Bootstrap and SQLite runtime files are tracked by Git

**Severity: High. Repository-inventory confirmed.**

`git ls-files -- server/data server/downloads server/.env app/android/key.properties` listed:

```text
server/data/bootstrap.json
server/data/ironforge.db
server/data/ironforge.db-shm
server/data/ironforge.db-wal
server/downloads/ironforge.apk
```

**Files:** `.gitignore:15-19`; `server/src/index.js:17-35`; `server/schema.sql`.

The bootstrap comment describes its JSON file as gitignored, but it is tracked. SQLite runtime files can contain account hashes, active sessions, private fitness records, and chat history; the WAL is also data, not harmless build output.

I did not dump the repository's credentials or personal database contents into this report. Whether the tracked snapshot contains only demo data, and whether any sensitive version was pushed, require a separate exposure assessment. This finding does **not** assert that a public leak occurred.

**Required behavior:** keep runtime databases, WAL/SHM files, and bootstrap credentials out of version control. If real secrets were distributed, merely adding ignore rules does not remove historical exposure.

### F06 — Nightly backup/recovery guarantees are not supported by the shipped script

**Severity: High. Runtime-confirmed failures plus source-confirmed path mismatch.**

**Files:** `deploy/harden.sh:24-31`; `server/docker-compose.yml:18-19`; `server/Dockerfile:19-21`; `knowledge/11-security-architecture.md:79-82`; `app/lib/screens/settings_screen.dart:202-207`.

Three independent problems:

1. **Backup promise is not awaited.** The cron command calls `db.backup(...)` followed immediately by `db.close()`. A disposable database probe produced:

   ```text
   UNAWAITED: The database connection is not open
   AWAITED: { value: 'preserved' }
   ```

2. **Backup creation and retention refer to different storage.** The host script creates `/home/gomango/ironforge/server/data/backups`, but the database lives in a **named Docker volume** mounted at `/data`. The backup command writes `/data/backups` inside that volume. The host retention command and documented weekly rsync read the unrelated host directory. The Dockerfile creates `/data`, not `/data/backups`. Container execution was not performed; the fresh-install failure and ineffective retention/export consequences are **[INFERENCE]** from those paths.
3. **Fresh-crontab installation can abort.** With `set -euo pipefail`, the unguarded `crontab -l` inside the installation subshell fails when no crontab exists. A safe stubbed reproduction returned **exit 1** with **empty installed input**; it did not reach the line emitting the backup job.

The Settings claim of nightly backups with 14-day retention should not be trusted as a recovery guarantee until successful backup creation, retention, and an actual restore are demonstrated on the intended volume.

### F07 — “Sync now” only downloads; it does not upload pending operations

**Severity: Medium. Browser-confirmed.**

**Files:** `app/lib/screens/settings_screen.dart:98-109`; `app/lib/screens/progress_screen.dart:649-653`; `app/lib/state/app_state.dart:227-241,413-419`.

During F01, Settings → Sync now showed **“Synced”**, but the pending `45 kg` operation remained unchanged. The action calls `refreshState()`, not a queue flush.

A pull also replaces local lists, so **[INFERENCE]**: an unsent local record absent from the server snapshot can disappear from view until a later replay/pull cycle. Reconnection alone did not flush the queued operation during the exercised browser flow.

**Required behavior:** a sync action should upload and reconcile, or be explicitly labelled “Refresh server copy.” It must not report complete synchronization with pending writes still present.

### F08 — Saving fewer sets does not replace the server's full workout entry

**Severity: Medium. Runtime-confirmed.**

**Files:** `server/src/routes.js:185-204`; `app/lib/state/app_state.dart:421-428`; `app/lib/screens/workout_screen.dart:382-401,428-455`.

The client replaces the whole `(date, exercise)` entry; the server only upserts supplied set numbers.

**Probe:** POST three sets, then POST two sets for the same date/exercise. The second response was `{ok:true,saved:2}`, but `/api/state` still returned **sets 1, 2, and 3**.

This is reachable through the UI because month/phase selection changes the prescribed set count while saves still target today. A later refresh can restore an omitted set and change volume/PR calculations.

### F09 — The “full state” endpoint silently truncates histories

**Severity: Medium. Runtime-confirmed.**

**Files:** `server/src/routes.js:269-274`; `app/lib/state/app_state.dart:290-319,897-908`; `app/lib/widgets/ember_heatmap.dart:15-18`.

`/api/state` limits check-ins to 60 rows and kegels to 90 rows. The client then clears its collections and replaces them with that partial response, with no pagination or truncation metadata.

**Isolated fixture results:**

| Collection | Rows stored in SQLite | Rows returned by `/api/state` |
|---|---:|---:|
| Check-ins | 61 | 60 |
| Kegel sessions | 93 | 90 |

The check-ins covered 61 consecutive dates ending September 30. August 1 was still within the 13-week heatmap window, but the oldest returned date was August 2.

This is **not database deletion**. It is loss from the client snapshot, visible history, heatmap inputs, and exports. Multiple valid kegel sessions per day make the 90-row cutoff cover even fewer days.

### F10 — Retried kegel creation has no idempotency protection

**Severity: Medium. Source-confirmed; retry outcome [INFERENCE].**

**Files:** `app/lib/state/app_state.dart:329-409,475-487`; `server/src/routes.js:230-237`; `server/schema.sql:53-60`.

POST kegel always inserts a new row. The queue has no stable command/session key, and successful operations are removed from persisted storage only after the whole flush finishes.

If the server commits a creation but its response is lost, or the app exits later in a partially completed flush, the same logical session can be replayed and inserted twice. The correct uniqueness unit is a session/operation ID, **not the date**, because multiple sessions per day are valid.

### F11 — Reminder preferences are not persisted locally; a disabled setting becomes enabled offline

**Severity: Medium. Browser-confirmed; Android scheduling effect [INFERENCE].**

**Files:** `app/lib/state/app_state.dart:611-634,638-768`; `app/lib/services/reminders.dart:139-168`.

The cache includes `startDate` and `unit`, but not the `prefs` map. Missing `reminder_enabled` defaults to `'1'`.

**Actual reproduction:** server preference was `reminder_enabled: '0'`. Reloaded the web app while aborting only API requests, allowing its static application files to load. It entered the cached offline session, and Settings showed **Enable reminders checked**, with default reminder times.

On Android, **[INFERENCE]**: the startup scheduler can consequently schedule reminders that the user had disabled, using default rather than chosen times. Changes to settings/start date also have no immediate general preference-cache write; their durability depends on later unrelated cache writes or successful server retrieval.

### F12 — Android reminder lifecycle is inconsistent with authentication lifecycle

**Severity: Medium. Source-confirmed; physical-device consequences [INFERENCE].**

**Files:** `app/lib/main.dart:33-37`; `app/lib/state/app_state.dart:115-121,167-207,611-615`; `app/lib/services/reminders.dart:139-206`.

- Startup calls `applyRemindersIfEnabled()` even if `init()` returned logged-out. Missing preferences default to enabled. A logged-out restart can therefore reschedule reminders that logout previously cancelled.
- Logout cancels all notifications, but a same-process login never reapplies fetched reminder preferences. The switch can show enabled while no schedules were recreated.
- The blanket documentation claim that notifications never run on Sunday is too broad: only the weekly gym reminders skip Sunday. Wake-up and recovery reminders use daily schedules.

These need Android-device verification. Browser tests cannot prove notification delivery, exact-alarm permissions, sound, reboot behavior, or OEM restrictions.

### F13 — “Export data / Copies everything” is not a complete backup

**Severity: Medium. Browser-confirmed.**

**File:** `app/lib/screens/settings_screen.dart:121-157`.

Used the actual Export data action and read the resulting clipboard JSON. Its keys were:

```text
exported, username, startDate, bodyWeight, measurements, workouts, kegels
```

The current server snapshot contained **60 check-ins**, but the export had no `checkins` field. It also omitted preferences, units, pending-operation metadata, and chat history. Kegels omit IDs and rename `holdSeconds` to `hold`.

The export is made from the bounded/local cache, not an authoritative full database backup. The “everything” claim and recovery expectations need to match its actual scope.

---

## B. Workout, dashboard, and progress correctness

### F14 — Weekly strength-session count collapses all session names to “Full”

**Severity: Medium. Browser-confirmed.**

**File:** `app/lib/screens/dashboard_screen.dart:30-35,236-254,282-298`.

`_logsForWeek()` returns `day.title.split(' ').first`. Full Body A, B, and C all become **Full**. The numerator is then `logsThisWeek.toSet().length`.

**Actual result:** logged dates Monday September 28 and Wednesday September 30. Dashboard displayed:

```text
This week 1 / 3 strength sessions
Strength sessions: Full, Full
```

Two distinct dates become one unique string. With all three required days logged, this implementation would still display 1/3 **[INFERENCE]**. Count distinct session/date identities, not the first word of their display titles.

### F15 — Any workout record can stand in for a required strength session

**Severity: Medium. Source-confirmed; partial-session treatment observed.**

**Files:** `app/lib/state/app_state.dart:813-817`; `app/lib/screens/dashboard_screen.dart:124-127,282-295,525-532`.

Required-day counting and missed-day checks test whether a date has **any** workout log. They do not check planned strength exercise completion or exclude recovery-only records.

The browser showed today as logged after saving only Leg Press from the six-exercise Full Body B session. The “add more” wording acknowledges partial activity, but the strength-session counter uses the same broad existence rule. **[INFERENCE]**: marking only an optional recovery activity on a Monday would still satisfy the Monday strength count.

Separate “some activity logged,” “session in progress,” and “required strength session completed.”

### F16 — Streak rules effectively require optional days and reset before today's session

**Severity: Medium. Source-confirmed; schedule mismatch observed.**

**Files:** `app/lib/state/app_state.dart:844-863,867-891`; `app/lib/widgets/ember_heatmap.dart:145-158`; `app/lib/data/program.dart:114-136,177-199,235-265`.

Streaks skip Sunday but require a log every other calendar day, including optional Tuesday/Thursday/Saturday. They also start at **today**, immediately returning zero when today's workout has not yet happened.

The exercised Monday/Wednesday pattern produced a one-day streak despite following the required-day spacing. This is not an arithmetic error in a daily streak; it is a product mismatch with “optional movement is genuinely optional.” A planned-session consistency measure or clearly distinct activity streak would avoid pressuring extra attendance.

### F17 — Heatmap intensity is a bit mask treated as an ordinal score

**Severity: Medium. Source-confirmed.**

**Files:** `app/lib/state/app_state.dart:894-908`; `app/lib/widgets/ember_heatmap.dart:8-18,49-63`.

`heatmapCells()` ORs workout=2, check-in=1, kegel=4. Valid values include 4, 5, 6, and 7. The widget instead clamps every value into the 0–4 color ramp.

Consequently **kegels alone (4)** and **workout + check-in + kegels (7)** receive the same maximum color. This contradicts the documented meaning that maximum intensity represents all three activities. It does not cause an out-of-range crash, because the widget clamps the value.

### F18 — Timed work and kegel repetitions are stored/displayed with the wrong meaning

**Severity: Medium. Browser-confirmed for kegel units; other paths source-confirmed.**

**Files:** `app/lib/widgets/kegel_sheet.dart:37-59,114-122`; `app/lib/screens/workout_screen.dart:475-476,758-845`; `app/lib/screens/progress_screen.dart:525-539,682-683,760-784`; `app/lib/data/program.dart:169-174,227-231`.

- The guided kegel timer increments `_done` once per **hold/repetition** but passes it as the number of **sets**. After one real hold, the API and history reported `sets:1`; Progress labels it “1 sets × 3s holds.” The guide distinguishes sets from 8–10 holds per set.
- Planks and dead bugs only receive “Mark done,” storing a synthetic `{weightKg:0,reps:1}` rather than actual holds, seconds, reps, or completed sets.
- Farmer carries label input as seconds but store the duration in `reps`. History renders it as reps and the volume chart combines `kg × seconds` with `kg × reps` under one “kg lifted” label.

Different activity measures need distinct semantics; these values cannot honestly be treated as interchangeable training volume.

### F19 — Optional cardio cards ignore the programmed duration and progression

**Severity: Medium. Browser-confirmed.**

**Files:** `app/lib/screens/workout_screen.dart:480-485`; `app/lib/data/program.dart:120-125,183-188,241-246`.

The fallback recovery-walk description always says **20 minutes**. It does not render that day's `repsByMonth` target.

The current week-2 Thursday card exposed “Light cardio ... 20 minutes,” although Thursday's first-month target is **15**. Later 25/30-minute progression also remains hidden behind the same static text.

### F20 — Beginner equipment/alternative guidance is incomplete and some alternatives change the movement pattern

**Severity: Low coverage gap; Medium content-consistency risk. Source-confirmed.**

**Files:** `app/lib/data/exercise_guides.dart:22-177`; `app/lib/screens/workout_screen.dart:711-714`; `plan.md:7`; `renovation.md:10-12`.

Dead bug and plank are prescribed but have no `ExerciseGuide`, so their expanded cards omit the structured equipment/setup/alternative block supplied to other exercises. They still have catalog form cues; they are not wholly undocumented.

The “same-pattern alternative” promise is also too broad: a leg curl is listed as a Romanian-deadlift alternative, and treadmill walking as a farmer-carry alternative. Those can be useful activities, but they are not equivalent hinge/carry replacements. Explain when a substitution changes the day's training rather than calling every option the same pattern.

### F21 — “Every log: edit or delete” overstates the available history controls

**Severity: Medium. Browser/source-confirmed.**

**File:** `app/lib/screens/progress_screen.dart:37-38,620-704,752-791`.

The logbook renders workout, weight, and kegel rows. Only kegel rows have an explicit edit control. Workout and weight rows have delete controls; measurement history is not rendered, and older check-ins have no general editing history screen.

Saving again from Workout changes **today's** exercise entry, not an arbitrary historical row. Thus “Edit = save over the same entry” is not a usable historical edit workflow for many rows shown under that promise.

### F22 — Week chart labels are zero-based, and browsing another week can mislabel today's logged volume

**Severity: Medium. Browser/source-confirmed.**

**Files:** `app/lib/screens/progress_screen.dart:525-533,560-568`; `app/lib/screens/workout_screen.dart:447-454`; `app/lib/screens/dashboard_screen.dart:94-97`.

The volume chart uses `BarChartGroupData(x:i)` for twelve weeks, so Week 1 is plotted at **0**, Week 2 at **1**, etc. The zero-based axis was visible in the browser.

Separately, workout saves combine today's date with the manually selected week/day. **[INFERENCE]**: browsing W12 and saving today puts today's volume in week 12. The Home “today” action resets the selected day but not the selected week. Either intentionally label manual program-week assignment or keep preview selection separate from log metadata.

### F23 — Accepted unit preferences are not applied to the visible app

**Severity: Low. Source-confirmed.**

**Files:** `server/src/routes.js:289-295`; `app/lib/state/app_state.dart:92,219,677`; `app/lib/screens/workout_screen.dart:783-790`; `app/lib/screens/progress_screen.dart:386-404,475,775`.

The API accepts `units='lb'` and AppState stores it, but logging fields, charts, history, and body measurements remain hardcoded to kg/cm. There is no corresponding units picker/conversion in the inspected Settings screen.

If kg-only is intentional, the exposed preference is misleading dead functionality; otherwise conversions and labels are incomplete.

---

## C. Tutorials, AI, nutrition, and usability

### F24 — The new web tutorial thumbnail is blocked by the production CSP

**Severity: Medium. Browser-confirmed.**

**Files:** `server/src/index.js:55-63`; `app/lib/widgets/youtube_sheet.dart:97-104,153-162`.

Opened the real Leg Press tutorial sheet. It showed the fallback video icon instead of its intended thumbnail. The request to:

```text
https://img.youtube.com/vi/IZxyjW7MPJQ/hqdefault.jpg
```

failed. A browser `securitypolicyviolation` listener recorded:

```text
directive: connect-src
blockedURI: https://img.youtube.com/vi/IZxyjW7MPJQ/hqdefault.jpg
```

Flutter CanvasKit fetches `Image.network` through XHR/fetch here. `img-src https:` does not authorize that mechanism; `connect-src` omits `img.youtube.com`.

The deliberate external-YouTube fallback is not itself a bug. The thumbnail failure is a separate, reproduced CSP mismatch. External playback was not tested.

### F25 — Coach rate limits and validation failures are misreported as connectivity failures

**Severity: Medium. Browser-confirmed for 429; 400 consequence [INFERENCE].**

**Files:** `app/lib/screens/coach_screen.dart:112-122`; `app/lib/services/api.dart:145-165`; `server/src/routes.js:317-330`.

The UI parses exception **text** for `'429'`, but `ApiException.toString()` returns only the server's message. The real rate-limit message is “slow down — max 8 questions per minute,” without the digits 429.

With the AI key absent, one UI request plus seven local API requests filled the rate window. The next real UI request returned **429** and displayed:

```text
Coach could not connect. Your saved workout data is still safe.
```

The intended “Try again in a minute” message was not shown. **[INFERENCE]**: an 801-character input similarly hides the server's actionable 800-character limit behind a connection error.

The absent-key **503** explanation did work and is recorded as a passing case, not an app defect.

### F26 — IronCoach receives conflicting canonical program facts

**Severity: Medium. Source-confirmed; model behavior [INFERENCE].**

**Files:** `server/src/ai.js:14-35,76-77,106-110,137-138`; `app/lib/screens/settings_screen.dart:59-75`; `app/lib/data/program.dart:55-69`; `knowledge/01-training-program.md:65-67`.

Settings permits changing the program start. The AI context reads that setting, but the system prompt still mandates September 21 through December 13 and says the dates **must** agree with the app. A user starting October 5 would have an app end date of December 27 while receiving those fixed instructions.

First-phase effort wording also differs: the app says **3 RIR**, while the AI prompt and knowledge document say **1–3 RIR**. This is duplicated product configuration with different values, not evidence that the model necessarily gives bad advice.

### F27 — AI attendance context invents missed sessions before the program and before today's session is due

**Severity: Medium. Source-confirmed; generated-context consequence [INFERENCE].**

**File:** `server/src/ai.js:79-100`.

The trailing 21-day attendance loop marks every unlogged Monday/Wednesday/Friday as “required strength missed.” It does not filter by program start/end or today's scheduled gym time.

A newly starting user is therefore assigned missed required sessions from before enrollment. Today's future session can be labelled missed in the morning. The context builder also uses server-local dates rather than an explicit user training timezone, which can disagree with the browser's date near midnight on a UTC-hosted deployment.

These are false input facts even if the prompt separately instructs the model not to shame the user.

### F28 — AI fallback attempts can outlive the client's entire request deadline

**Severity: Medium. Source-confirmed; slow-provider consequence [INFERENCE].**

**Files:** `server/src/ai.js:7-11,146-178`; `app/lib/services/api.dart:24-25`.

Each model attempt receives a fresh 90-second deadline. The default online/base sequence can take roughly 180 seconds, but Dio's receive timeout is 90 seconds.

A slow first attempt can consume the client's whole waiting period before a fallback completes. The UI can report failure while the server continues and later stores a successful conversation. No external/slow-provider test was run; this is a directly visible deadline mismatch.

### F29 — “Your data stays on your own server” omits the AI data transfer

**Severity: Medium. Source-confirmed; applies when AI is configured.**

**Files:** `app/lib/screens/login_screen.dart:104-108`; `app/lib/screens/coach_screen.dart:225-228,319-325`; `server/src/ai.js:47-121,137-158`.

The coach serializes workouts, weight and measurements, pelvic-floor history, check-ins, mood, attendance, and chat context into requests sent to OpenRouter. The UI describes access to server data but does not clearly explain that this information is transmitted to an external provider.

The blanket own-server privacy claim therefore does not describe the configured AI feature. This audit sent no real user data to an AI provider.

### F30 — Nutrition search/budget data is not connected to the nutrition screen, and its helpers overstate their behavior

**Severity: Medium feature mismatch. Source/browser-surface confirmed.**

**Files:** `app/lib/screens/learn_screen.dart:1-8,274-348`; `app/lib/data/diet_database.dart:380-435`; `app/test/program_test.dart:57-63`.

The Nutrition tab is static text. It does not use `foodDb`, `searchFood`, or `calculateBudget`; there is no food search or interactive budget planner on that surface, despite descriptions of a food reference for the offline nutrition screen.

The helper called search is substring/exact/category matching, not typo-tolerant fuzzy matching. The budget helper always returns the same **INR 182** food list; changing the target only changes the reported target/within-budget comparison. Its comment does call it an example, so this is not a failed optimization algorithm—but it should not be presented as a target-adapting calculator.

Tests importing the data helpers do not establish that those features are available to a user.

### F31 — Health/nutrition copy remains internally inconsistent or more certain than the safety policy

**Severity: Medium content-consistency risk. Source-confirmed, not a medical diagnosis or independent literature review.**

**Files:** `app/lib/screens/learn_screen.dart:310-316,430-436,516-524,620-650`; `app/lib/data/diet_database.dart:126-136`; `app/lib/data/program.dart:292-300`; `app/lib/widgets/kegel_sheet.dart:10-11`; `app/lib/screens/settings_screen.dart:496-501`; `knowledge/09-risks-safety.md:30-46`; `app/lib/screens/progress_screen.dart:580-581`.

Specific mismatches:

- Learn says ordinary curd/dahi has **8–11 g protein/100 g**; the typed food entry says **3.8 g/100 g**. No strained/high-protein product distinction explains the difference.
- The kegel guide says month 2 can build up to 5 seconds and month 3 should maintain if symptom-free; the timer automatically uses **3, 5, then 8 seconds**. Settings still advertises “3 sets, 5 min,” not the actual one-repetition-at-a-time, manually saved flow.
- Learn promises stronger sexual function and “results typically at 6–8 weeks,” while the canonical notes emphasize optional individualized practice and symptom screening.
- Statements such as “cold muscles + load = the #1 beginner injury mechanism,” “half the growth lives here,” and a fixed recomposition identity are not supported within the app and are much stronger than its conservative safety policy.
- Progress says volume **must** rise week over week, contradicting the documented option to deload/reduce work for recovery.
- The safety document gives a blanket 3–4 L/day hydration target and fixed substitution duration, while revised nutrition copy says to personalize rather than prescribe rigid targets without context.

These need one content reconciliation pass against the chosen evidence and coaching policy. I am not claiming that every exercise statement is medically false; the clear defects are conflicting numbers, unsupported certainty, and inconsistent personalization.

### F32 — Readable palette colors are overridden by low-contrast text on selected controls

**Severity: Medium. Source/color-calculation confirmed; controls visible in browser.**

**Files:** `app/lib/theme.dart:23-25,59-64,72-77`; `app/lib/screens/workout_screen.dart:117-153`; `app/lib/screens/learn_screen.dart:56-64`; `app/lib/screens/coach_screen.dart:190-203`; `app/lib/screens/progress_screen.dart:134-137,267-272`.

The theme correctly chooses a dark `onPrimary`, but several screens explicitly use white text over teal/coral selections or messages.

Calculated WCAG contrast for the defined opaque colors:

| Foreground/background | Contrast |
|---|---:|
| White `#FFFFFF` on teal `#49D6C2` | approximately **1.80:1** |
| White `#FFFFFF` on coral `#FF9A76` | approximately **2.07:1** |
| Navy `#0B1220` on teal | approximately **10.41:1** |

The first two are below the 4.5:1 normal-text target cited in the theme itself. The problem is not the dark text palette in general; it is the per-widget overrides.

### F33 — Some controls and visualization data lack useful accessibility names

**Severity: Low. Browser/source-confirmed.**

**Files:** `app/lib/screens/coach_screen.dart:270-279`; `app/lib/screens/workout_screen.dart:767-805`; `app/lib/widgets/ember_heatmap.dart:44-75`.

The browser accessibility tree exposed the coach send icon as a **button with an empty name**. Repeated workout inputs are named only “kg” and “reps,” without a set number in their own accessible names. Heatmap cells have no individual date/activity semantic labels or tooltips.

**Correction to the earlier attempt:** the workout text fields and Save button **do** appear in the accessibility tree when scrolled into view. Their complete absence was not a valid finding. Coordinate/automation hit-test failures are not being counted as app bugs.

---

## D. Web delivery, deployment, documentation, and tests

### F34 — A fully offline web reload cannot open the cached app

**Severity: Medium. Browser-confirmed.**

**Files:** `server/web/flutter_service_worker.js:3-31`; `server/src/index.js:69-72`.

Opened the application online in a second browser tab, then enabled full offline mode and reloaded. The browser displayed its **ERR_INTERNET_DISCONNECTED** page rather than the workout app.

The delivered service worker unregisters itself and has no application-shell caching. An already open app with a cached session can perform local operations, and backend-only failure is handled differently, as tested in F11. Those facts do not establish offline cold-start support on the web.

Clarify the scope of “works offline” or provide an intentionally supported offline web shell. Android assets are bundled and were not tested by this browser scenario.

### F35 — Unversioned JavaScript can remain stale for an hour after an update

**Severity: Medium. Runtime-confirmed headers; actual two-version cache-reuse outcome [INFERENCE].**

**Files:** `server/src/index.js:69-86`; `server/web/index.html`; `server/web/flutter_bootstrap.js`.

Observed response headers:

| URL | Cache-Control |
|---|---|
| `/` | `no-store` |
| `/main.dart.js` | `public, max-age=3600` |
| `/flutter_bootstrap.js` | `public, max-age=3600` |
| `/flutter_service_worker.js?v=audit` | `public, max-age=3600` |

A fresh index does not force refetching entry scripts at unchanged URLs. The exact `req.url` comparison also misses the service-worker path when a version query is present. This leaves a path for mixed/old deployments despite the no-stale-preview comment.

No deployment was performed to reproduce an actual version swap.

### F36 — Deploying with `--no-apk` can replace or delete the current remote APK

**Severity: Medium. Source-confirmed; deployment consequence [INFERENCE].**

**File:** `deploy/deploy.sh:46-59`.

The broad `rsync --delete server/ ...` includes `server/downloads/ironforge.apk`. Fresh release APKs are separately uploaded from `app/build/...` and do not update that local `server/downloads` copy. On the next `--no-apk` deployment, the broad sync can restore an older local APK—or remove the remote APK if the local file is absent—while the corrective APK-upload branch is skipped.

Treat the download artifact independently from broad server-directory synchronization. No rsync to the real host was run.

### F37 — Bootstrap credential provisioning uses unsafe temporary-file handling and unsafe env serialization

**Severity: Medium. Source-confirmed; exposure/interpolation consequences [INFERENCE].**

**File:** `deploy/deploy.sh:20-37`.

- A plaintext password is written to predictable `/tmp/if-env` without private-at-creation permissions or `umask 077`. Under a normal `022` umask, that file can be world-readable; a failed `scp` exits before the cleanup command. The later remote `chmod 600` does not protect the local interval or leftover file.
- The arbitrary interactive password is written unquoted into Compose's env-file syntax. Dollar interpolation and other special characters can change the password before bootstrap. For example, an unset variable in a value such as `Training$UNSET-123` need not reach the server literally.

Use secure temporary-file lifetime handling and literal-safe env serialization. No real password or deployment file was used for a provisioning test.

### F38 — “Release” APK builds still use the debug signing key

**Severity: Medium release blocker. Source-confirmed; already acknowledged in README.**

**File:** `app/android/app/build.gradle.kts:33-38`; `deploy/deploy.sh:46-48`.

The release build explicitly uses `signingConfigs.getByName("debug")`, while deploy builds/uploads release APKs. This is not a production signing setup and can break update continuity across build machines/debug keystores.

This is a known unfinished release prerequisite, not a newly introduced regression. No release installation or signing migration was attempted.

### F39 — Security and deployment guarantees disagree with implementation or cannot be inferred from local code

**Severity: Medium documentation/trust issue. Source-confirmed; production configuration unverified.**

**Files:** `knowledge/11-security-architecture.md:9-31,53-82`; `knowledge/12-tech-stack-deployment.md:83-115,154-156`; `server/src/auth.js:8-12,31-37,55-56`; `server/src/index.js:46-49`; `server/src/routes.js:10`; `deploy/harden.sh:34-38`; `app/lib/screens/settings_screen.dart:202-207`.

| Claim | Actual implementation / limit |
|---|---|
| 128-bit, 12-hour sessions | 32 random bytes (256 bits), 30-day bounded sessions |
| Exponential login backoff | Fixed one-minute/15-minute counting windows |
| `harden.sh` enforces SSH password auth off | It only checks and warns |
| Unknown JSON fields are rejected | Ajv is configured with `removeAdditional:true`; a valid weight body with an extra field was accepted with HTTP 200 |
| Session secret/TOTP secret in the current security inventory | `SESSION_SECRET` is provisioned but unused by current server auth; current schema has no TOTP field |
| Password hash stored in `.env` | Current code stores hashes in SQLite; bootstrap plaintext may remain in the env file |
| Password rotation automatically removes bootstrap password from `.env` | The password route changes the database and sessions, not the env file |
| Nobody can reach the app without Cloudflare Access | The UI says this unconditionally; Access is separately configured infrastructure, not established by a local login screen |
| Per-visitor/IP rate limiting through the tunnel | `trustProxy:false` uses the proxy peer IP behind the described tunnel; separate visitors can share a bucket **[INFERENCE]** |
| Nightly backups and 14-day retention | F06 demonstrates why the supplied script does not establish that guarantee |

The intentional 30-day session is not itself a defect. The misleading part is inconsistent documentation and unverified absolute deployment guarantees.

### F40 — The documented API is not the implemented API

**Severity: Low integration/documentation issue. Runtime/source-confirmed.**

**File:** `knowledge/12-tech-stack-deployment.md:83-115`; `server/src/routes.js:20-39,152-164`.

The document advertises `PUT /api/state` for offline merge and workout sets shaped `{kg,reps}`. Actual probes showed:

- `PUT /api/state {}` → **404**.
- A workout with documented `{kg,reps}` sets → **400**, missing `setNumber` and `weightKg`.
- `/api/me` returns profile/settings/start date, not a computed program week.
- The sample schema retains a nonexistent `totp_secret` column.

The client replays individual mutations; there is no state-merge endpoint. Documentation should describe that actual contract rather than imply compatibility that does not exist.

### F41 — Existing tests provide misleading confidence in the highest-risk behavior

**Severity: Medium. Source-confirmed.**

**Files:** `app/test/audit_test.dart:9-15,27-49,53-85,89-99`; `app/test/program_test.dart:57-63`; `server/test/smoke.sh:70-86`; `renovation.md:78-86`.

Several audit tests are literal `expect(true,isTrue)` assertions. Others test constants such as `2 | 1 | 4`, not `AppState.heatmapCells()`. They do not exercise the queue, logout, reminders, date helper, or streak implementation they describe.

The smoke test's workout edit sends all three original sets, so it misses omitted-set replacement. Its password-change section checks old-password rejection, not revocation of a separately retained old session cookie. The diet test demonstrates helper data exists, not an accessible nutrition feature.

Passing analyzer/test output cannot establish those contracts. The earlier session logged a clean analyzer and successful web build, but those were not behavioral proof; this resumed audit did not rerun the suite or claim a fresh test pass. The current report's reproduced failures come from the actual application and isolated probes.

### F42 — The extended smoke script is unsafe as a live-server audit and overstates what it checks

**Severity: Medium. Source-confirmed; live side effects [INFERENCE].**

**File:** `server/test/extended.sh:8-10,19-28,48-50,64-77`.

- “Bootstrap user” only attempts a login; it does not create the required user.
- The “heatmap intensity” test checks a workout-row count, not heatmap intensity.
- The state-shape test only checks that `workouts` appears, not the advertised complete shape.
- Eight sequential real AI calls can incur provider requests when a key is configured. Slow responses can move the ninth request outside the intended 60-second window, invalidating the rate-limit assumption.
- “Cleanup” does not remove the inserted kegel row, reminder preference, or any successful chat history, despite claiming data is empty.

I did not run this script against a live or configured-AI server. Use isolated fixtures and deterministic local provider behavior for such a test.

### F43 — An advertised streak sub-widget is still an empty scaffold

**Severity: Low. Source-confirmed.**

**File:** `app/lib/widgets/ember_heatmap.dart:165-184`.

`StreakHero` constructs a “Mini heat bar — last 7 days,” but `_last7()` always returns an empty map and `_WeekStrip.build()` always returns `SizedBox.shrink()`.

There is no rendered mini-strip or data behind it. This is dead scaffolding, not a crash and not the main 13-week heatmap. Remove the misleading internal feature claim or implement the intended visualization when it is actually required.

---

## Additional validation gaps demonstrated by the API probes

These are grouped here rather than inflated into several nearly identical findings. They reinforce F02/F08/F39:

| Input | Observed result | Problem |
|---|---|---|
| Body-weight date `2026-02-30` | HTTP 200 | Shape-only date regex accepts an impossible calendar date |
| Workout set with `reps:0` | HTTP 200 | Backend permits a set the current workout UI explicitly rejects |
| `reminder_enabled:'banana'` | HTTP 200 | Boolean-like setting is an arbitrary string despite downstream `'1'`/`'0'` interpretation |
| Valid weight body plus an unknown field | HTTP 200 | Contradicts documentation saying unknown fields are rejected |

**Sources:** `server/src/routes.js:23-34,44-45,65-70,278-295`.

The impossible-date issue also applies to `program_start_date`'s regex validation by inspection. Inputs need semantic bounds where those bounds are part of the app's actual contract, not just textual shape checks.

## Working behavior and earlier suspicions that were ruled out

A useful audit must not preserve false positives:

- **Normal login worked** through actual keyboard entry. The first synthetic-fill attempt had automation/input-event errors; those were not promoted to an authentication defect.
- **Workout fields and Save are available when scrolled into view.** A real two-set `40 kg × 10` save reached the server correctly. Empty-set saving displayed its validation message.
- **The rest countdown works visibly.** On the narrow phone layout it changed to a running countdown and a Restart control. Background timing/device notification behavior was not assessed.
- **Expanded exercise guidance renders:** equipment, setup, alternatives, form cues, mistakes, and rest controls were inspected.
- **No general InkWell/input-breaking defect was established.** The earlier coordinate experiments were unreliable; they are not evidence that text-field taps are swallowed.
- **Start +83 days is correct** for the inclusive last day of a 12-week program. September 21 through December 13 is 84 calendar days inclusive. This is not an off-by-one bug.
- **A 13-week rolling heatmap is not inherently inconsistent with a 12-week program.** The genuine problems are intensity semantics and truncated input history, not its width alone.
- **Multiple kegel sessions per day are legitimate.** Identical POSTs inserting separate rows does not, by itself, prove a bug. Missing IDs and unsafe replay are the defects.
- **30-day sessions are intentional.** Stale 12-hour documentation is the mismatch.
- **Missing AI configuration is an expected local limitation.** The browser showed the intended explanatory message for 503. The 429 misclassification is the reproduced bug.
- **Web external-video fallback is intentional.** The CSP-blocked thumbnail remains a separate issue.
- **Recovery-walk/stretch intentionally use special cards rather than catalog entries.** Their absence from the exercise catalog is not a missing-exercise failure; the hardcoded duration is the issue.
- **History caps do not delete SQLite rows.** The database still contained 61 check-ins and 93 kegel rows while the client endpoint returned 60/90.
- Existing code contains user-scoped SQL parameters and session checks on data routes. This review found no basis to claim SQL injection or an unauthenticated data-route bypass.

## Suggested repair order — no repairs performed

1. Preserve data first: F01–F04, F07–F13. Treat queue ordering, acknowledgement, identity, and reconciliation as one explicit client/server contract.
2. Protect recoverability/confidentiality: F05–F06; verify a real backup **and restore** before retaining unconditional backup promises.
3. Correct progress and prescription semantics: F14–F23.
4. Fix browser-visible errors and misleading UI claims: F24–F35.
5. Reconcile release/deployment/docs/tests: F36–F43 and the API validation table.

Do not “fix” these by hiding errors, marking every response successful, or merely rewriting tests to agree with current behavior. The verified failures concern actual saved data, actual browser behavior, and guarantees users can reasonably rely on.

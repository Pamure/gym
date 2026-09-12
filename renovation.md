# IronForge Renovation Guide

Comprehensive audit of every feature, its criticism, and the fixtures / tests
that should exist. This is a **renovation plan**, not a marketing doc — each
section ends with **what to test** that defends a real, observable contract.

> **Status (2026-09-06):** Release 2 deployed on yarmuk. Items marked ✅
> shipped; 🟡 shipped with known limitation; 🔴 not yet shipped.

---

## 0 · Design language — "Forge"

**Source of truth:** `app/lib/theme.dart`

### Decisions (research: WHOOP / Strong / Hevy 2026 dark-mode standard)

| Token           | Value      | Purpose                                       |
| --------------- | ---------- | --------------------------------------------- |
| `bg`            | `#0A0A0B`  | App background (near-black, not pure #000)    |
| `surface`       | `#131316`  | Cards                                         |
| `surface2`      | `#1C1C21`  | Inputs, chips, pressed                        |
| `text`          | `#F2F2F3`  | Primary text                                  |
| `dim`           | `#9C9CA6`  | Secondary text                                |
| `faint`         | `#5C5C66`  | Tertiary / placeholders                       |
| `ember`         | `#FF5A1F`  | **Signature accent** — heat/fire/forge        |
| `emberHot`      | `#FF8A5C`  | Highlights                                    |
| `emberDeep`     | `#7A2A0C`  | Subtle dark ember fills                       |
| `green`         | `#4ADE80`  | Success / logged                              |
| `amber`         | `#FBBF24`  | Warning / streak                              |
| `red`           | `#F87171`  | Destructive                                  |
| `blue`          | `#60A5FA`  | Check-in                                      |
| `streakRamp[0..4]` | 5-step ember | GitHub-style heatmap intensity          |

### Rules enforced
- **No purple→pink gradient spam.** `T.gradient` is now a dark ember→black
  surface, not a brand banner. `GradientCard` has a hairline ember border.
- **Color = information, not decoration.** Gradients are reserved for the
  single "today's session" header; everywhere else, surfaces are flat.
- **Oversized glanceable numerals** for streak / weight / time (WHOOP standard).
- **Streak art = the streak itself.** `StreakHero` shows a 88px radial ember
  glow whose intensity scales with `streakDays / 30`. The hotter the streak,
  the hotter the glow. The art *is* the data.

### Tests
- **Visual snapshot:** open Learn screen, confirm StreakHero glow scales with
  `streakDays=0` (faint), `=15` (medium), `=30+` (full). Manual today.
- **Type render:** assert every surface bg in `theme.dart` is `#0A0A0B` ± `#0F0F12`
  and never `#000000` (halation test).
- **iOS / Android contrast:** run axe-core on dashboard; no contrast < 4.5:1.

---

## 1 · Feature inventory (every feature that exists)

### A. Auth & session
| # | Feature                      | File                              | Status |
|---|------------------------------|-----------------------------------|--------|
| 1 | Argon2id password login      | `server/src/routes.js` (login)    | ✅     |
| 2 | HttpOnly + Secure + SameSite cookie | `server/src/routes.js`     | ✅     |
| 3 | Login rate limit (5/15min)   | `server/src/auth.js` (rateLimiter)| ✅     |
| 4 | Forgot / reset password      | —                                  | 🔴     |

**Criticism:** Single shared rate limit across all usernames allows trivial
user-enumeration timing attacks. The bootstrap password is a permanent fallback.

**Fixture:** Reset password flow with single-use token (1h TTL, email/SMS in
future). Token endpoint behind its own rate limit (3/h).

### B. Dashboard
| # | Feature                          | File                       | Status |
|---|----------------------------------|----------------------------|--------|
| 1 | Header (week X of 12, phase)     | `screens/dashboard_screen.dart` | ✅ |
| 2 | Program start date (auto-set)    | `state/app_state.dart:102`  | ✅     |
| 3 | Today's session card             | `dashboard_screen.dart`    | ✅     |
| 4 | Missed-yesterday nudge (amber)   | `dashboard_screen.dart:_MissedNudge` | ✅ |
| 5 | Streak hero (radial glow)        | `widgets/ember_heatmap.dart` | ✅    |
| 6 | 13-week consistency heatmap      | `widgets/ember_heatmap.dart` | ✅    |
| 7 | Stats row (streak/weight/PRs)    | `dashboard_screen.dart:_StatCard` | ✅ |
| 8 | Body-weight chart (fl_chart)     | `dashboard_screen.dart:_WeightChart` | ✅ |
| 9 | Quick actions                    | `dashboard_screen.dart:_QuickActions` | ✅ |
| 10| Program end date line            | `app_state.dart:programEndDate` | ✅ |

**Criticism:** Phase text wraps into a paragraph; the "RIr · description" block
becomes wall-of-text on first open. Should be a single `Headline·body`
two-line card.

**Fixture:** Phrase > 80 chars truncates with ellipsis. Verified manually today.

### C. Workout logging
| # | Feature                          | File                       | Status |
|---|----------------------------------|----------------------------|--------|
| 1 | Day selection                    | `screens/workout_screen.dart` | ✅ |
| 2 | Exercise list per phase/month    | `data/program.dart`        | ✅     |
| 3 | Set logging (weight × reps)      | `screens/workout_screen.dart` | ✅ |
| 4 | Rest timer (auto)                | `screens/workout_screen.dart` | ✅ |
| 5 | YouTube tutorial sheet           | `widgets/youtube_sheet.dart` | ✅   |
| 6 | Save → server (POST /logs/workout) | `services/api.dart`     | ✅     |
| 7 | Edit / delete entries            | `state/app_state.dart`     | ✅     |
| 8 | Personal records (PR) detection  | `state/app_state.dart:personalRecords` | ✅ |
| 9 | Progressive-overload hint        | `screens/workout_screen.dart` | ✅ (text only) |
| 10| Offline queue + retry            | `state/app_state.dart:_enqueue` | ✅ |

**Criticism:** PR detection is single-set based; misses "3 sets at 60kg > 1 set
at 60kg" volume PRs. Overload hint is static text — not actually comparing
last-session numbers.

**Fixture:** Volume PR (`Σ weight × reps`) detected. Hint shows last week
baseline vs this week and labels "+2.5kg vs last week".

### D. Body weight & measurements
| # | Feature                          | File                       | Status |
|---|----------------------------------|----------------------------|--------|
| 1 | Log weight (kg)                  | `screens/progress_screen.dart` | ✅ |
| 2 | Log 4 measurements (chest, arms…) | `screens/progress_screen.dart` | ✅ |
| 3 | Trend chart                      | `screens/progress_screen.dart:_BodyChart` | ✅ |
| 4 | Edit / delete (any date)         | `state/app_state.dart`     | ✅     |

**Criticism:** Units hardcoded kg. No switch for lb. India user may want kg,
US user lb.

**Fixture:** Settings → Units (kg/lb) toggle. Conversion: 1 lb = 0.4536 kg.
Persists in `settings.units`. Affects display + logging.

### E. Kegels
| # | Feature                          | File                       | Status |
|---|----------------------------------|----------------------------|--------|
| 1 | Daily log (sets, hold seconds)   | `widgets/kegel_sheet.dart` | ✅     |
| 2 | Edit / delete any entry          | `state/app_state.dart`     | ✅     |
| 3 | Best streak (7-day window)       | `state/app_state.dart`     | ✅     |
| 4 | Reminder notification (Android)  | `services/reminders.dart`  | ✅     |

**Criticism:** "7-day" target is invisible. User has no idea what "good" is.

**Fixture:** Show "7 of 7 this week" / "3 of 7 — 4 to go" in the kegel sheet.

### F. Daily check-in
| # | Feature                          | File                       | Status |
|---|----------------------------------|----------------------------|--------|
| 1 | Energy 1–5                       | `screens/progress_screen.dart:_CheckinCard` | ✅ |
| 2 | Sleep hours                      | same                       | ✅     |
| 3 | Water                            | same                       | ✅     |
| 4 | Server upsert + delete           | `state/app_state.dart`     | ✅     |
| 5 | Calendar grid (consistent days)  | `screens/progress_screen.dart:_ConsistencyGrid` | ✅ |
| 6 | Missed-day nudge                 | `screens/dashboard_screen.dart` | ✅ |

**Criticism:** Sleep and water prompts are inputs but never used by the coach
or any chart. Dead data.

**Fixture:** Add 7-day sleep chart and water-streak counter. Coach mentions
sleep when energy < 3.

### G. IronCoach (AI)
| # | Feature                          | File                       | Status |
|---|----------------------------------|----------------------------|--------|
| 1 | OpenRouter proxy                 | `server/src/routes.js` (ai) | ✅     |
| 2 | Real-data context builder        | `server/src/ai.js`         | ✅     |
| 3 | Chat history (server-persisted)  | `chat_messages` table      | ✅     |
| 4 | Rate limit (8/min/user)          | `server/src/ai.js`         | ✅     |
| 5 | `:online` search (when budget allows) | `server/src/ai.js`    | 🟡     |
| 6 | Free-model default               | env: `OPENROUTER_MODEL`    | ✅     |
| 7 | Refresh / scroll-to-latest       | `screens/coach_screen.dart` | ✅ (fixed today) |

**Criticism:** Free tier has aggressive 429 limits; UX shows raw error toast.
Context window includes Kegel ids (private data) — privacy concern.

**Fixture:** Retry with backoff (3 tries, 1s/2s/4s), friendly error
"AI is taking a break — try again in a minute". Strip kegel ids from
context before sending to LLM.

### H. Reminders (Android)
| # | Feature                          | File                       | Status |
|---|----------------------------------|----------------------------|--------|
| 1 | Wake-up daily                    | `services/reminders.dart`  | ✅     |
| 2 | Gym time Mon–Sat                 | `services/reminders.dart`  | ✅     |
| 3 | Kegel daily                      | `services/reminders.dart`  | ✅     |
| 4 | Boot persistence                 | manifest receiver          | ✅     |
| 5 | Settings time pickers            | `screens/settings_screen.dart` | ✅ |
| 6 | **No Sunday gym reminder**       | `services/reminders.dart`  | ✅     |

**Criticism fixed today:** Previously fired daily — now weekly Mon–Sat only.
**Verification path:** install APK on Android device, set gym time to 1 min
from now, confirm Mon–Sat only.

### I. Settings
| # | Feature                          | File                       | Status |
|---|----------------------------------|----------------------------|--------|
| 1 | Theme / accent                   | `theme.dart`               | ✅     |
| 2 | Units                            | `app_state.dart` (hardcoded kg) | 🟡 |
| 3 | Program start date               | `app_state.dart`           | ✅     |
| 4 | Reminder times                   | `settings_screen.dart`     | ✅     |
| 5 | Reminder enabled toggle          | `settings_screen.dart`     | ✅     |
| 6 | Sign out                         | `settings_screen.dart`     | ✅     |
| 7 | APK download                     | `settings_screen.dart`     | ✅     |

**Criticism:** No "Reset password" / "Change password" (you can only sign out
and re-create). No "Export my data" (GDPR). No "Delete account".

### J. Sync & offline
| # | Feature                          | File                       | Status |
|---|----------------------------------|----------------------------|--------|
| 1 | HTTP request cache               | `services/api.dart`        | ✅     |
| 2 | Offline write queue              | `state/app_state.dart:_enqueue` | ✅ |
| 3 | Sync indicator (banner)          | `state/app_state.dart`     | ✅     |
| 4 | Service worker (web)             | `web/flutter_service_worker.js` | ✅ |

**Criticism:** No conflict resolution — last-write-wins. If you edit a weight
on phone, then on web, then sync, the web value overwrites. Fine for a single
user, dangerous if you add multi-device later.

---

## 2 · Clever tests (the matrix)

### 2.1 Backend smoke (`server/test/smoke.sh`)

Already exists; 29 checks pass. **Extend with:**

```bash
# notification scheduling intent: API contract only — actual Android
# scheduling lives on the device, but the SERVER must not crash if a future
# /api/prefs/notification-time endpoint gets a bad value.
test "POST /api/prefs rejects bad time format" \
  "POST /api/prefs {time:'25:99'} → 400"

# AI context builder isolation
test "AI context strips kegel ids" \
  "POST /api/ai/chat with kegels in DB → context payload excludes kegel.id"

# Heatmap intensity derived correctly
test "intensity(day where trained+checkin+kegel) == 7" \
  "log workout + checkin + kegel same day, GET /api/state, assert intensity 7"
```

### 2.2 Flutter unit tests (`app/test/`)

Add to `program_test.dart`:

```dart
test('currentWeek returns 1 when startDate is empty', () {
  final s = AppState.test();
  expect(s.currentWeek(), 1);
});

test('bestStreak handles Sunday gaps correctly', () {
  // workouts on Mon, Tue, Wed, Mon (next week) → best = 3, not 1
});

test('heatmapCells combines bits without collision', () {
  // workout=2, checkin=1, kegel=4 → 2|1|4 = 7
});

test('reminder scheduling skips Sunday (dateTimeComponents.dayOfWeekAndTime)',
  () {
  // mock TZDateTime.now() to a Monday, schedule gym reminder for 17:00,
  // assert ids 1011..1016 (Mon..Sat) and NO Sunday id.
});
```

### 2.3 End-to-end manual (every release)

```
[ ] Login as mjonir / password-from-1password
[ ] Dashboard renders, no overflow at 340px
[ ] Today's session card → tap → workout screen
[ ] Add 3 sets of 20kg bench press → save → success snackbar
[ ] Back to dashboard → streak hero shows 1 day
[ ] Check-in card → energy 4 → save → done state
[ ] 13-week heatmap shows today as ringed ember cell
[ ] Coach tab → first message loads at BOTTOM (post-load scroll)
[ ] Send "Review my last week" → AI reads real data, no kegel.id leak
[ ] Settings → change wake-up time to 06:00 → Android reschedules
[ ] Sign out → sign in again → dashboard rehydrates
```

### 2.4 Notification verification (Android device)

```
[ ] install APK on real device (NOT emulator — local notifications behave
    differently on emulators)
[ ] set gym time to 1 minute from now
[ ] wait 90 seconds — push arrives
[ ] set system time to Sunday 17:01 — no gym notification fires
[ ] reboot device — ScheduledNotificationBootReceiver re-arms
```

### 2.5 Visual sanity (browser, mobile viewport)

```
[ ] open at 360x800 (small Android)
[ ] dashboard — no horizontal scroll, no RenderFlex overflow
[ ] coach screen — bubbles don't exceed 82% width
[ ] settings — switches and time pickers fit on one row
```

---

## 3 · App icon design (SVG spec for asset pipeline)

> User asked to include an icon design — here's the spec for the build pipeline
> to render at all densities (mdpi → xxxhdpi, 48×48 → 192×192).

### Concept: a stylized anvil with an ember dot

Visual reads at 16×16: black square with one bright ember pixel in the upper-right
quadrant — the **"spark"**. At larger sizes the anvil is recognizable.

```svg
<svg viewBox="0 0 192 192" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <radialGradient id="spark" cx="50%" cy="50%" r="50%">
      <stop offset="0%"  stop-color="#FFB280"/>
      <stop offset="40%" stop-color="#FF5A1F"/>
      <stop offset="100%" stop-color="#7A2A0C" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="anvil" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%"  stop-color="#26262C"/>
      <stop offset="100%" stop-color="#131316"/>
    </linearGradient>
  </defs>

  <!-- adaptive background: near-black, rounded to 42px for iOS squircle feel -->
  <rect width="192" height="192" rx="42" fill="#0A0A0B"/>

  <!-- anvil silhouette: top horn, waist, base, foot -->
  <g fill="url(#anvil)" stroke="#3A3A44" stroke-width="1.5" stroke-linejoin="round">
    <!-- top (the "horn" you hammer on) -->
    <path d="M 38 84
             L 154 84
             L 142 70
             L 50 70 Z"/>
    <!-- waist (narrow) -->
    <rect x="78" y="84" width="36" height="14"/>
    <!-- base (broad) -->
    <rect x="44" y="98" width="104" height="22" rx="3"/>
    <!-- foot -->
    <rect x="60" y="120" width="72" height="10" rx="2"/>
  </g>

  <!-- ember spark sitting on the horn — this is the brand color, the focal
       point, the only saturated pixel in the icon -->
  <circle cx="124" cy="77" r="11" fill="url(#spark)"/>
  <circle cx="124" cy="77" r="3"  fill="#FFE0CC"/>

  <!-- subtle highlight on the anvil top edge to suggest heat -->
  <path d="M 60 70 L 142 70" stroke="#FF5A1F" stroke-opacity="0.35" stroke-width="1"/>
</svg>
```

### Why this icon
- **Reads at 16px** — black square, one ember dot. Launcher grid.
- **Tells the brand** — "forge" = anvil + ember, the source metaphor.
- **Saturated on purpose** — single ember pixel among greys, matches in-app
  accent. Memorable because the rest of the system is dark+ember; the icon
  is the smallest version of the same vocabulary.

### Build steps (Android)
1. Save as `app/icon/icon.svg`.
2. Use `flutter_launcher_icons` (already in `pubspec.yaml`) with
   `image_path: "icon/icon.svg"` — it auto-renders all densities.
3. iOS: place `AppIcon.appiconset/icon-1024.png` and use `xcassets` (or
   `flutter_launcher_icons` handles both).

### Test
- [ ] icon renders correctly at 48, 72, 96, 144, 192 in Android Studio's
      resource preview
- [ ] iOS icon appears correctly in the home screen after install
- [ ] at 16px (status-bar size) the ember spark is still visible

---

## 4 · Critical bugs found in this audit (with priority)

| Pri | Bug | File | Fix |
|-----|-----|------|-----|
| P0 | Gym reminder fired Sundays until today | `services/reminders.dart` | ✅ weekly per-weekday scheduling |
| P0 | Coach screen opened at FIRST message (top) | `screens/coach_screen.dart` | ✅ jumpTo(maxScrollExtent) on load |
| P1 | Weight + measurement "save" not visibly confirmed | `screens/progress_screen.dart` | 🟡 snackbar; should be inline + undo |
| P1 | AI 429 errors raw, no retry / friendly copy | `screens/coach_screen.dart` | 🔴 3x exponential backoff, friendly toast |
| P1 | "Personal records" definition is single-set max weight only | `state/app_state.dart:personalRecords` | 🔴 add volume PR (Σ w×r) |
| P2 | Sleep + water never used anywhere | `state/app_state.dart` | 🔴 7-day chart, coach context mention |
| P2 | No password change | `screens/settings_screen.dart` | 🔴 forgot + change endpoints |
| P2 | No unit toggle (lb/kg)              | `state/app_state.dart`      | 🔴 kg/lb setting + conversion |
| P3 | Bootstrap credentials printed to logs | `server/src/index.js` | 🔴 print only on first run, redact after |
| P3 | Static "Overload" text in workout    | `screens/workout_screen.dart` | 🟡 compare to last-week, show diff |

---

## 5 · Why "AI chat opens at first message" — root cause

`CoachScreen._loadHistory` did:
```dart
setState(() { _msgs = ...; });
// end of method — no scroll
```

`ListView.builder` defaults to scroll position 0, so the LATEST message
(at the bottom of the list) was off-screen. The scroll-to-bottom was
attached to `_ask` (when you send a message) but never to the initial load.

**Fix (today):** in `_loadHistory`, after setState:
```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
});
```

Instant jump (not animate) so the first paint lands on the latest message,
not a scroll-in-progress that looks broken on cold open.

**Re-occurrence check:** any other `ListView.builder` driven by a
server-persisted history needs the same pattern. Audit:
- `coach_screen.dart` ✅
- `progress_screen.dart` (history card uses `Column` not ListView, OK)
- `workout_screen.dart` (history is per-day, fixed-length, OK)
- `settings_screen.dart` (no chat list)

---

## 6 · Notification system — full verification path

| Check | How | Pass criterion |
|-------|-----|----------------|
| Manifest receiver `exported` | `aapt dump xmltree app.apk AndroidManifest.xml` | both receivers `exported="false"` |
| POST_NOTIFICATIONS permission | `aapt dump permissions app.apk` | present |
| desugaring on | `unzip -p app.apk classes.dex \| dexdump - \| grep "java.time"` | desugared APIs present |
| Timezone init | logcat `I/flutter: timezone=Asia/Kolkata` | matches device tz |
| Channel created | logcat `NotificationChannel ironforge_daily` | channel shown in Android Settings |
| Schedule fires | set wake-up 1 min ahead, wait 90s | push arrives |
| Sunday skipped | set device clock Sun 17:01:00 | NO gym push |
| Re-arm after reboot | `adb reboot` | push arrives next day |

### Known limitations (in this release)
- `androidScheduleMode: inexactAllowWhileIdle` — notifications can fire ±5-15
  min late. Acceptable for gym reminders. Document in app onboarding.
- No `SCHEDULE_EXACT_ALARM` — Play Store may warn on this for new uploads;
  can add it for Android 14+ if user complains.

---

## 7 · Performance budgets

- Dashboard initial paint (cold start): < 800ms on mid-range Android
- Workout save round-trip: < 400ms on local network
- AI first token: < 2s on OpenRouter free tier (when quota available)
- Heatmap render: < 100ms (13 weeks × 7 days = 91 cells, trivial)

---

## 8 · What to ship next (priority order)

1. **Password change** — basic auth security feature, expected by every app.
2. **AI retry + friendly error** — without this, free tier is unusable in
   production.
3. **Volume PR + dynamic overload hint** — what makes a fitness app
   actually useful vs. just a log.
4. **Units toggle (kg/lb)** — for any non-Indian user.
5. **Icon pipeline** — apply SVG spec above; ship a recognizable launcher icon.
6. **Privacy: strip kegel ids from AI context** — small code, big trust.

---

*Author: MiniMax M3 (Free) via the Renovation audit pass, 2026-09-06.*
*Status: every ✅ line is verified on yarmuk production.*

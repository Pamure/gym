# IRONFORGE — Professional Execution Plan (Fresh Start)

## User Context Lock (immutable reference)
- Name/handle: 68kg beginner male, age 18-22, height <5'7", healthy (no injuries)
- Gym: UFC-style gym (Punjabi Bagh / Okhla Vihar area reference); CLOSED SUNDAY
- Location: Delhi, India (Okhla Vihar reference area)
- Start date: 21 September 2026 (Monday) — NOT 7 Sep; user will adjust manually later
- Diet budget: ~200 INR/day (Okhla Vihar market pricing)
- Experience: 5-10 home pushups only; complete beginner
- Goals (priority order): stamina > aesthetic/body posture > strength/muscles > core > flexibility > kegels > sexual health
- Trainer split (BAD — must be documented with misspellings preserved):
  - "Flate bench", "Dumble", "Prichaire curl" (preacher misspelled), "Pully", "Roughf nd toughf", "Pron Leg curl", "Pack deck fly"
  - No rest days (Mon-Sat only, no Sunday mention, no full body)
  - Zero kegels, zero core, zero posture, zero stamina/cardio, zero flexibility
- Previous state: quick logout bug, broken GIF animations, weak notifications, no punishment mechanism

## Phase P0 — Plan & Architecture (this file + git tracking)
P0.1 Write this plan.md
P0.2 Initialize git, baseline commit
P0.3 Define sub-sub-task tracking format (each has: ID, description, verification method, commit hash target)
P0.4 Lock user context into AI system prompt / knowledge base
P0.5 Lock start date to 21 Sep 2026 in production DB

## Phase P1 — Diet Feature (the #1 new feature, 500+ Indian foods)
P1.1 Research common Indian food prices (Okhla Vihar / Delhi market reference)
P1.2 Build Indian food database: 500+ entries with:
  - food name (English + Hindi transliteration where common)
  - category: protein / carb / fat / mixed / vegetable / dairy / legume / fruit
  - image URL (free stock / Wikimedia / open source — must work in production)
  - nutritional profile per 100g: protein (g), carbs (g), fat (g), calories (kcal)
  - common portion weights (e.g., "1 chicken breast ~150g", "1 cup paneer ~150g", "1 roti ~30g")
  - approximate Okhla Vihar market price per unit (INR)
P1.3 Implement fuzzy search backend (SQLite full-text or simple LIKE with ranking)
P1.4 Implement diet calculator: given budget (200 INR), design today's diet showing:
  - selected foods
  - portions in grams
  - total protein / carbs / calories / cost
  - verification that total cost ≤ budget
P1.5 Add images that actually load (test each URL in browser)
P1.6 Document the AI knowledge: the AI knows all 500 foods + their profiles + pricing logic

## Phase P2 — Routine Redesign (replacing bad trainer split)
P2.1 Document trainer's bad split (with exact misspellings) in app screen
P2.2 Design science-based HYBRID full-body beginner routine (3 days/week) combining:
  - Compound lifts (squat, deadlift, bench, pull, overhead press)
  - Stamina/cardio integration (Zone 2, farmer's carry)
  - Core/posture (dead bug, bird-dog, plank)
  - Kegels (pelvic floor training with correct technique notes)
  - Flexibility (World's Greatest Stretch, couch stretch, cat-cow)
P2.3 Write new routine in app and document: "AI-designed hybrid routine" vs "Trainer split (with errors noted)"
P2.4 Build 3-phase progression (Month 1: form/learning, Month 2: overload, Month 3: consolidation)

## Phase P3 — App Fixes (persistent auth, GIFs, notifications, punishment)
P3.1 Fix quick logout: localStorage session persistence (cookie + localStorage mirror)
P3.2 Fix broken GIF animations: verify all URLs load, replace broken sources with working ones (GymVisual, RepDB, GIPHY, Tenor, Wikimedia)
P3.3 Make notifications stricter: daily reminder for 6-day target (Mon-Sat, skip Sunday per gym close), increase from 1/day to 2/day (morning prep + evening reminder)
P3.4 Add punishment mechanism: if user misses 6-day workout target for a week, app shows "Penalty: +1 extra set next workout" or "Streak reset notification" — implemented as visual/text punishment in UI
P3.5 Update reminder scheduling to skip Sunday (use DateTimeComponents.dayOfWeekAndTime properly)

## Phase P4 — AI Knowledge Base Integration
P4.1 Update AI system prompt / context file with:
  - Full user profile (68kg, 18-22, <5'7", beginner, non-veg, 5 days, 60 min, healthy)
  - Full gym profile (UFC-style, Punjabi Bagh reference, no Sunday, equipment list: octagon, boxing bags, BJJ mats, Olympic platforms, free weights, cardio, turf)
  - Full routine knowledge (hybrid A/B/C + trainer split comparison)
  - Full diet database (500+ Indian foods, pricing, budget logic)
  - Full goal hierarchy (stamina > posture/aesthetics > strength > core > flexibility > kegels > sexual health)
P4.2 Make AI responses reference the correct context (not generic fitness advice)

## Phase P5 — Subagent Critics (routine evaluation)
P5.1 Create subagent A: "Strength & Hypertrophy Critic" — reviews if compound selection is optimal for beginner
P5.2 Create subagent B: "Stamina & Conditioning Critic" — reviews if Zone 2/cardio integration is sufficient
P5.3 Create subagent C: "Posture & Core Critic" — reviews if dead bugs/bird-dog/plank progression is correct for posture correction
P5.4 Create subagent D: "Diet & Nutrition Critic" — reviews budget meal design for 200 INR/day at Okhla Vihar prices
P5.5 Create subagent E: "Sexual Health / Kegel Critic" — reviews if pelvic floor integration is scientifically sound
P5.6 Aggregate good criticism only; discard noise; document which recommendations were adopted/rejected

## Phase P6 — Testing & Verification (rigorous, 3x)
P6.1 Frontend browser test: load diet feature, test fuzzy search, verify all food images load, test budget calculator (200 INR), verify buttons respond
P6.2 Frontend browser test: verify auth persistence (login, refresh page, still logged in), verify notification settings
P6.3 Frontend browser test: verify GIF animations play, verify routine display shows both AI routine and trainer split with misspellings noted
P6.4 Backend test: diet search endpoint returns correct results, budget calculator returns accurate totals
P6.5 Backend test: reminder scheduling skips Sunday, auth endpoint works, settings endpoint validates schema
P6.6 Verify program start date is set to 21 Sep 2026 (not 7 Sep)
P6.7 Verify punishment mechanism displays correctly when simulated miss
P6.8 Verify AI responds with context-aware answers (not generic)

## Phase P7 — Deploy & Final Verification
P7.1 Build web release (flutter build web)
P7.2 Build APK (flutter build apk --release)
P7.3 Copy APK to server/downloads
P7.4 Deploy (bash deploy/deploy.sh)
P7.5 Verify live URL serves updated app
P7.6 Final git commit: "P7 FINAL: deployed with diet feature + all fixes + verification"
P7.7 Report to user with verification proof

## Sub-Sub-Task Format (every task must have)
- ID (e.g., P1.1)
- Description (1 line max)
- Verification: [exact command/test/observation]
- Commit target hash
- Status: [pending / in-progress / verified / deployed]

## Professional Principles (locked)
1. No unnecessary complexity — every feature earns its place
2. Every claim must have evidence (code inspection, live browser check, or data source)
3. Every change is a git commit with descriptive message
4. No generic AI answers — context-locked
5. Test 3x before declaring complete

# IronForge overnight work plan

**Scope lock:** work only inside `/home/quilt/f/projects/gym`; never deploy or push without the owner's explicit approval.

## Product direction

Build a calm beginner companion for a first gym visit in Delhi. The canonical schedule is three full-body strength sessions (Mon/Wed/Fri), optional easy movement on Tue/Thu/Sat, and Sunday rest. The app should answer, in order: what is today, where is the equipment, how do I set it up, what does a good rep look like, how long do I rest, what can I do if it is busy, and how do I record it.

## Work items and verification

| ID | Work | Verification | Status |
|---|---|---|---|
| P0 | Clone repo into `/home/quilt/f/projects/gym` | `git status`, path inspection | done |
| P1 | Read app, server, knowledge folder and original coach plan | audit in `renovation.md` | done |
| P2 | Research evidence and Android limits | source list in `renovation.md` and `knowledge/01-training-program.md` | done |
| P3 | Repair typed offline diet data | `flutter analyze` has no diet parse errors | done |
| P4 | Replace first-week split with a simple canonical plan | `app/test/program_test.dart` | done |
| P5 | Add machine/form/alternative guidance | inspect expanded Workout card; catalog test | done |
| P6 | Fix local sync, duplicate logs and session/logout behavior | Flutter tests + code review; device follow-up | done |
| P7 | Fix Android reminder IDs, exact-alarm request and Sunday policy | analyze/build + real Android test | done |
| P8 | Align dashboard, Settings, Learn and IronCoach copy | source audit | done |
| P9 | Run full Flutter/server checks and fix regressions | Flutter analyze/test, web + APK build, server smoke/audit | done |
| P10 | Morning owner review; only then decide on build/deploy/push | explicit owner approval | pending |
| P11 | Fix preview rendering/theme/video/permission UX regressions | gradient fix, navy/teal theme, web video fallback, Android permission flow | done |
| P12 | Run critic pass on screenshots, browser/API preview and training plan | `renovation.md` critic report; no deploy/push | done |

## Commands

```bash
cd /home/quilt/f/projects/gym/app
/home/quilt/development/flutter/bin/flutter pub get
/home/quilt/development/flutter/bin/flutter analyze
/home/quilt/development/flutter/bin/flutter test

cd /home/quilt/f/projects/gym/server
npm install
# run smoke in a separate shell with a compatible Node/native dependency build
npm start
npm run smoke
```

## Safety decisions

- No punishment, extra sets, or guilt for missed workouts.
- No behind-the-neck pulldown/press recommendation.
- No medical diagnosis or claim that an exercise is universally safe.
- Exact 06:30 alarms are best-effort and require user-controlled Android permissions.
- Workout logging rejects blank/zero-rep sets; zero load is allowed only as an unloaded movement.
- The app does not pretend the local food list contains 500 verified foods.

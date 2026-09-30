# IronForge Flutter client

IronForge is a beginner-first gym companion for Android and web. It shows a
three-day full-body strength plan, optional easy movement, equipment/form
instructions, exercise alternatives, set logging, progress and reminders.

## Run locally

```bash
flutter pub get
flutter run
```

For the web outlet, the supported deployment topology is the Flutter web build
served by the Fastify server in `../server`; web reminders are not native push
alarms. Android reminders require notification permission and optionally
Alarms & reminders access for a more precise 06:30 notification. Android may
still delay or silence notifications due to battery settings or Do Not Disturb.

## Checks

```bash
flutter analyze
flutter test
flutter build web --release
flutter build apk --debug
```

The release APK must be configured with a real signing keystore before public
distribution. Do not deploy or push a build without reviewing the repository
diff and the audit in `../renovation.md`.

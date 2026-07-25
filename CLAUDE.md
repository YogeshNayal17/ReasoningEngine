# Project Philosophy

- Simplicity over cleverness.
- Readability over optimization.
- Every feature should compile before moving on.
- Never generate unused code.
- Never create placeholder services.
- Keep commits small.
- Explain architectural tradeoffs.
- Ask before introducing a new dependency.
- Prefer composition over inheritance.
- Minimize platform-specific code by isolating Android-specific functionality behind interfaces where practical.
- Do not assume anything, ask questions in case of any doubts. Restrict to max 5 questions.

# Testing & Build Workflow

- Don't do a full APK rebuild + reinstall for trivial or Dart-only changes
  (typos, comments, widget/logic tweaks). Use `flutter analyze` and
  `flutter test` for verification — they run in seconds and need no device.
  A full `flutter build apk` + install is only actually required when
  native Android files change (Kotlin, AndroidManifest.xml, Gradle files,
  `res/`), since those aren't hot-reloadable.
- For on-device/manual verification (native UI, permissions, gestures,
  anything a unit/widget test can't cover), don't drive my phone via adb
  screenshots yourself. Instead, write a clear step-by-step manual test
  guide (what to tap, what to expect at each step) and let me run it and
  report back.
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

# Developer Notes

After every prompt response, update `developer_notes.xlsx` in the repo root.
This Excel workbook is the living technical reference for the project.

## Sheets

| Sheet | Purpose |
|---|---|
| Functional Requirements | Every user-facing feature (FR-xxx IDs) |
| Non-Functional Requirements | Security, reliability, performance (NFR-xxx) |
| Stack | All technologies, libraries, and versions |
| Frontend | Flutter/Dart implementation details |
| Backend | FastAPI/Python implementation details |
| DB | SQLite table/column reference |
| Key Design Decisions | Architectural choices and their rationale |
| Environment Variables | All .env variables with purpose and defaults |
| Active Bugs | Known unresolved issues (BUG-xxx) |
| Resolved Bugs | Fixed issues with root cause and fix (RBUG-xxx) |

## Update rules

- Every row has **Created Date** and **Modified Date** columns (YYYY-MM-DD).
- **Do not add a new row** if an existing row covers the same fact — update the existing row and change Modified Date only.
- Add a new row only for a genuinely new fact, feature, bug, or decision.
- When a bug is fixed, move its row from Active Bugs to Resolved Bugs and set Resolved Date.
- When a requirement or design decision changes, update the existing row (not a new one).
- Use the backend venv Python to run the update script if regenerating from scratch:
  `.\venv\Scripts\python.exe create_dev_notes.py` (from `backend/`)

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
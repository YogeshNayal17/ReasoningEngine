# Environment configuration

Per-environment values (API base URL, feature flags, ...) are injected at
**build time** via Flutter's `--dart-define-from-file`, not loaded from a
bundled `.env` asset at runtime.

Why: a bundled `.env` file ships inside the compiled app (readable by
anyone who unzips the APK) and requires a runtime read + parse before the
app can configure itself. `--dart-define-from-file` values are baked in by
the compiler as `String.fromEnvironment`/`bool.fromEnvironment` constants —
nothing to parse, nothing extra in the bundle, and the values are available
before `main()` even runs.

## Usage

```bash
flutter run --dart-define-from-file=env/dev.json
flutter build apk --dart-define-from-file=env/prod.json
```

`lib/core/config/app_environment.dart` reads these into a typed
`AppEnvironment`, exposed via `appEnvironmentProvider` so the rest of the
app depends on the provider rather than reading defines directly.

## Adding a new environment or value

1. Add the key to every `env/*.json` file (missing keys silently fall back
   to the default in `AppEnvironment.fromDartDefines`, which can hide
   misconfiguration — keep the files in sync).
2. Add the corresponding field to `AppEnvironment`.

## Secrets

`dev.json` / `prod.json` currently hold no secrets, so they're committed.
If an API key or similar is added later, put it in a `env/<name>.local.json`
instead (already covered by `.gitignore`) and document the required keys
here rather than committing real values.

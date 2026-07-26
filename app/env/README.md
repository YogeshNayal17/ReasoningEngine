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

## Reaching the backend from a physical device

`dev.json`'s `API_BASE_URL` is `http://127.0.0.1:8000` — that's the
**device's own** loopback, not your development machine's. It only works
paired with:

```bash
adb reverse tcp:8000 tcp:8000
```

which forwards the connected device's port 8000 to your machine's port
8000 over the existing USB connection. This is why `127.0.0.1` was chosen
over `10.0.2.2` (the Android *emulator's* alias for host loopback, which
doesn't apply to a real device) or a LAN IP (which would need the phone
and dev machine on the same network, and the backend bound to `0.0.0.0`
instead of its default `127.0.0.1`). Re-run the `adb reverse` command
whenever the device reconnects — the mapping doesn't persist across USB
disconnects.

## Secrets

`dev.json` / `prod.json` currently hold no secrets, so they're committed.
If an API key or similar is added later, put it in a `env/<name>.local.json`
instead (already covered by `.gitignore`) and document the required keys
here rather than committing real values.

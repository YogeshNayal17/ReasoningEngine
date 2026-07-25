# Reason AI — Flutter client

## Setup

This project was authored without the Flutter SDK available in the
authoring environment, so the native `android/` platform folder has **not**
been generated yet. That's a deliberate call, not an oversight: `flutter
create` templates (Gradle/AGP/Kotlin versions, namespace wiring, etc.) are
generated from whatever Flutter SDK is installed, and hand-writing that
boilerplate to match a version I can't verify against is a good way to
introduce subtle build breakage. It's one command to fix:

```bash
# 1. Install the Flutter SDK (stable channel) if you haven't:
#    https://docs.flutter.dev/get-started/install
flutter doctor

# 2. From this app/ directory, backfill the Android platform folder.
#    This reads the existing pubspec.yaml and only adds the missing
#    platform files — it will not touch lib/ or pubspec.yaml.
flutter create . --platforms=android --org com.reasonai

# 3. Fetch packages.
flutter pub get

# 4. Run against the local backend (Android emulator → host machine).
flutter run --dart-define-from-file=env/dev.json
```

Only the `android` platform is generated — see the platform-scope note in
the root `README.md` for why iOS isn't part of this project yet.

`com.reasonai` is a placeholder org/applicationId. Change it (via the
`--org` flag above, before generating `android/`, or by editing
`android/app/build.gradle` afterward) once the real domain/company name is
final — the Android `applicationId` is effectively permanent after the
first Play Store release.

**Verification note:** `flutter analyze` and `flutter test` have not been
run against this code (no Flutter SDK in the authoring sandbox). Please run
both after step 3 and report anything that fails — the most likely trouble
spot is exact package API surfaces (`flutter_riverpod` 3.3.2, `go_router`
17.3.0) drifting from what's used here.

## Architecture

Feature-first, with a small shared core. Each feature will eventually own
its own `data/` / `domain/` / `presentation/` layers, but those only get
created when a feature actually has logic to put in them — there's no
`home/data/` or `home/domain/` yet because `home` is a static placeholder
screen.

```
lib/
├── main.dart, app.dart        Composition root: ProviderScope, MaterialApp.router
├── core/                      Cross-cutting infrastructure, no feature knowledge
│   ├── config/                Build-time environment (AppEnvironment)
│   ├── logging/                AppLogger interface + console implementation
│   ├── router/                 GoRouter setup + route path constants
│   ├── theme/                  Material 3 ThemeData
│   ├── error/                  AppFailure hierarchy
│   └── utils/                  Result<T> — shared functional error handling
├── features/
│   └── home/presentation/      First (placeholder) feature slice
└── shared/widgets/             Reusable UI atoms (PrimaryButton, ...)
```

### Dependency injection: Riverpod, not a service locator

Providers *are* the DI mechanism. `appEnvironmentProvider` and
`appLoggerProvider` are defined next to the class they provide (e.g.
`core/logging/app_logger.dart`), and consumers `ref.watch()` them rather
than constructing dependencies directly. This gives constructor-injection-
style testability (override any provider in a `ProviderScope` in tests)
without maintaining a second DI container (get_it/injectable) alongside
Riverpod — two overlapping DI systems would be pure accidental complexity.

### Logging is behind an interface, config is not

`AppLogger` is an abstract class wrapping the `logger` package — this
abstraction earns its keep because the backend *will* change (console today,
almost certainly Sentry/Crashlytics once there are real users). `AppEnvironment`,
by contrast, is a concrete class with no interface: there's only ever one
real implementation of "where do config values come from," so an interface
there would be abstraction for its own sake.

### Result<T> over exceptions for expected failures

`core/utils/result.dart` defines a sealed `Result<T>` (`ResultSuccess` /
`ResultError`) for operations that can fail in expected ways (network
errors, OCR failures, ...). This is the one piece of "future-facing"
infrastructure included before any repository exists to use it, because
retrofitting error handling style onto every repository/data source after
the fact is far more disruptive than deciding on it once, up front. Nothing
uses it yet — that's expected until Milestone 5+ (OCR) / Milestone 6+
(backend calls) add the first repositories.

### Linting

`analysis_options.yaml` extends `flutter_lints` and turns on
`strict-casts` / `strict-inference` / `strict-raw-types` in the analyzer,
plus a small set of additional lints (`avoid_dynamic_calls`,
`unawaited_futures`, etc.) that catch the kinds of bugs that are cheap to
prevent and expensive to debug on a device (unawaited futures silently
swallowing errors, implicit `dynamic`).

# Reason AI — Flutter client

## Setup

```bash
flutter pub get
flutter run --dart-define-from-file=env/dev.json
```

Only the `android` platform is generated — see the platform-scope note in
the root `README.md` for why iOS isn't part of this project yet.

`com.reasonai` is a placeholder org/applicationId (set in
`android/app/build.gradle.kts`). Change it before the first Play Store
release — the Android `applicationId` is effectively permanent afterward.

Every milestone in this repo is verified the same way before being
committed: `flutter analyze`, `flutter test`, a debug build
(`flutter build apk --debug --dart-define-from-file=env/dev.json`)
installed on a physical device, and for native-UI features, manual
on-device exercise of the actual behavior (not just "it compiled").

## Architecture

Feature-first, with a small shared core. Each feature will eventually own
its own `data/` / `domain/` / `presentation/` layers, but those only get
created when a feature actually has logic to put in them — there's no
`home/domain/` because `home` is just a thin screen that composes other
features' widgets.

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
│   ├── home/presentation/      Landing screen; composes feature widgets
│   └── overlay/                Floating bubble control (data + presentation)
└── shared/widgets/             Reusable UI atoms (PrimaryButton, ...)

android/app/src/main/kotlin/com/reasonai/reason_ai/
├── MainActivity.kt             Registers platform channels; nothing else
└── overlay/                    OverlayService, OverlayBubbleController,
                                 OverlayMethodChannelHandler
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

### Milestone 2: the overlay bubble is native, not Flutter

The floating bubble is a plain Android `View` added directly to the
`WindowManager` from a foreground `Service` (`android/.../overlay/`) —
Flutter has no concept of "a window that floats over every other app,"
so this piece can't be Flutter UI. Two choices worth calling out:

- **No third-party overlay plugin.** Packages exist that wrap this
  pattern, but the bubble tap → capture → reasoning flow is this
  product's entire differentiator, so owning the ~150 lines of
  `WindowManager`/`Service` code directly — rather than depending on a
  small, often loosely-maintained plugin for the most load-bearing
  feature in the app — was worth the trade. It also meant no new pub.dev
  dependency for this milestone.
- **A native `View`, not a `FlutterView` embedded in the overlay window.**
  Some plugins render Flutter widgets inside the overlay by running a
  second `FlutterEngine` inside the `Service`. That buys UI-code reuse at
  the cost of a second engine's lifecycle/memory to manage inside a
  long-lived service — unjustified complexity for a bubble that's just an
  icon, a drag gesture, and an expand/collapse panel. WhatsApp/Messenger
  chat-heads use the same plain-`View` approach for the same reason.

**Dart ↔ native contract:** a single `MethodChannel`
(`com.reasonai.reason_ai/overlay`), wrapped by `OverlayBridge`
(`features/overlay/data/overlay_bridge.dart`) so nothing outside that one
file touches a `MethodChannel` directly — this is the "isolate
Android-specific functionality behind an interface" principle from
`CLAUDE.md` applied directly. `OverlayController` (Riverpod `Notifier`)
calls it and exposes `hasPermission`/`isRunning` state to
`OverlayControlPanel`. Because granting the overlay permission happens in
a system Settings screen outside the app, the panel re-checks state via
`WidgetsBindingObserver.didChangeAppLifecycleState` on every resume —
polling would work too, but resume is the only moment the state can
actually have changed.

**`minSdk` raised to 26.** `WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY`
(the modern, non-deprecated overlay window type) requires API 26+; below
that you need the deprecated `TYPE_PHONE`. Targeting 26+ only avoids
maintaining that legacy branch for a vanishingly small slice of active
devices.

**Foreground service, `specialUse` type.** The bubble has to survive the
host app backgrounding, which is exactly what a foreground service is
for — its lifecycle is independent of `MainActivity`. On API 34+, Android
requires every foreground service to declare a type; none of the
predefined categories (`mediaPlayback`, `location`, `camera`, ...) fit "a
persistent screen overlay," so this uses `specialUse`, the category Google
added for exactly this kind of case, with a `PROPERTY_SPECIAL_USE_FGS_SUBTYPE`
justification string for Play Console review.

**What's genuinely done vs. what's future-proofed.** Drag, tap-to-expand/
collapse, and a close button are real, working features — not stand-ins.
What's *not* here yet, on purpose, is any capture trigger: adding one in
Milestone 3 means adding a button to `OverlayBubbleController`'s expanded
panel and a new `OverlayMethodChannelHandler` branch, without restructuring
either. Building a disabled "Capture" button now would have been dead code
per `CLAUDE.md`'s "never create placeholder services" — so it isn't there.

### Linting

`analysis_options.yaml` extends `flutter_lints` and turns on
`strict-casts` / `strict-inference` / `strict-raw-types` in the analyzer,
plus a small set of additional lints (`avoid_dynamic_calls`,
`unawaited_futures`, etc.) that catch the kinds of bugs that are cheap to
prevent and expensive to debug on a device (unawaited futures silently
swallowing errors, implicit `dynamic`).

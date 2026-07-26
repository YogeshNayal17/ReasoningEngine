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
│   ├── overlay/                Floating bubble permission/toggle (data + presentation)
│   ├── capture/                Capture permission only — selection UI is native now
│   └── ocr/                    On-device text recognition (data + presentation)
└── shared/widgets/             Reusable UI atoms (PrimaryButton, ...)

android/app/src/main/kotlin/com/reasonai/reason_ai/
├── MainActivity.kt             Registers platform channels; checks/opens the
│                                accessibility-service permission (no in-app
│                                consent dialog is possible for that kind of
│                                permission, unlike the MediaProjection flow
│                                this replaced)
├── overlay/                    OverlayService, OverlayBubbleController,
│                                BubbleMenuOverlayController, SelectionCanvasView,
│                                SelectionOverlayController, OverlayMethodChannelHandler
└── capture/                    CaptureAccessibilityService, PendingCaptureStore,
                                 PendingClipboardRequestStore, CaptureMethodChannelHandler
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
errors, OCR failures, ...). This was the one piece of "future-facing"
infrastructure included before any repository existed to use it, because
retrofitting error handling style onto every repository/data source after
the fact is far more disruptive than deciding on it once, up front.
`OcrController` (Milestone 5) is its first real consumer.

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

**`minSdk` raised to 26** (later 30 — see the AccessibilityService rework
near the end of this doc). `WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY`
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
What's *not* here yet, on purpose, is any capture trigger — see Milestone 3
below for how that trigger actually landed (it changed the tap gesture
itself, not just the expanded panel, per product direction after this
milestone shipped).

### Milestone 3: MediaProjection, and the bubble's gesture model changed (capture mechanism superseded — see below)

**The tap gesture changed from Milestone 2.** The original brief's core
interaction is "tap bubble → screen is captured" (one tap), but Milestone 2
had already built and shipped tap = expand/collapse. Rather than bolt a
second "Capture" button onto the expanded panel (two taps to capture,
contradicting the one-tap vision), the gesture model was reworked in
`OverlayBubbleController`: **short tap on the collapsed bubble now
captures directly**; **long-press expands** the panel, which now exists
only to close/stop the overlay; drag still repositions it. This is a
product-direction change, not scope creep — flagging it here because it
touched code Milestone 2's README described as finished.

**Permission is requested once, reused for every capture.** `MediaProjection`
consent is a system dialog ("Start now" / "Cancel") — re-prompting on every
single bubble tap would defeat the point of a low-friction bubble. Instead,
`ScreenCaptureService` holds the granted `MediaProjection` for as long as
it's alive and creates a fresh `VirtualDisplay` + `ImageReader` per capture,
tearing both down immediately after grabbing one frame — no continuous
recording, just repeated on-demand single frames from one grant. The
trade-off: Android shows its own persistent "screen recording" indicator
for as long as that grant is held, on top of this app's own foreground
notification — an OS-level privacy signal that can't be suppressed, and
arguably shouldn't be. (This whole `MediaProjection` mechanism was later
replaced — see the AccessibilityService rework near the end of this doc.)

**Why the consent flow uses `startActivityForResult`, not the modern API.**
`FlutterActivity` extends the plain `android.app.Activity`, not AndroidX's
`ComponentActivity` — so `registerForActivityResult` (the current
recommended API) isn't available on it at all. `MainActivity` overrides
the classic `onActivityResult` instead, which Flutter's embedding
explicitly supports for exactly this situation.

**Why the captured bytes take a "pull on resume" path instead of an
`EventChannel`.** The capture is triggered natively, inside a Service, by
a bubble tap that can happen while the Flutter app is fully backgrounded.
Getting the bytes to Dart could have used an `EventChannel` (native pushes
as soon as it's ready) — instead, `ScreenCaptureService` stashes the PNG
bytes in an in-memory `PendingCaptureStore`, brings `MainActivity` to the
foreground, and `CaptureController` pulls them via a plain `MethodChannel`
call on the next resume. This reuses the exact resume-refresh mechanism
Milestone 2 already established for overlay permission, and sidesteps a
real `EventChannel` footgun: a sink registered on one Flutter engine
instance going stale if that engine is ever torn down and recreated,
silently dropping events. One lifecycle-refresh pattern for both features
was worth more than the marginal elegance of a push model here.

**Milestone 3 originally stopped at a raw full-screen preview** (a
`CapturePreviewScreen` showing the captured PNG with pinch-zoom, no region
selection). It shipped and was tested that way, but is gone as of Milestone
4 — replaced by `CaptureCropScreen`, which is what the user actually sees
now after tapping the bubble. Noting this because Milestone 3 was still
uncommitted when Milestone 4 landed, so there's no git history showing the
preview screen ever existed standalone.

### Milestone 4: drag-to-crop, in Flutter, no new dependency (superseded — see below)

Originally built as `CaptureCropScreen`: once the app was in the
foreground showing a captured screenshot, the user dragged a selection
rectangle in ordinary Flutter UI (`GestureDetector` + a `CustomPainter`
that dimmed everything outside the selection, snip-tool style), and the
actual pixel crop used `dart:ui`'s `Canvas.drawImageRect` — no image/crop
package needed. It shipped and was tested this way.

It no longer exists — the follow-up rework below moved the entire
selection step into the overlay itself, before the app ever opens.
`CaptureCropScreen` and its route were deleted rather than left in as
unused code. The one piece of it worth remembering, because the same
math got re-derived natively: mapping a drag gesture (in on-screen
coordinates) to a crop rectangle in source-image pixel coordinates has to
account for `BoxFit.contain`'s scale factor *and* its letterbox offset if
the image's aspect ratio doesn't match the view — get only the scale
right and the crop comes out subtly shifted, correct-looking only on
whichever screen you happened to test on.

### Milestone 5: on-device OCR, and why MediaProjection stayed

Two things were reconsidered going into this milestone, based on feedback
after Milestone 3 shipped:

- **Could screen capture avoid `MediaProjection`'s consent dialog and
  persistent indicator entirely**, to feel more like Android's "Circle to
  Search"? Investigated `AccessibilityService.takeScreenshot()` (API 30+),
  which genuinely is silent — no dialog, no indicator. Rejected: Google
  Play has a real, actively-enforced policy restricting Accessibility
  Service usage to apps providing genuine accessibility support, and using
  it purely for screenshots is a well-documented way to get an app
  rejected or removed. "Circle to Search" itself only gets away with
  silent capture because it's a Google system-privileged component — not
  a capability any third-party Play Store app can obtain. `MediaProjection`
  stayed as-is; only the post-capture flow changed (straight into crop,
  no separate preview stop) to make the interaction feel more immediate.
  (This rejection was later reversed by an explicit product decision,
  accepting the Play Store risk — see the AccessibilityService rework near
  the end of this doc.)
- **`google_mlkit_text_recognition`** (MIT, `flutter-ml.dev`) over hand-
  rolling OCR: recognition is a pre-trained ML model, not something
  reasonable to build from scratch the way the overlay/capture native code
  was. It wraps Google ML Kit's on-device text recognizer — fully offline
  after the model's one-time download via Play Services, free, no API key
  or Firebase project. `path_provider` (official Flutter-team package)
  came along with it: ML Kit's reliable input API takes a file path, not
  arbitrary encoded bytes, so the cropped PNG is written to a temp file
  before recognition.

`TextRecognizerService` isolates the plugin behind an interface (same
reasoning as `OverlayBridge`/`CaptureBridge`), and `OcrController` is the
first real user of `core/utils/result.dart`'s `Result<T>` — text
recognition succeeding or failing is exactly the "operation with an
expected failure mode" that type exists for.

### Post-Milestone-5 rework: selection moved into the overlay itself

After Milestone 5 shipped, product direction (with a concrete mockup)
called for the selection step to feel like Android's "Circle to Search" —
drag-select happening directly over whatever app you're in, with the
Reason AI app only opening once, after you confirm a selection, rather
than the app opening immediately after every tap. This changed where the
Milestone 4 crop UI lives, not whether `MediaProjection` is used (still
rejected switching to `AccessibilityService`, for the Play Store policy
reason in the Milestone 5 section above).

**The whole selection UI is now native, not a second Flutter engine.**
The tempting shortcut would be embedding a `FlutterView` in a full-screen
overlay window to reuse `CaptureCropScreen`'s code — rejected in
Milestone 2 for the bubble itself, and the reasoning holds even more here:
a second engine's lifecycle inside a `Service`, with no `Activity` behind
it, for a screen that's just "show a bitmap, drag a rectangle, two
buttons." `SelectionCanvasView` (a plain `View` with `onDraw`/
`onTouchEvent`) re-implements the same dim-outside/border-selection
drawing `CaptureCropScreen`'s `CustomPainter` did, and the same
`BoxFit.contain`-equivalent coordinate mapping — Android's `Canvas` API is
close enough to Flutter's that porting the already-validated math over
was direct, not a redesign.

**The flow now:** tap bubble → `OverlayService` captures via
`ScreenCaptureService` (unchanged) → instead of immediately opening the
app, it shows `SelectionOverlayController`, a second full-screen
`TYPE_APPLICATION_OVERLAY` window (focusable/touchable, unlike the small
bubble's) with the screenshot and a drag-to-select rectangle → **Cancel**
dismisses it with no further effect, bubble unchanged → **confirm** crops
the `Bitmap` natively (`Bitmap.createBitmap` with the selected bounds —
simpler than the `dart:ui` version, since there's no engine boundary to
cross), stores the result in the same `PendingCaptureStore`, and only
*then* brings `MainActivity` forward. Flutter's role shrank to exactly
"receive already-cropped bytes, run OCR, show the result" —
`CaptureController`'s `croppedImage`/`setCroppedImage` collapsed into a
single `capturedImage` field, since Flutter never sees the uncropped
screenshot at all anymore.

**Bug fix found while doing this rework:** the bubble is a window like
any other, so every screenshot taken before this point almost certainly
had the bubble icon baked into a corner of it. `OverlayBubbleController`
gained `setVisible()`, and `OverlayService` now hides the bubble, waits
one short delay for that to actually composite, captures, then restores
it — before this, there was no reason to have noticed, since capture and
"look at the result" were separated by an app-switch that drew attention
elsewhere.

### Post-Milestone-5 rework #2: MediaProjection replaced with AccessibilityService, and a bubble-tap menu

Product feedback after the selection-overlay rework above raised two more
points, both driven by a second mockup:

1. The `MediaProjection` consent dialog and persistent "screen recording"
   indicator (accepted as an unavoidable trade-off in the Milestone 5
   section above) were explicitly rejected — the ask was one permission,
   granted once at install-ish time, with capture feeling completely
   silent afterward.
2. Tapping the bubble should show a small menu — "Select on screen" or
   "From clipboard / text" — rather than jumping straight into capture.

**Capture mechanism swapped to `AccessibilityService.takeScreenshot()`
(API 30+).** This is the one Android capability that can grab arbitrary
on-screen content with no per-capture consent dialog and no recording
indicator — but it comes with the real trade-off flagged (and rejected) in
Milestone 5: Google Play's Accessibility API policy restricts this API to
apps with a genuine accessibility use case, and using it purely for
OCR/reasoning is a documented way to get an app rejected or pulled. This
was a business-risk decision, not a technical one — the user explicitly
chose to accept that risk after the trade-off was laid out, reversing the
Milestone 5 call.

- `ScreenCaptureService` (the `MediaProjection`-holding foreground service)
  is deleted entirely, along with `MainActivity`'s `onActivityResult`/
  `startActivityForResult` consent flow and the
  `FOREGROUND_SERVICE_MEDIA_PROJECTION` permission.
- `CaptureAccessibilityService` replaces it: a minimal `AccessibilityService`
  (`canRetrieveWindowContent="false"`, only listens for
  `typeWindowStateChanged` since it doesn't act on events at all) whose only
  job is calling `takeScreenshot()`. Declared in
  `res/xml/accessibility_service_config.xml` with `canTakeScreenshot="true"`.
- **Enabling it has no in-app dialog.** Unlike `MediaProjection`,
  Accessibility Services can only be toggled from system Settings >
  Accessibility — there's no `Intent` that pops a grant/deny dialog.
  `hasPermission()` checks `Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES`
  directly (the service could be revoked from Settings at any time, so this
  is checked fresh rather than cached); `requestPermission()` just opens
  `Settings.ACTION_ACCESSIBILITY_SETTINGS` and lets the existing
  resume-refresh pattern (from Milestone 2's overlay permission) pick up
  the change when the user comes back.
- **`minSdk` raised 26 → 30**, since `takeScreenshot()` requires API 30.
  This drops Android 8–10 support; a deliberate trade against zero-startup
  distribution risk, made alongside the AccessibilityService decision above.
- `takeScreenshot()` returns a `HardwareBuffer`-backed `Bitmap`
  (`Config.HARDWARE`), which several APIs used further down the pipeline
  reject outright — `Bitmap.compress()` throws on it, and so do some
  `Bitmap.createBitmap` overloads. `CaptureAccessibilityService` copies to
  `Config.ARGB_8888` immediately after wrapping the buffer, so the rest of
  the pipeline (`SelectionCanvasView`, the crop in
  `SelectionOverlayController`) never has to know a hardware bitmap was
  ever involved. One PNG round-trip also disappeared in this swap: capture
  now hands a `Bitmap` straight to the selection overlay instead of
  encoding to PNG and immediately decoding it back, which `ScreenCaptureService`
  used to do only because `MediaProjection`'s `ImageReader` output needed
  converting anyway.

**Bubble-tap menu, matching the mockup.** `OverlayBubbleController`'s short
tap now calls `onMenuRequested` (previously `onCaptureRequested`), which
`OverlayService` handles by showing `BubbleMenuOverlayController` — a small
`WRAP_CONTENT` overlay window (`bubble_menu.xml`) with the "What would you
like me to assess?" title, "Select on screen" / "From clipboard / text"
options, and a close button. It's positioned near the bubble's current
on-screen coordinates (`OverlayBubbleController.currentScreenPosition()`),
clamped so it can't render off-screen, flipping to appear below the bubble
instead of above if there isn't room above it.

Deliberately **no outside-tap-to-dismiss** — that would need a full-screen
transparent touch-catcher behind a small popup purely to detect taps
outside it, which is exactly the kind of complexity this doesn't need when
a close button already covers dismissal (`CLAUDE.md`: simplicity over
cleverness). "Select on screen" leads into the existing capture →
selection-overlay flow unchanged; "From clipboard / text" is new (below).

**The clipboard/text path.** There's nothing to visually select for pasted
text, so this path skips the selection overlay and brings the app forward
immediately, via a new `PendingClipboardRequestStore` (a boolean flag,
mirroring `PendingCaptureStore`). The actual clipboard read has to happen
in Dart, in the now-foregrounded app, not in the native `Service` that
requested it — Android 10+ only lets the currently-focused app read
clipboard contents, and a background `Service` is never that. `Clipboard`
comes from `package:flutter/services.dart` — no new dependency, since
Flutter ships clipboard access as a built-in platform channel.
`CaptureController` gained a `pastedText` field alongside `capturedImage`;
`OcrResultScreen` shows whichever one is present, running OCR only for the
image path and skipping straight to displaying the text for the clipboard
path — no second screen needed for what's visually the same "show me some
text" result.

**Selection UI polish.** `SelectionCanvasView` now draws small white
handle circles at the four corners of the selection rectangle, matching
the mockup's visual treatment more closely than the border-only rectangle
from the original rework.

### Milestone 6: backend integration and the four result screens

Milestone 6's actual backend (`backend/`) is a single mocked
`POST /analyze` endpoint — see `backend/README.md`. This section covers
wiring the app to it and building the result UI the product mockup calls
for, on top of that mocked data.

**New `analysis` feature**, mirroring the existing data/presentation split:
`AnalysisApi` (`features/analysis/data/analysis_api.dart`) isolates
`package:http` behind an interface the same way `CaptureBridge`/
`TextRecognizerService` isolate their platform channels — nothing else
touches `http` directly. `AnalysisController` mirrors `OcrController`'s
`Result<T>`-based shape exactly, since a network call is exactly the
same "can fail in an expected way" case.

**`http` package added** — the official Dart-team package, a thin wrapper
over `dart:io`/web HTTP. No heavier client (`dio`, `chopper`) is justified
for one JSON POST call.

**Reaching a locally-run backend from a physical device.** `API_BASE_URL`
in `env/dev.json` is `http://127.0.0.1:8000` — the *device's own*
loopback — paired with `adb reverse tcp:8000 tcp:8000`, which forwards
that port to the dev machine over the existing USB connection. This was
chosen over `10.0.2.2` (the Android *emulator's* alias, not applicable to
a real device) or a LAN IP (would need the phone and dev machine on the
same network, and the backend bound to `0.0.0.0`). The forward doesn't
survive a USB disconnect/reconnect — see `env/README.md`.

**The "Analyzing" screen intentionally fakes its pacing.** `AnalyzingScreen`
holds for a fixed 5 seconds and advances its five checklist steps on a
1-second timer, regardless of how long OCR + the network call actually
take (currently milliseconds, since the backend is mocked). This is a
deliberate product decision — matching the mockup's "this usually takes
5-10 seconds" framing — not a claim that the steps reflect real pipeline
stages; the mocked backend doesn't report intermediate progress, so
there's no real signal to drive them with yet. Milestone 7's real
pipeline could swap the timer for actual stage events without changing
this screen's shape.

**Four result screens, matching the product mockup**: `CoreClaimScreen` →
`AnalysisScreen` (Overview/Questions/Context shown inline; tapping
"Evidence" pushes a dedicated `EvidenceScreen` instead of switching tab
content, since the mockup gives Evidence its own search/filter UI
distinct from a plain tab body) → `EvidenceScreen` (All/For/Against/Neutral
filter chips over the same evidence list) → `SummaryScreen`. All four read
the completed result from `analysisControllerProvider` rather than route
arguments, consistent with how `OcrResultScreen` (this milestone's
predecessor) read from `captureControllerProvider`.

**Unimplemented actions get an honest "Coming soon", not silence.**
"Ask a follow-up question" / "Save this analysis" / "Share" (on
`SummaryScreen`) and a couple of decorative icon buttons elsewhere have no
backing feature yet — Milestone 7 and beyond will give some of them real
behavior. Rather than wiring them to nothing (a button that visibly does
nothing reads as broken) or building throwaway functionality ahead of
need, they show a shared `showComingSoon()` snackbar. "New selection" is
the one action that's real today — it returns to Home.

**The backend's mocked schema grew to match the mockup's actual content**:
`what_this_means`, `questions`, `context`, and each insight got a `kind`
(`strength`/`question`/`context`, driving which icon the client shows)
and an optional `tag` (e.g. "Moderate"). This is still all fixed
placeholder text — Milestone 7 changes the values, not this shape.

### Linting

`analysis_options.yaml` extends `flutter_lints` and turns on
`strict-casts` / `strict-inference` / `strict-raw-types` in the analyzer,
plus a small set of additional lints (`avoid_dynamic_calls`,
`unawaited_futures`, etc.) that catch the kinds of bugs that are cheap to
prevent and expensive to debug on a device (unawaited futures silently
swallowing errors, implicit `dynamic`).

# Reason AI (working name)

Android-first app that helps people think critically about the information
they consume. The user highlights a claim on screen (via a floating bubble →
screenshot → region select → OCR), and the backend returns a structured
"reasoning card" analyzing that claim. This is explicitly **not** a chatbot —
the interaction model (bubble → capture → reasoning card) is the product's
core differentiator.

## Repository layout

This is a monorepo. Each top-level folder is an independently deployable
project with its own dependency manifest and lifecycle:

```
reasoning_engine/
├── app/       Flutter client (Android-first). See app/README.md.
└── backend/   FastAPI service (OCR → claim extraction → reasoning).
               Added in a later milestone — not present yet.
```

Keeping the client and backend as siblings (rather than the Flutter project
at the repo root) leaves room for the backend, and later shared assets
(design tokens, API contracts, docs), without restructuring the client.

## Build order

The system is being built incrementally, one vertical slice at a time,
rather than all at once:

1. **Flutter project scaffold** — structure, theming, routing, DI, logging.
   ✅ done, see [`app/`](app/).
2. **Android overlay (floating bubble) feature.** ✅ done — draggable,
   expand/collapse, survives backgrounding, see the Milestone 2 section in
   [`app/README.md`](app/README.md).
3. **Screenshot capture.** ✅ done — tap the bubble, then "Select on
   screen" in the bubble menu to capture. Uses `AccessibilityService`
   (a single one-time permission, no recording indicator), after starting
   on MediaProjection and switching later — see the Milestone 3 and
   "post-Milestone-5 rework #2" sections in [`app/README.md`](app/README.md).
4. **Region selector UI.** ✅ done — drag-to-select happens as a native
   overlay directly over whatever app you're in, confirmed before the app
   ever opens (reworked after Milestone 4 shipped; see the Milestone 4 and
   "post-Milestone-5 rework" sections in [`app/README.md`](app/README.md)).
5. **OCR integration.** ✅ done — on-device Google ML Kit, no backend. The
   bubble menu also offers "From clipboard / text" as a second path to the
   same result screen, skipping OCR entirely — see the Milestone 5 section
   in [`app/README.md`](app/README.md).
6. Backend (FastAPI): claim extraction + reasoning pipeline.
7. AI pipeline (OpenAI-backed reasoning prompts).

## Platform scope note

The floating-bubble overlay (step 2) relies on Android's system alert
window / accessibility APIs, which have no equivalent on iOS — Apple does
not allow system-wide draw-over-other-apps overlays. Flutter is still the
right choice for the UI layer, but the core interaction is Android-only
for the foreseeable future. An iOS entry point, if pursued later, would
need a different trigger (e.g. a Share Extension) rather than a bubble.

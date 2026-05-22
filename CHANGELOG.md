# Changelog

All notable changes to **PulseOps** will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/) and
this project adheres to [Semantic Versioning](https://semver.org/).

## 1.2.0 — 2026-05-22

### ⚡ Performance Monitoring

- **Real-time FPS monitor** — subscribes to `WidgetsBinding` frame timings and
  streams FPS data into a rolling 300-frame ring buffer.
- **Frame drop & jank detection** — frames exceeding 16 ms are flagged as
  dropped; frames exceeding 33 ms are marked severe jank.
- **Startup time tracking** — measures wall-clock time from `PulseOps.initialize`
  to the first rendered frame.
- **API latency chart** — `CustomPainter` bar chart showing the last 40 request
  durations, coloured green / yellow / red against the slow-request threshold.
- **FPS sparkline chart** — gradient-filled line chart with 60 fps / 30 fps
  reference grid lines, coloured by current FPS health.
- **Performance screen** accessible from the inspector toolbar (`⚡` button),
  showing startup banner, FPS stats, frame drop list, and latency charts.

### 🔍 Inspector Improvements

- **Slow filter chip** — one-tap filter to show only requests that exceeded the
  configured `slowRequestThresholdMs`.
- **Status-family filter chips** — filter by `2xx`, `3xx`, `4xx`, or `5xx`
  response families.
- **Wider search** — search now matches against host name and error message in
  addition to URL, method, and status code.

## 1.1.1 — 2026-05-21

### 🐛 Bug Fixes

- Fixed `No Directionality widget found` crash on Android and iOS when the
  `PulseOverlay` `Stack` was mounted above the host app's `MaterialApp`.
  The overlay now wraps the `Stack` in an explicit `Directionality(ltr)`.
- Fixed `RenderFlex overflowed` yellow-stripe in `RequestTile` when the host
  name is long (e.g. `jsonplaceholder.typicode.com`). The host `Text` is now
  wrapped in `Flexible` so it ellipsises instead of overflowing.

### 📚 Documentation

- Added a **Sentry adapter** code snippet to the README — drop-in equivalent
  of the existing Firebase Crashlytics adapter. Covers non-fatal, fatal,
  breadcrumbs, network history, and custom tags via `Sentry.configureScope`.
- Updated CI workflow (`publish.yml`) to use `flutter pub get`,
  `flutter analyze`, and `flutter test` instead of their bare `dart` equivalents,
  fixing the *"Flutter users should use flutter pub"* error in GitHub Actions.

## 1.1.0 — 2026-05-16

### 🛠 Debug Overlay

- **Shake-to-open**: shaking the device launches the inspector. Tunable via
  `PulseOpsConfig.enableShakeToOpen` and `shakeThreshold`. Powered by
  `sensors_plus` and silently no-ops when an accelerometer is unavailable.
- **Expandable bottom sheet**: the inspector now slides up as a draggable
  bottom sheet with 40 / 70 / 95 % snap points instead of a full-screen
  route. Switch back via
  `PulseOpsConfig(inspectorPresentation: InspectorPresentation.fullScreen)`.

### ✨ Developer Experience

- **Log export**: new export menu in the inspector (JSON / plain text / cURL)
  that opens the platform share sheet via `share_plus` and falls back to
  clipboard. Programmatic exports available via `NetworkLogExporter`.

### Migration

- `PulseOps.openInspector` now respects `inspectorPresentation`. Existing
  callers continue to work unchanged.

## 1.0.0 — 2026-05-16

Initial public release.

### 🌐 Network Inspector

- Dio interceptor (`PulseDioInterceptor`) capturing request, response,
  headers, query params, timing, sizes, and errors.
- In-memory ring-buffer store (`InMemoryNetworkStore`) with configurable
  capacity and reactive stream API.
- Beautiful dark Material 3 inspector UI:
  - Newest-first timeline with method, status, host, duration, timestamp.
  - Live search and filter chips (`GET` / `POST` / `PUT` / `PATCH` /
    `DELETE`, plus "failed only").
  - Per-request detail screen with **Overview**, **Headers**, **Request**,
    **Response**, and **cURL** tabs.
  - Syntax-highlighted JSON viewer with copy-to-clipboard.
- One-tap **cURL export** via `CurlBuilder` with proper shell escaping.
- One-tap **retry** using a host-provided Dio instance.
- Multipart (`FormData`) request description, including filenames + sizes.
- Header / body sanitization for sensitive keys.

### 💥 Crash Diagnostics

- Backend-agnostic `PulseCrashReporter` interface with shipped
  `NoopCrashReporter` and a documented Firebase Crashlytics adapter.
- `BreadcrumbTrail` ring buffer with `debug` / `info` / `warning` / `error`
  levels.
- Automatic non-fatal reporting for failed Dio requests, with recent
  request summary attached as context.
- Manual breadcrumb + error APIs:
  `PulseOps.instance.log(...)`, `PulseOps.instance.recordError(...)`.
- Optional global `FlutterError.onError` and `PlatformDispatcher.onError`
  installation.

### Developer Experience

- Single-call `PulseOps.initialize(...)` with shorthand `crashlytics`,
  `enableInRelease`, and `sanitizeKeys` named args.
- `PulseOps.instance.wrap(child:)` to mount the draggable floating overlay
  launcher around any widget tree.
- `PulseOps.instance.openInspector(context)` to push the inspector from a
  debug menu without the overlay.
- Production-safe: inspector and overlay are disabled in release builds
  unless `enableInRelease` is explicitly set.
- Comprehensive test suite covering sanitizer, cURL builder, store,
  breadcrumb trail, interceptor, and facade.

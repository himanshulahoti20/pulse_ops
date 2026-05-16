# Changelog

All notable changes to **PulseOps** will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/) and
this project adheres to [Semantic Versioning](https://semver.org/).

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

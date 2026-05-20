# pulse_ops

[![pub version](https://img.shields.io/pub/v/pulse_ops.svg)](https://pub.dev/packages/pulse_ops)
[![pub points](https://img.shields.io/pub/points/pulse_ops)](https://pub.dev/packages/pulse_ops/score)
[![pub likes](https://img.shields.io/pub/likes/pulse_ops)](https://pub.dev/packages/pulse_ops/score)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![CI](https://github.com/himanshulahoti20/pulse_ops/actions/workflows/dart_ci.yml/badge.svg?branch=main&cache_bust=1)


> A modern, Flutter-native developer toolkit for **in-app network inspection**
> and **crash diagnostics** — designed as a lightweight alternative to
> Chucker / Pulse / Stetho, with a beautiful dark Material 3 UI.

<p align="center">
  <img
    src="https://raw.githubusercontent.com/himanshulahoti20/pulse_ops/main/doc/demo.gif"
    alt="PulseOps in action — floating launcher, expandable inspector, cURL export, and log sharing"
    width="320"
  />
</p>

PulseOps ships with two focused capabilities in v1.0:

1. **🌐 Network Inspector** — a Dio interceptor that records every request,
   pretty-prints JSON, exports cURL, retries calls, and presents it all in a
   developer-grade dark inspector.
2. **💥 Crash Diagnostics** — pluggable bridge to Firebase Crashlytics (or any
   backend) with rich breadcrumbs and automatic attachment of recent API
   activity to every crash report.

---

## ✨ Highlights

- 🎨 **Beautiful dark, Material 3 inspector** with monospace JSON viewer and
  syntax highlighting
- 🔌 **One-line Dio integration** — works with `GET`, `POST`, `PUT`, `PATCH`,
  `DELETE`, and `multipart/form-data`
- 🔍 **Search, filter by method, "failed only"** filter
- 📋 **Copy buttons everywhere** — headers, body, full cURL
- ↻ **Retry requests** from the inspector with your real Dio client
- 🔒 **Sanitization** for secrets / tokens / passwords before storage or upload
- 🧭 **Breadcrumb trail** with bounded ring buffer
- 💥 **Backend-agnostic crash reporter** — wire Crashlytics, Sentry, or your
  own logger via a thin `PulseCrashReporter` interface
- 🛡️ **Production-safe** — disabled in release builds by default
- 🪶 **Lightweight** — no Firebase or Isar at runtime; pure Dart + Dio +
  Riverpod core

---

## 🚀 Quick start

### 1. Add the dependency

```yaml
dependencies:
  pulse_ops: ^1.1.0
  dio: ^5.4.0
```

### 2. Initialize in `main()`

```dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pulse_ops/pulse_ops.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PulseOps.initialize(
    crashlytics: true,
    enableInRelease: false,
    sanitizeKeys: ['token', 'password', 'authorization'],
  );

  final dio = Dio()..interceptors.add(PulseOps.instance.dioInterceptor);

  runApp(PulseOps.instance.wrap(retryDio: dio, child: const MyApp()));
}
```

That's it. A draggable floating button appears in debug builds; tap it to
open the inspector.

### 3. (Optional) Open the inspector imperatively

```dart
PulseOps.instance.openInspector(context, retryDio: dio);
```

---

## 🌐 Network Inspector

Every Dio call routed through `PulseOps.instance.dioInterceptor` is captured
as a `NetworkRecord` and pushed into an in-memory ring buffer (configurable
via `PulseOpsConfig.maxRecords`).

The inspector UI provides:

| Surface | Contents |
| --- | --- |
| **Timeline list** | Newest-first list of requests with method chip, host, path, timestamp, duration, status chip |
| **Overview tab** | Status, timing, request/response sizes, error details |
| **Headers tab** | Sanitized request + response headers with copy-all |
| **Request tab** | Query params and request body with syntax-highlighted JSON |
| **Response tab** | Highlighted response body and error banner |
| **cURL tab** | One-tap copy of the full `curl` command |

The list supports:

- 🔎 Live search across URL / method / status
- 🎯 Filter by method (`GET` / `POST` / `PUT` / `PATCH` / `DELETE`)
- ⚠️ "Failed only" toggle

### Retrying a request

Pass your authenticated `Dio` instance to `wrap(retryDio:)` or
`openInspector(retryDio:)`. The retry button in the app bar reissues the
captured request via that client.

### Multipart support

`FormData` payloads are described (field names, file names, sizes) rather
than serialized — useful for inspecting uploads without breaking streams.

---

## 💥 Crash Diagnostics

PulseOps decouples itself from any specific crash backend via the
`PulseCrashReporter` interface, so the package itself does **not** depend on
`firebase_crashlytics`. You wire that up in your app.

### Example adapter for Firebase Crashlytics

```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:pulse_ops/pulse_ops.dart';

class FirebaseCrashReporterAdapter implements PulseCrashReporter {
  FirebaseCrashReporterAdapter(this._c);
  final FirebaseCrashlytics _c;

  @override
  Future<void> recordNonFatal(Object error,
      {StackTrace? stackTrace, String? reason, Map<String, dynamic>? context}) async {
    await _attach(context);
    await _c.recordError(error, stackTrace, reason: reason, fatal: false);
  }

  @override
  Future<void> recordFatal(Object error,
      {StackTrace? stackTrace, Map<String, dynamic>? context}) async {
    await _attach(context);
    await _c.recordError(error, stackTrace, fatal: true);
  }

  @override
  Future<void> attachBreadcrumbs(List<Breadcrumb> breadcrumbs) async {
    for (final b in breadcrumbs) {
      await _c.log(b.toString());
    }
  }

  @override
  Future<void> attachNetworkHistory(List<NetworkRecord> records) async {
    final summary = records.take(20).map((r) =>
        '${r.method} ${r.endpoint} -> ${r.statusCode ?? r.status.name}').join('\n');
    await _c.setCustomKey('pulse_ops_recent_requests', summary);
  }

  @override
  Future<void> setCustomKey(String key, Object value) =>
      _c.setCustomKey(key, value);

  Future<void> _attach(Map<String, dynamic>? context) async {
    if (context == null) return;
    for (final e in context.entries) {
      await _c.setCustomKey(e.key, e.value.toString());
    }
  }
}
```

Then pass it in:

```dart
await PulseOps.initialize(
  crashReporter: FirebaseCrashReporterAdapter(FirebaseCrashlytics.instance),
);
```

### Example adapter for Sentry

```dart
import 'package:pulse_ops/pulse_ops.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class SentryCrashReporterAdapter implements PulseCrashReporter {
  const SentryCrashReporterAdapter();

  @override
  Future<void> recordNonFatal(Object error,
      {StackTrace? stackTrace, String? reason, Map<String, dynamic>? context}) async {
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      hint: Hint.withMap({
        if (reason != null) 'reason': reason,
        if (context != null) ...context,
      }),
    );
  }

  @override
  Future<void> recordFatal(Object error,
      {StackTrace? stackTrace, Map<String, dynamic>? context}) async {
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) => scope.setTag('fatal', 'true'),
    );
  }

  @override
  Future<void> attachBreadcrumbs(List<Breadcrumb> breadcrumbs) async {
    for (final b in breadcrumbs) {
      await Sentry.addBreadcrumb(
        SentryBreadcrumb(
          message: b.message,
          level: _sentryLevel(b.level),
          timestamp: b.timestamp,
          data: b.data,
        ),
      );
    }
  }

  @override
  Future<void> attachNetworkHistory(List<NetworkRecord> records) async {
    final summary = records.take(20).map((r) =>
        '${r.method} ${r.endpoint} -> ${r.statusCode ?? r.status.name}').join('\n');
    await Sentry.configureScope(
      (scope) => scope.setContexts('pulse_ops_recent_requests', {'log': summary}),
    );
  }

  @override
  Future<void> setCustomKey(String key, Object value) async {
    await Sentry.configureScope((scope) => scope.setTag(key, value.toString()));
  }

  SentryLevel _sentryLevel(BreadcrumbLevel level) {
    switch (level) {
      case BreadcrumbLevel.debug:   return SentryLevel.debug;
      case BreadcrumbLevel.info:    return SentryLevel.info;
      case BreadcrumbLevel.warning: return SentryLevel.warning;
      case BreadcrumbLevel.error:   return SentryLevel.error;
    }
  }
}
```

Then initialize Sentry first, then PulseOps:

```dart
await SentryFlutter.init(
  (options) => options.dsn = 'YOUR_DSN',
  appRunner: () async {
    await PulseOps.initialize(
      crashReporter: const SentryCrashReporterAdapter(),
    );
    runApp(PulseOps.instance.wrap(child: MyApp()));
  },
);
```

### What gets attached to crashes

Whenever an error is reported through PulseOps — automatically for failed
HTTP requests, or manually via `PulseOps.instance.recordError(...)`:

- The **breadcrumb trail** (default 50 entries) is forwarded.
- The **last 20 network records** are summarized and attached as context.
- Any additional `extra` map you pass is merged in.

### Adding your own breadcrumbs

```dart
PulseOps.instance.log('User opened checkout', data: {'cart_size': 4});
```

### Reporting errors manually

```dart
try {
  await doRiskyThing();
} catch (e, st) {
  await PulseOps.instance.recordError(e, st, reason: 'checkout pipeline');
}
```

### Failed requests

When `PulseOpsConfig.captureFailedRequestsAsCrashEvents` is `true` (the
default), every Dio exception is forwarded to the configured reporter as a
non-fatal — already enriched with the request summary, e.g.:

```text
GET /profile        200 OK
POST /login         timeout
PUT /settings       500
```

This timeline rides along to Crashlytics so triage starts with full context.

---

## ⚙️ Configuration

```dart
const PulseOpsConfig(
  enableInRelease: false,                  // disable overlay/inspector in prod
  maxRecords: 200,                         // request ring-buffer size
  maxBreadcrumbs: 50,                      // breadcrumb ring-buffer size
  sanitizeKeys: ['authorization', ...],    // keys redacted everywhere
  attachNetworkHistoryToCrashes: true,
  showOverlay: true,                       // floating launcher
  captureFailedRequestsAsCrashEvents: true,
)
```

You can pass it directly to `PulseOps.initialize(config: ...)`, or use the
shorthand named args `enableInRelease`, `sanitizeKeys`, `crashlytics`.

---

## 🏗 Architecture

```text
lib/
├── pulse_ops.dart                         # public exports
└── src/
    ├── core/                              # facade + config
    ├── network/
    │   ├── interceptor/                   # PulseDioInterceptor
    │   ├── models/                        # NetworkRecord
    │   ├── store/                         # NetworkStore (in-memory)
    │   └── utils/                         # CurlBuilder, Sanitizer
    ├── crash/                             # breadcrumbs + reporter + bridge
    ├── ui/
    │   ├── inspector/                     # screens, tabs, widgets
    │   ├── overlay/                       # draggable launcher
    │   └── theme/                         # dark Material 3 theme
    └── providers/                         # Riverpod scope
```

The design follows **clean architecture** principles: the network layer is
plain Dart with no Flutter imports, the UI consumes data only through
Riverpod providers, and the crash backend is injected via an interface.
This makes it trivial to:

- swap the in-memory store for an Isar/Hive-backed store
- substitute the crash reporter for Sentry, Bugsnag, or a custom sink
- embed the inspector inside a debug menu without using the overlay

---

## 🧪 Testing

The package ships with a full test suite covering the sanitizer, cURL
builder, in-memory store, breadcrumb trail, Dio interceptor (success /
failure / sanitization paths), and the facade.

```bash
flutter test
```

---

## 🛣 Roadmap

- [ ] Isar-backed persistent network store
- [ ] HTTP/2 + `http` package interceptor adapter
- [ ] Log inspector (debugPrint / `Logger`)
- [ ] Performance traces (frame timings, GC)
- [ ] Per-host throttling visualizer

---

## 📄 License

MIT — see `LICENSE`.

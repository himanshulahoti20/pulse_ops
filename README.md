# pulse_ops

<!-- pub.dev -->
[![pub version](https://img.shields.io/pub/v/pulse_ops.svg)](https://pub.dev/packages/pulse_ops)
[![pub points](https://img.shields.io/pub/points/pulse_ops)](https://pub.dev/packages/pulse_ops/score)
[![pub likes](https://img.shields.io/pub/likes/pulse_ops)](https://pub.dev/packages/pulse_ops/score)
[![pub popularity](https://img.shields.io/pub/popularity/pulse_ops)](https://pub.dev/packages/pulse_ops/score)

<!-- GitHub -->
![CI](https://github.com/himanshulahoti20/pulse_ops/actions/workflows/dart_ci.yml/badge.svg?branch=main&cache_bust=1)
[![GitHub stars](https://img.shields.io/github/stars/himanshulahoti20/pulse_ops?style=flat&logo=github&label=stars)](https://github.com/himanshulahoti20/pulse_ops/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/himanshulahoti20/pulse_ops)](https://github.com/himanshulahoti20/pulse_ops/issues)
[![GitHub last commit](https://img.shields.io/github/last-commit/himanshulahoti20/pulse_ops)](https://github.com/himanshulahoti20/pulse_ops/commits/main)
[![PRs welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/himanshulahoti20/pulse_ops/pulls)
[![Sponsor](https://img.shields.io/github/sponsors/himanshulahoti20?label=Sponsor&logo=GitHub)](https://github.com/sponsors/himanshulahoti20)

<!-- tech -->
[![Flutter ≥3.10](https://img.shields.io/badge/flutter-%E2%89%A53.10-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart ≥3.0](https://img.shields.io/badge/dart-%E2%89%A53.0-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![iOS](https://img.shields.io/badge/iOS-000000?style=flat&logo=apple&logoColor=white)](https://pub.dev/packages/pulse_ops)
[![Android](https://img.shields.io/badge/Android-3DDC84?style=flat&logo=android&logoColor=white)](https://pub.dev/packages/pulse_ops)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

---

> A modern, Flutter-native developer toolkit for **in-app network inspection**,
> **performance & memory monitoring**, and **crash diagnostics** — built for
> iOS & Android, with a beautiful dark Material 3 UI.

<p align="center">
  <img
    src="https://raw.githubusercontent.com/himanshulahoti20/pulse_ops/main/doc/demo.gif"
    alt="PulseOps in action — floating launcher, expandable inspector, cURL export, and log sharing"
    width="320"
  />
</p>

PulseOps ships with five focused capabilities:

1. **🌐 Network Inspector** — a Dio interceptor that records every request,
   pretty-prints JSON, exports cURL, retries calls, and presents it all in a
   developer-grade dark inspector.
2. **⚡ Performance Monitoring** — real-time FPS tracking, frame drop & jank
   detection, startup time measurement, and API latency charts.
3. **🧠 Memory Monitoring** — RSS memory tracking, spike detection, leak
   detection via `FlutterMemoryAllocations`, widget lifecycle logs, and rebuild
   frequency tracking.
4. **💥 Crash Diagnostics** — pluggable bridge to Firebase Crashlytics (or any
   backend) with rich breadcrumbs and automatic attachment of recent API
   activity to every crash report.
5. **🧪 Test Observability** — per-test session tracking with event timelines,
   API log capture, assertion recording, failure diagnostics, and exportable
   reports.

---

## ✨ Highlights

- 🎨 **Beautiful dark, Material 3 inspector** with monospace JSON viewer and
  syntax highlighting
- 🔌 **One-line Dio integration** — works with `GET`, `POST`, `PUT`, `PATCH`,
  `DELETE`, and `multipart/form-data`
- 🔍 **Search, filter by method / status family / slow / failed** — live and
  composable
- 📋 **Copy buttons everywhere** — headers, body, full cURL
- ↻ **Retry requests** from the inspector with your real Dio client
- ⚡ **Real-time FPS monitor** — sparkline chart, dropped-frame list, startup
  time, and API latency bar chart
- 🧠 **Memory monitor** — RSS sparkline, spike warnings, leak list, widget
  lifecycle breakdown, and rebuild frequency — all live
- 🧪 **Test observability** — per-test session timeline, API log capture,
  assertion recording, failure diagnostics, and JSON/text report export
- 💾 **Persistent network store** — `FileBackedNetworkStore` survives app
  restarts with zero extra setup
- 📡 **Unified event exporter** — one interface to forward every failed request
  and every crash to your own analytics backend
- 📳 **Shake to open** — shake the device to launch the inspector
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
  pulse_ops: ^1.4.0
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
open the inspector. Use the **🧠** toolbar button for memory, **⚡** for
performance.

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

- 🔎 Live search across URL, method, status, host, and error message
- 🎯 Filter by HTTP method (`GET` / `POST` / `PUT` / `PATCH` / `DELETE`)
- ⚠️ **Failed only** toggle — show only errored requests
- 🐢 **Slow only** toggle — requests exceeding `slowRequestThresholdMs`
- 🔢 **Status-family chips** — `2xx` / `3xx` / `4xx` / `5xx`

### Persistent store

To keep network history across app restarts, swap in `FileBackedNetworkStore`:

```dart
final store = FileBackedNetworkStore(maxRecords: 200);
await store.initialize();              // loads previous session from disk

await PulseOps.initialize(
  networkStore: store,
);
```

### Retrying a request

Pass your authenticated `Dio` instance to `wrap(retryDio:)` or
`openInspector(retryDio:)`. The retry button in the app bar reissues the
captured request via that client.

### Multipart support

`FormData` payloads are described (field names, file names, sizes) rather
than serialized — useful for inspecting uploads without breaking streams.

---

## ⚡ Performance Monitoring

The performance screen is available from the **⚡ icon** in the inspector
toolbar. It requires no additional dependencies — everything uses Flutter's
built-in `WidgetsBinding.addTimingsCallback`.

### What's tracked

| Metric | Description |
| --- | --- |
| **Startup time** | Wall-clock time from `PulseOps.initialize()` to the first rendered frame |
| **Current FPS** | Rolling average over the last 15 frames |
| **Dropped frames** | Frames taking > 16 ms (one refresh period at 60 Hz) |
| **Severe jank** | Frames taking > 33 ms (two full refresh periods) |
| **API latency** | Per-request bar chart for the last 40 completed calls |

### FPS chart

A gradient-filled sparkline shows FPS over the last N frames (default 300).
The line turns green (≥ 55 fps), yellow (≥ 40 fps), or red (< 40 fps).
Reference grid lines are drawn at 60 fps and 30 fps.

### Latency chart

Each bar represents one completed request, coloured:

- 🟢 **Green** — within the slow-request threshold
- 🟡 **Yellow** — exceeds `slowRequestThresholdMs`
- 🔴 **Red** — the request failed

A dashed threshold line marks the slow boundary.

---

## 🧠 Memory Monitoring

The memory screen is available from the **🧠 icon** in the inspector toolbar.
It uses `dart:io`'s `ProcessInfo.currentRss` for RSS sampling and Flutter's
`FlutterMemoryAllocations` for object lifecycle — **no extra dependencies**.

### Metrics

| Metric | Description |
| --- | --- |
| **Current RSS** | Process resident set size, sampled every 2 s (configurable) |
| **Peak RSS** | Highest RSS reading since monitoring started |
| **Memory spikes** | Samples >20% above the 10-sample rolling average |
| **Potential leaks** | Objects created but not disposed after 30 s |
| **Widget lifecycle** | Created / active / disposed counts per type |
| **Rebuild counts** | How many times each widget type has been rebuilt |

### Leak detection

PulseOps subscribes to `FlutterMemoryAllocations` and tracks the lifecycle
of every `ChangeNotifier`, `AnimationController`, `TextEditingController`, and
other disposable Flutter objects. Any object that remains alive for > 30 s
without being disposed appears in the **Potential Leaks** list with its age.

### Rebuild tracking

Call `PulseOps.instance.memoryStore.recordRebuild(widgetType)` at the top of
your `build()` method to track rebuild frequency:

```dart
@override
Widget build(BuildContext context) {
  PulseOps.instance.memoryStore.recordRebuild('MyHeavyWidget');
  return ...;
}
```

Counts appear colour-coded in the Memory screen — red (> 50), yellow (> 20).

---

## 📡 Unified Event Exporter

Implement `PulseEventExporter` and pass it to `PulseOps.initialize` to receive
**every failed API call and every crash** in one place, so you can forward them
to Mixpanel, Amplitude, your own backend, or any analytics sink:

```dart
class MyAnalyticsExporter implements PulseEventExporter {
  @override
  Future<void> onFailedRequest(NetworkRecord record) async {
    await MyAnalytics.track('api_error', {
      'url': record.url,
      'method': record.method,
      'status': record.statusCode,
      'error': record.error,
      'duration_ms': record.duration.inMilliseconds,
    });
  }

  @override
  Future<void> onCrash(
    Object error,
    StackTrace? stackTrace, {
    required String? reason,
    required bool fatal,
    required List<Breadcrumb> breadcrumbs,
    required List<NetworkRecord> recentRequests,
  }) async {
    await MyAnalytics.trackCrash(
      error.toString(),
      fatal: fatal,
      context: {'breadcrumb_count': breadcrumbs.length},
    );
  }
}
```

```dart
await PulseOps.initialize(
  eventExporter: MyAnalyticsExporter(),
);
```

This is separate from `PulseCrashReporter` — the exporter fires for both
crashes **and** failed requests, making it ideal for a unified observability
pipeline.

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

---

## ⚙️ Configuration

```dart
const PulseOpsConfig(
  // — General —
  enableInRelease: false,                  // keep disabled in prod builds
  showOverlay: true,                       // floating launcher button

  // — Network —
  maxRecords: 200,                         // request ring-buffer capacity
  sanitizeKeys: ['authorization', ...],    // keys redacted before storage
  slowRequestThresholdMs: 2000,            // ms to flag a request as slow
  captureFailedRequestsAsCrashEvents: true,
  attachNetworkHistoryToCrashes: true,

  // — Performance —
  enableFpsMonitor: true,                  // frame-timing subscriber
  fpsFrameBufferSize: 300,                 // frames kept in memory

  // — Memory —
  enableMemoryMonitor: true,               // RSS polling + FlutterMemoryAllocations
  memorySampleIntervalSeconds: 2,          // polling interval
  memorySnapshotBufferSize: 120,           // snapshots kept (~4 min at 2 s)

  // — Overlay / UX —
  enableShakeToOpen: true,                 // shake gesture to open inspector
  shakeThreshold: 22.0,                    // m/s² to trigger a shake
  inspectorPresentation: InspectorPresentation.bottomSheet, // or .fullScreen

  // — Crash —
  maxBreadcrumbs: 50,
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
    ├── core/                              # facade + config + PulseEventExporter
    ├── network/
    │   ├── interceptor/                   # PulseDioInterceptor
    │   ├── models/                        # NetworkRecord (with toJson/fromJson)
    │   ├── store/                         # InMemoryNetworkStore, FileBackedNetworkStore
    │   └── utils/                         # CurlBuilder, Sanitizer, LogExporter
    ├── performance/
    │   ├── frame_metric.dart              # FrameMetric value type
    │   ├── performance_store.dart         # ring-buffer + stream
    │   └── fps_tracker.dart              # WidgetsBinding timing subscriber
    ├── memory/
    │   ├── memory_snapshot.dart           # RSS snapshot value type
    │   ├── tracked_object.dart            # object lifecycle record
    │   ├── memory_store.dart             # ring-buffer + leak map + rebuild counts
    │   └── memory_monitor.dart           # RSS polling + FlutterMemoryAllocations
    ├── testing/
    │   ├── test_event.dart               # TestEvent value type
    │   ├── test_session.dart             # TestSession value type
    │   ├── test_store.dart              # ring-buffer + stream
    │   ├── pulse_test_observer.dart      # static helper for test files
    │   └── test_report_exporter.dart     # JSON / plain-text report serialiser
    ├── crash/                             # breadcrumbs + reporter + bridge
    ├── ui/
    │   ├── inspector/                     # screens, tabs, widgets
    │   ├── performance/                   # PerformanceScreen + charts
    │   ├── memory/                        # MemoryScreen + RSS chart
    │   ├── testing/                       # TestScreen + TestSessionScreen
    │   ├── overlay/                       # draggable launcher + shake detector
    │   └── theme/                         # dark Material 3 theme
    └── providers/                         # Riverpod scope
```

The design follows **clean architecture** principles: the network layer is
plain Dart with no Flutter imports, the UI consumes data only through
Riverpod providers, and crash/export backends are injected via interfaces.
This makes it trivial to:

- swap the in-memory store for `FileBackedNetworkStore` or any custom sink
- substitute the crash reporter for Sentry, Bugsnag, or a custom logger
- forward every event to your own backend via `PulseEventExporter`
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

---

## 🧪 Test Observability

Track what happens inside each Flutter test — widget logs, API calls,
assertions, pump events, and performance snapshots — then review or export
the results from the inspector.

### Quick setup

```dart
// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_ops/pulse_ops.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await PulseOps.initialize(config: const PulseOpsConfig(enableInRelease: true));
    PulseTestObserver.attach(PulseOps.instance.testStore);
  });

  tearDownAll(() => PulseTestObserver.detach());

  group('auth', () {
    setUp(() => PulseTestObserver.beginTest('login success', group: 'auth'));
    tearDown(() => PulseTestObserver.endTest());

    testWidgets('user can log in', (tester) async {
      PulseTestObserver.log('pumping login screen');
      await tester.pumpWidget(const MyApp());
      PulseTestObserver.pump(frameCount: 1);

      PulseTestObserver.assertion('login button is visible');
      expect(find.text('Log in'), findsOneWidget);
    });
  });
}
```

### Capturing API calls during tests

```dart
// Wire captureNetworkRequest into your event exporter or store listener:
PulseOps.instance.store.stream.listen((records) {
  for (final r in records) {
    PulseTestObserver.captureNetworkRequest(r);
  }
});
```

### Exporting reports programmatically

```dart
final report = PulseTestObserver.exporter.export(
  PulseOps.instance.testStore.sessions,
  format: TestReportFormat.json,
);
File('test-report.json').writeAsStringSync(report);
```

### What's tracked per session

| Item | How |
| --- | --- |
| **Log messages** | `PulseTestObserver.log(message)` |
| **Assertions** | `PulseTestObserver.assertion(description)` |
| **Widget pumps** | `PulseTestObserver.pump(frameCount:)` |
| **Network calls** | `PulseTestObserver.captureNetworkRequest(record)` |
| **Performance** | `PulseTestObserver.capturePerformance(fps:, droppedFrames:)` |
| **Failures** | `PulseTestObserver.endTest(passed: false, failureMessage: ...)` |

---

## 🛣 Roadmap

- [x] Test observability — session tracking, API logs, timelines, report export *(v1.4)*
- [x] Memory monitoring — RSS, leaks, lifecycle, rebuild tracking *(v1.3)*
- [x] Persistent network store + unified event exporter *(v1.3)*
- [x] Real-time FPS monitor, frame drop detection, API latency chart *(v1.2)*
- [x] Shake-to-open, expandable bottom sheet, log export *(v1.1)*
- [ ] HTTP/2 + `http` package interceptor adapter
- [ ] Log inspector (debugPrint / `Logger`)
- [ ] Per-host throttling visualizer
- [ ] GC pressure & heap breakdown charts

---

## 📄 License

MIT — see `LICENSE`.

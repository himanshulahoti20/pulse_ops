import '../crash/breadcrumb.dart';
import '../network/models/network_record.dart';
import 'test_event.dart';
import 'test_report_exporter.dart';
import 'test_session.dart';
import 'test_store.dart';

/// Static helper for capturing test observability data from Flutter tests.
///
/// Attach a [TestStore] once (e.g. in `setUpAll`) then call [beginTest] /
/// [endTest] around each test and use [log], [pump], [assertion] inside it:
///
/// ```dart
/// void main() {
///   setUpAll(() => PulseTestObserver.attach(PulseOps.instance.testStore));
///
///   group('auth', () {
///     setUp(() => PulseTestObserver.beginTest('login success', group: 'auth'));
///     tearDown(() => PulseTestObserver.endTest());
///
///     test('login success', () async {
///       PulseTestObserver.log('submitting credentials');
///       // ...
///       PulseTestObserver.assertion('user token is set');
///     });
///   });
/// }
/// ```
class PulseTestObserver {
  PulseTestObserver._();

  static TestStore? _store;
  static const _exporter = TestReportExporter();

  static TestStore? get store => _store;
  static TestReportExporter get exporter => _exporter;

  /// Attaches a [TestStore] so observer calls are forwarded to it.
  static void attach(TestStore store) => _store = store;

  /// Detaches the current store.
  static void detach() => _store = null;

  /// Starts a new test session named [name].
  ///
  /// Throws [StateError] if no store has been attached via [attach].
  static TestSession beginTest(String name, {String? group}) {
    final s = _store;
    if (s == null) {
      throw StateError(
        'PulseTestObserver: call attach(store) before using the observer.',
      );
    }
    return s.beginSession(name, group: group);
  }

  /// Ends the active session.
  ///
  /// Pass [passed] = `false` together with [failureMessage] / [stackTrace]
  /// to record a failed test.
  static void endTest({
    bool passed = true,
    String? failureMessage,
    String? stackTrace,
  }) {
    _store?.endSession(
      passed: passed,
      failureMessage: failureMessage,
      stackTrace: stackTrace,
    );
  }

  /// Logs a freeform [message] into the active session.
  static void log(
    String message, {
    BreadcrumbLevel level = BreadcrumbLevel.info,
    Map<String, dynamic>? data,
  }) {
    _store?.logEvent(message, level: level, data: data);
  }

  /// Records a widget pump call in the active session.
  static void pump({int frameCount = 1, Duration? duration}) {
    _store?.logEvent(
      duration != null
          ? 'pump(${duration.inMilliseconds} ms)'
          : 'pump(×$frameCount)',
      type: TestEventType.widgetPump,
      data: <String, dynamic>{
        'frame_count': frameCount,
        if (duration != null) 'duration_ms': duration.inMilliseconds,
      },
    );
  }

  /// Records a named assertion result in the active session.
  static void assertion(String description, {bool passed = true}) {
    _store?.logEvent(
      description,
      type: TestEventType.assertion,
      level: passed ? BreadcrumbLevel.info : BreadcrumbLevel.error,
      data: <String, dynamic>{'passed': passed},
    );
  }

  /// Forwards a captured [NetworkRecord] to the active session.
  ///
  /// Wire this up alongside `PulseDioInterceptor` by implementing
  /// [PulseEventExporter.onFailedRequest] or by subscribing to the
  /// network store's stream inside your test setup.
  static void captureNetworkRequest(NetworkRecord record) {
    _store?.recordNetworkRequest(record);
  }

  /// Records an FPS / dropped-frame snapshot into the active session.
  static void capturePerformance({
    required double fps,
    required int droppedFrames,
    Map<String, dynamic>? extra,
  }) {
    _store?.recordPerformance(
      fps: fps,
      droppedFrames: droppedFrames,
      extra: extra,
    );
  }
}

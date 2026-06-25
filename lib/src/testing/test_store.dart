import 'dart:async';

import '../crash/breadcrumb.dart';
import '../network/models/network_record.dart';
import 'test_event.dart';
import 'test_session.dart';

/// In-memory ring-buffer store for [TestSession]s captured during test runs.
///
/// Use [beginSession] at the start of each test, [endSession] at the end,
/// and [logEvent] / [recordNetworkRequest] in between.  The [stream] emits
/// updated snapshots after every mutation.
class TestStore {
  TestStore({this.maxSessions = 100});

  final int maxSessions;

  final _sessions = <TestSession>[];
  final _controller = StreamController<List<TestSession>>.broadcast();
  TestSession? _active;

  List<TestSession> get sessions => List.unmodifiable(_sessions);
  TestSession? get activeSession => _active;
  Stream<List<TestSession>> get stream => _controller.stream;

  /// Starts a new session and returns it.  Any previous active session
  /// is implicitly abandoned (not ended) to allow for mid-test begins.
  TestSession beginSession(String name, {String? group}) {
    final session = TestSession(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      group: group,
      startedAt: DateTime.now(),
      status: TestSessionStatus.running,
    );
    _active = session;
    _insert(session);
    return session;
  }

  /// Finalises the active session.
  void endSession({
    bool passed = true,
    String? failureMessage,
    String? stackTrace,
  }) {
    final current = _active;
    if (current == null) return;
    _active = null;
    _replace(
      current.copyWith(
        status: passed ? TestSessionStatus.passed : TestSessionStatus.failed,
        endedAt: DateTime.now(),
        failureMessage: failureMessage,
        stackTrace: stackTrace,
      ),
    );
  }

  /// Appends a log [message] event to the active session.
  void logEvent(
    String message, {
    TestEventType type = TestEventType.log,
    BreadcrumbLevel level = BreadcrumbLevel.info,
    Duration? duration,
    Map<String, dynamic>? data,
  }) {
    _appendEvent(TestEvent(
      type: type,
      message: message,
      timestamp: DateTime.now(),
      level: level,
      duration: duration,
      data: data,
    ));
  }

  /// Attaches [record] to the active session and logs a network event for it.
  void recordNetworkRequest(NetworkRecord record) {
    final current = _active;
    if (current == null) return;
    final updated = current.copyWith(
      networkRequests: [...current.networkRequests, record],
    );
    _active = updated;
    _replace(updated);
    logEvent(
      'HTTP ${record.method} ${record.endpoint}'
      ' — ${record.statusCode ?? record.status.name}',
      type: TestEventType.networkRequest,
      level: record.isFailure ? BreadcrumbLevel.error : BreadcrumbLevel.info,
      duration: record.duration == Duration.zero ? null : record.duration,
      data: record.toSummaryMap(),
    );
  }

  /// Records an FPS / frame-drop snapshot into the active session.
  void recordPerformance({
    required double fps,
    required int droppedFrames,
    Map<String, dynamic>? extra,
  }) {
    _appendEvent(TestEvent(
      type: TestEventType.performance,
      message: 'FPS: ${fps.toStringAsFixed(1)}, dropped: $droppedFrames',
      timestamp: DateTime.now(),
      data: <String, dynamic>{
        'fps': fps,
        'dropped_frames': droppedFrames,
        if (extra != null) ...extra,
      },
    ));
  }

  void clear() {
    _sessions.clear();
    _active = null;
    _emit();
  }

  void dispose() {
    _controller.close();
  }

  // ── private ────────────────────────────────────────────────────────────────

  void _appendEvent(TestEvent event) {
    final current = _active;
    if (current == null) return;
    final updated = current.copyWith(
      events: [...current.events, event],
    );
    _active = updated;
    _replace(updated);
  }

  void _insert(TestSession session) {
    _sessions.insert(0, session);
    if (_sessions.length > maxSessions) _sessions.removeLast();
    _emit();
  }

  void _replace(TestSession updated) {
    final idx = _sessions.indexWhere((s) => s.id == updated.id);
    if (idx < 0) return;
    _sessions[idx] = updated;
    _emit();
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List.unmodifiable(_sessions));
    }
  }
}

import 'package:flutter/foundation.dart';

import '../network/models/network_record.dart';
import 'test_event.dart';

/// Lifecycle state of a [TestSession].
enum TestSessionStatus { running, passed, failed, skipped }

/// An immutable snapshot of a single test run, capturing its events,
/// network activity, and outcome.
@immutable
class TestSession {
  const TestSession({
    required this.id,
    required this.name,
    required this.startedAt,
    required this.status,
    this.group,
    this.endedAt,
    this.events = const [],
    this.networkRequests = const [],
    this.failureMessage,
    this.stackTrace,
  });

  final String id;
  final String name;

  /// Optional group / suite name (from `group(...)` in flutter_test).
  final String? group;

  final DateTime startedAt;
  final DateTime? endedAt;
  final TestSessionStatus status;
  final List<TestEvent> events;
  final List<NetworkRecord> networkRequests;
  final String? failureMessage;
  final String? stackTrace;

  Duration get duration {
    final end = endedAt;
    if (end == null) return Duration.zero;
    return end.difference(startedAt);
  }

  bool get isPassed => status == TestSessionStatus.passed;
  bool get isFailed => status == TestSessionStatus.failed;
  bool get isRunning => status == TestSessionStatus.running;
  bool get isSkipped => status == TestSessionStatus.skipped;

  TestSession copyWith({
    TestSessionStatus? status,
    DateTime? endedAt,
    List<TestEvent>? events,
    List<NetworkRecord>? networkRequests,
    String? failureMessage,
    String? stackTrace,
  }) {
    return TestSession(
      id: id,
      name: name,
      group: group,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      status: status ?? this.status,
      events: events ?? this.events,
      networkRequests: networkRequests ?? this.networkRequests,
      failureMessage: failureMessage ?? this.failureMessage,
      stackTrace: stackTrace ?? this.stackTrace,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        if (group != null) 'group': group,
        'status': status.name,
        'started_at': startedAt.toIso8601String(),
        if (endedAt != null) 'ended_at': endedAt!.toIso8601String(),
        'duration_ms': duration.inMilliseconds,
        'event_count': events.length,
        'network_request_count': networkRequests.length,
        if (failureMessage != null) 'failure_message': failureMessage,
        if (stackTrace != null) 'stack_trace': stackTrace,
        'events': events.map((e) => e.toJson()).toList(),
        'network_requests':
            networkRequests.map((r) => r.toSummaryMap()).toList(),
      };
}

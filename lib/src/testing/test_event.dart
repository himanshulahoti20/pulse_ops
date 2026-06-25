import 'package:flutter/foundation.dart';

import '../crash/breadcrumb.dart';

/// The type of event captured within a [TestSession].
enum TestEventType {
  log,
  networkRequest,
  assertion,
  widgetPump,
  failure,
  performance,
}

/// An immutable record of a single event captured during a [TestSession].
@immutable
class TestEvent {
  const TestEvent({
    required this.type,
    required this.message,
    required this.timestamp,
    this.duration,
    this.level = BreadcrumbLevel.info,
    this.data,
  });

  final TestEventType type;
  final String message;
  final DateTime timestamp;
  final Duration? duration;
  final BreadcrumbLevel level;
  final Map<String, dynamic>? data;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type.name,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        if (duration != null) 'duration_ms': duration!.inMilliseconds,
        'level': level.name,
        if (data != null) 'data': data,
      };
}

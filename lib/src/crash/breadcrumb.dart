import 'dart:collection';

import 'package:flutter/foundation.dart';

/// A single timestamped event captured into the crash breadcrumb trail.
@immutable
class Breadcrumb {
  Breadcrumb({
    required this.message,
    DateTime? timestamp,
    this.data,
    this.level = BreadcrumbLevel.info,
  }) : timestamp = timestamp ?? DateTime.now();

  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? data;
  final BreadcrumbLevel level;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'timestamp': timestamp.toIso8601String(),
        'level': level.name,
        'message': message,
        if (data != null) 'data': data,
      };

  @override
  String toString() =>
      '[${timestamp.toIso8601String()}] ${level.name.toUpperCase()} $message';
}

enum BreadcrumbLevel { debug, info, warning, error }

/// Bounded chronological trail of breadcrumbs.
///
/// New entries are appended to the tail; the head is evicted once capacity
/// is exceeded so the trail always reflects the most recent activity.
class BreadcrumbTrail {
  BreadcrumbTrail({this.maxEntries = 50});

  final int maxEntries;
  final Queue<Breadcrumb> _entries = Queue<Breadcrumb>();

  List<Breadcrumb> get entries => List.unmodifiable(_entries);

  void log(
    String message, {
    Map<String, dynamic>? data,
    BreadcrumbLevel level = BreadcrumbLevel.info,
  }) {
    _entries.addLast(Breadcrumb(message: message, data: data, level: level));
    while (_entries.length > maxEntries) {
      _entries.removeFirst();
    }
  }

  void clear() => _entries.clear();

  String formatForCrashReport() {
    if (_entries.isEmpty) return '<no breadcrumbs>';
    final buf = StringBuffer();
    for (final b in _entries) {
      buf.writeln(b.toString());
    }
    return buf.toString();
  }
}

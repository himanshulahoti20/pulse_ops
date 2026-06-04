import 'package:flutter/foundation.dart';

/// A point-in-time memory reading sampled by [MemoryMonitor].
@immutable
class MemorySnapshot {
  const MemorySnapshot({
    required this.timestamp,
    required this.rssBytes,
    this.isSpike = false,
  });

  final DateTime timestamp;

  /// Resident set size in bytes. Zero on platforms where it is not available
  /// (e.g. Web).
  final int rssBytes;

  /// Set to `true` by [MemoryMonitor] when this sample is >20% above the
  /// rolling average of the previous window.
  final bool isSpike;

  double get rssMb => rssBytes / (1024 * 1024);
}

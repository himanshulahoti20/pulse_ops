import 'package:flutter/foundation.dart';

/// A single captured frame's timing data.
@immutable
class FrameMetric {
  const FrameMetric({
    required this.timestamp,
    required this.totalDuration,
    required this.buildDuration,
    required this.rasterDuration,
  });

  final DateTime timestamp;
  final Duration totalDuration;
  final Duration buildDuration;
  final Duration rasterDuration;

  /// Estimated FPS based on total frame duration. Clamped to 0–120.
  double get fps {
    final ms = totalDuration.inMicroseconds / 1000.0;
    if (ms <= 0) return 60;
    return (1000.0 / ms).clamp(0.0, 120.0);
  }

  /// Frame took longer than 16.67 ms (below 60 fps).
  bool get isDropped => totalDuration.inMicroseconds > 16667;

  /// Frame took longer than 33.33 ms (below 30 fps) — severe jank.
  bool get isSevere => totalDuration.inMicroseconds > 33333;
}

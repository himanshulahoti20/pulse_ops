import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'frame_metric.dart';
import 'performance_store.dart';

/// Attaches to [WidgetsBinding] frame timings and feeds them into
/// [PerformanceStore].
class FpsTracker {
  FpsTracker(this._store);

  final PerformanceStore _store;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addTimingsCallback(_onTimings);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _store.markFirstFrame();
    });
  }

  void stop() {
    if (!_started) return;
    _started = false;
    WidgetsBinding.instance.removeTimingsCallback(_onTimings);
  }

  void _onTimings(List<FrameTiming> timings) {
    final now = DateTime.now();
    for (final t in timings) {
      _store.addFrame(FrameMetric(
        timestamp: now,
        totalDuration: t.totalSpan,
        buildDuration: t.buildDuration,
        rasterDuration: t.rasterDuration,
      ));
    }
  }
}

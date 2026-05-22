import 'dart:async';
import 'dart:collection';

import 'frame_metric.dart';

/// Holds the rolling frame-timing buffer and startup metrics.
class PerformanceStore {
  PerformanceStore({this.maxFrames = 300});

  final int maxFrames;

  final Queue<FrameMetric> _frames = Queue<FrameMetric>();
  final _controller =
      StreamController<List<FrameMetric>>.broadcast(sync: false);

  DateTime? _initTime;
  Duration? _startupTime;

  // ── public API ─────────────────────────────────────────────────────────────

  Stream<List<FrameMetric>> get stream => _controller.stream;
  List<FrameMetric> get frames => List.unmodifiable(_frames);

  /// Wall-clock time between [markInit] and the first rendered frame.
  Duration? get startupTime => _startupTime;

  void markInit() => _initTime = DateTime.now();

  void markFirstFrame() {
    if (_initTime != null && _startupTime == null) {
      _startupTime = DateTime.now().difference(_initTime!);
    }
  }

  void addFrame(FrameMetric metric) {
    _frames.addLast(metric);
    while (_frames.length > maxFrames) {
      _frames.removeFirst();
    }
    _emit();
  }

  /// Average FPS over the last [window] frames.
  double currentFps({int window = 15}) {
    if (_frames.isEmpty) return 60;
    final recent = _frames.toList().reversed.take(window).toList();
    final avgUs = recent
            .map((f) => f.totalDuration.inMicroseconds.toDouble())
            .reduce((a, b) => a + b) /
        recent.length;
    return avgUs <= 0 ? 60 : (1e6 / avgUs).clamp(0, 120);
  }

  int get droppedFrameCount => _frames.where((f) => f.isDropped).length;
  int get severeDropCount => _frames.where((f) => f.isSevere).length;

  List<FrameMetric> get droppedFrames =>
      _frames.where((f) => f.isDropped).toList();

  void dispose() {
    if (!_controller.isClosed) _controller.close();
  }

  void _emit() {
    if (_controller.isClosed) return;
    _controller.add(List.unmodifiable(_frames));
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';

import '_process_info_io.dart' if (dart.library.html) '_process_info_web.dart';
import 'memory_snapshot.dart';
import 'memory_store.dart';

/// Polls RSS memory and subscribes to [FlutterMemoryAllocations] to feed
/// [MemoryStore] with snapshots and object-lifecycle events.
class MemoryMonitor {
  MemoryMonitor(this._store, {this.sampleIntervalSeconds = 2});

  final MemoryStore _store;
  final int sampleIntervalSeconds;

  Timer? _timer;
  bool _started = false;

  // Rolling window for spike detection (last 10 samples).
  final List<int> _recentRss = [];

  void start() {
    if (_started) return;
    _started = true;

    if (kFlutterMemoryAllocationsEnabled) {
      FlutterMemoryAllocations.instance.addListener(_onObjectEvent);
    }

    _sample(); // immediate first reading
    _timer = Timer.periodic(
      Duration(seconds: sampleIntervalSeconds),
      (_) => _sample(),
    );
  }

  void stop() {
    if (!_started) return;
    _started = false;
    _timer?.cancel();
    _timer = null;
    if (kFlutterMemoryAllocationsEnabled) {
      FlutterMemoryAllocations.instance.removeListener(_onObjectEvent);
    }
  }

  // ── private ───────────────────────────────────────────────────────────────

  void _sample() {
    final rss = currentRssBytes();
    final isSpike = _detectSpike(rss);

    _recentRss.add(rss);
    if (_recentRss.length > 10) _recentRss.removeAt(0);

    _store.addSnapshot(MemorySnapshot(
      timestamp: DateTime.now(),
      rssBytes: rss,
      isSpike: isSpike,
    ));
  }

  bool _detectSpike(int rss) {
    if (_recentRss.length < 5 || rss == 0) return false;
    final avg = _recentRss.reduce((a, b) => a + b) / _recentRss.length;
    return avg > 0 && rss > avg * 1.20;
  }

  void _onObjectEvent(ObjectEvent event) {
    final token = identityHashCode(event.object).toRadixString(16);
    final type = event.object.runtimeType.toString();
    final library = event is ObjectCreated ? event.library : null;

    if (event is ObjectCreated) {
      _store.trackCreated(token, type, library: library);
    } else if (event is ObjectDisposed) {
      _store.trackDisposed(token);
    }
  }
}

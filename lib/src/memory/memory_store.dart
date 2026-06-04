import 'dart:async';
import 'dart:collection';

import 'memory_snapshot.dart';
import 'tracked_object.dart';

/// Holds rolling memory snapshots and tracked object lifecycle records.
class MemoryStore {
  MemoryStore({this.maxSnapshots = 120});

  final int maxSnapshots;

  final Queue<MemorySnapshot> _snapshots = Queue<MemorySnapshot>();
  final _snapshotController =
      StreamController<List<MemorySnapshot>>.broadcast(sync: false);

  // token → tracked object. Old disposed objects are pruned periodically.
  final Map<String, TrackedObject> _objects = {};
  final _objectController =
      StreamController<List<TrackedObject>>.broadcast(sync: false);

  // rebuild counts: widget type → count
  final Map<String, int> _rebuildCounts = {};

  Stream<List<MemorySnapshot>> get stream => _snapshotController.stream;
  Stream<List<TrackedObject>> get objectStream => _objectController.stream;

  List<MemorySnapshot> get snapshots => List.unmodifiable(_snapshots);

  /// Most recent RSS in bytes, or 0 if no data yet.
  int get currentRssBytes => _snapshots.isEmpty ? 0 : _snapshots.last.rssBytes;

  /// Peak RSS seen since monitoring started.
  int get peakRssBytes => _snapshots.isEmpty
      ? 0
      : _snapshots.map((s) => s.rssBytes).reduce((a, b) => a > b ? a : b);

  List<TrackedObject> get trackedObjects =>
      List.unmodifiable(_objects.values.toList());

  List<TrackedObject> get potentialLeaks =>
      _objects.values.where((o) => o.isPotentialLeak).toList()
        ..sort((a, b) => b.age.compareTo(a.age));

  Map<String, int> get rebuildCounts => Map.unmodifiable(_rebuildCounts);

  // ── snapshot ──────────────────────────────────────────────────────────────

  void addSnapshot(MemorySnapshot snapshot) {
    _snapshots.addLast(snapshot);
    while (_snapshots.length > maxSnapshots) {
      _snapshots.removeFirst();
    }
    if (!_snapshotController.isClosed) {
      _snapshotController.add(snapshots);
    }
  }

  // ── object lifecycle ──────────────────────────────────────────────────────

  void trackCreated(String token, String type, {String? library}) {
    _objects[token] = TrackedObject(
      token: token,
      type: type,
      createdAt: DateTime.now(),
      library: library,
    );
    _emitObjects();
  }

  void trackDisposed(String token) {
    final obj = _objects[token];
    if (obj == null) return;
    obj.disposed = true;
    obj.disposedAt = DateTime.now();
    _emitObjects();

    // Prune old disposed objects to avoid unbounded growth
    if (_objects.length > 500) {
      final stale = _objects.entries
          .where((e) => e.value.disposed)
          .map((e) => e.key)
          .take(100)
          .toList();
      stale.forEach(_objects.remove);
    }
  }

  // ── rebuild tracking ──────────────────────────────────────────────────────

  void recordRebuild(String widgetType) {
    _rebuildCounts[widgetType] = (_rebuildCounts[widgetType] ?? 0) + 1;
  }

  void resetRebuildCounts() => _rebuildCounts.clear();

  // ── housekeeping ──────────────────────────────────────────────────────────

  void _emitObjects() {
    if (!_objectController.isClosed) {
      _objectController.add(trackedObjects);
    }
  }

  void dispose() {
    if (!_snapshotController.isClosed) _snapshotController.close();
    if (!_objectController.isClosed) _objectController.close();
  }
}

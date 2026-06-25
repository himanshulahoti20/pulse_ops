import 'dart:async';
import 'dart:collection';

import '../models/network_record.dart';

/// In-memory ring-buffer store for captured network records.
///
/// Exposes a [stream] for reactive UIs and is designed so that an alternate
/// implementation (e.g. Isar/Hive backed) can be substituted by extending
/// [NetworkStore] without modifying callers.
abstract class NetworkStore {
  Stream<List<NetworkRecord>> get stream;
  List<NetworkRecord> get records;
  NetworkRecord? findById(String id);
  void add(NetworkRecord record);
  void update(NetworkRecord record);
  void clear();
  void dispose();
}

class InMemoryNetworkStore implements NetworkStore {
  InMemoryNetworkStore({this.maxRecords = 200});

  final int maxRecords;

  final Queue<NetworkRecord> _records = Queue<NetworkRecord>();

  // O(1) lookup index — kept in sync with _records.
  final Map<String, NetworkRecord> _index = {};

  final _controller =
      StreamController<List<NetworkRecord>>.broadcast(sync: false);

  @override
  Stream<List<NetworkRecord>> get stream => _controller.stream;

  @override
  List<NetworkRecord> get records => List.unmodifiable(_records);

  @override
  NetworkRecord? findById(String id) => _index[id];

  @override
  void add(NetworkRecord record) {
    _records.addFirst(record);
    _index[record.id] = record;
    if (_records.length > maxRecords) {
      final evicted = _records.removeLast();
      _index.remove(evicted.id);
    }
    _emit();
  }

  @override
  void update(NetworkRecord record) {
    if (!_index.containsKey(record.id)) {
      add(record);
      return;
    }
    _index[record.id] = record;
    final updated =
        _records.map((r) => r.id == record.id ? record : r).toList();
    _records
      ..clear()
      ..addAll(updated);
    _emit();
  }

  @override
  void clear() {
    _records.clear();
    _index.clear();
    _emit();
  }

  @override
  void dispose() {
    _controller.close();
  }

  void _emit() {
    if (_controller.isClosed) return;
    _controller.add(List.unmodifiable(_records));
  }
}

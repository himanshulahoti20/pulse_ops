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
  final _controller =
      StreamController<List<NetworkRecord>>.broadcast(sync: false);

  @override
  Stream<List<NetworkRecord>> get stream => _controller.stream;

  @override
  List<NetworkRecord> get records => List.unmodifiable(_records);

  @override
  NetworkRecord? findById(String id) {
    for (final r in _records) {
      if (r.id == id) return r;
    }
    return null;
  }

  @override
  void add(NetworkRecord record) {
    _records.addFirst(record);
    while (_records.length > maxRecords) {
      _records.removeLast();
    }
    _emit();
  }

  @override
  void update(NetworkRecord record) {
    final updated = <NetworkRecord>[];
    var replaced = false;
    for (final r in _records) {
      if (r.id == record.id) {
        updated.add(record);
        replaced = true;
      } else {
        updated.add(r);
      }
    }
    if (!replaced) {
      add(record);
      return;
    }
    _records
      ..clear()
      ..addAll(updated);
    _emit();
  }

  @override
  void clear() {
    _records.clear();
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

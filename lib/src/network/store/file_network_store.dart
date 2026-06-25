import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/network_record.dart';
import 'network_store.dart';

/// A [NetworkStore] that persists records to a JSON file in the app's
/// documents directory. On first [initialize] it restores any previously
/// captured records, so the inspector survives app restarts.
///
/// Usage:
/// ```dart
/// final store = FileBackedNetworkStore(maxRecords: 200);
/// await store.initialize();
/// await PulseOps.initialize(networkStore: store);
/// ```
class FileBackedNetworkStore extends InMemoryNetworkStore {
  FileBackedNetworkStore({super.maxRecords});

  static const _kFileName = 'pulse_ops_network_log.json';

  File? _file;
  bool _initialized = false;

  /// Loads persisted records from disk. Must be called once before use.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final dir = await getApplicationDocumentsDirectory();
      _file = File('${dir.path}/$_kFileName');
      if (await _file!.exists()) {
        final raw = await _file!.readAsString();
        final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        // Restore oldest-first so the in-memory store ends up newest-first
        for (final json in list.reversed) {
          super.add(NetworkRecord.fromJson(json));
        }
      }
    } catch (_) {
      // Corrupt / missing file — start fresh
    }
  }

  @override
  void add(NetworkRecord record) {
    super.add(record);
    _persist();
  }

  @override
  void update(NetworkRecord record) {
    super.update(record);
    _persist();
  }

  @override
  void clear() {
    super.clear();
    _file?.writeAsStringSync('[]', flush: true);
  }

  void _persist() {
    final file = _file;
    if (file == null) return;
    try {
      final json = jsonEncode(
        records.map((r) => r.toJson()).toList(growable: false),
      );
      file.writeAsStringSync(json, flush: true);
    } catch (_) {
      // Disk full / permissions error — silently skip to avoid crashing the app.
    }
  }
}

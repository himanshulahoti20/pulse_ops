import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/pulse_ops_config.dart';
import '../crash/crash_diagnostics.dart';
import '../network/models/network_record.dart';
import '../network/store/network_store.dart';

/// Public Riverpod providers used by the inspector UI.
///
/// These providers are initialized inside the [PulseOpsScope] that wraps the
/// inspector — they are not intended to be overridden from host apps.
final pulseOpsConfigProvider = Provider<PulseOpsConfig>((ref) {
  throw UnimplementedError('PulseOpsConfig must be provided via overrides');
});

final networkStoreProvider = Provider<NetworkStore>((ref) {
  throw UnimplementedError('NetworkStore must be provided via overrides');
});

final crashDiagnosticsProvider = Provider<CrashDiagnostics>((ref) {
  throw UnimplementedError('CrashDiagnostics must be provided via overrides');
});

/// Reactive list of captured records.
final networkRecordsProvider = StreamProvider<List<NetworkRecord>>((ref) {
  final store = ref.watch(networkStoreProvider);
  return store.stream.asBroadcastStream();
});

/// Filter state used by the inspector list.
class InspectorFilter {
  const InspectorFilter({
    this.search = '',
    this.method,
    this.failedOnly = false,
  });

  final String search;
  final String? method;
  final bool failedOnly;

  InspectorFilter copyWith({
    String? search,
    String? method,
    bool? failedOnly,
    bool clearMethod = false,
  }) {
    return InspectorFilter(
      search: search ?? this.search,
      method: clearMethod ? null : (method ?? this.method),
      failedOnly: failedOnly ?? this.failedOnly,
    );
  }

  bool matches(NetworkRecord r) {
    if (method != null && r.method.toUpperCase() != method!.toUpperCase()) {
      return false;
    }
    if (failedOnly && !r.isFailure) return false;
    if (search.isNotEmpty) {
      final q = search.toLowerCase();
      final haystack =
          '${r.method} ${r.url} ${r.statusCode ?? ''}'.toLowerCase();
      if (!haystack.contains(q)) return false;
    }
    return true;
  }
}

class InspectorFilterController extends Notifier<InspectorFilter> {
  @override
  InspectorFilter build() => const InspectorFilter();

  void update(InspectorFilter Function(InspectorFilter) cb) {
    state = cb(state);
  }
}

final inspectorFilterProvider =
    NotifierProvider<InspectorFilterController, InspectorFilter>(
  InspectorFilterController.new,
);

final filteredRecordsProvider = Provider<List<NetworkRecord>>((ref) {
  final filter = ref.watch(inspectorFilterProvider);
  final async = ref.watch(networkRecordsProvider);
  return async.maybeWhen(
    data: (records) => records.where(filter.matches).toList(growable: false),
    orElse: () => const <NetworkRecord>[],
  );
});

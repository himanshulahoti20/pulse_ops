import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/pulse_ops_config.dart';
import '../crash/crash_diagnostics.dart';
import '../network/models/network_record.dart';
import '../network/store/network_store.dart';
import '../performance/frame_metric.dart';
import '../performance/performance_store.dart';

/// Public Riverpod providers used by the inspector UI.
final pulseOpsConfigProvider = Provider<PulseOpsConfig>((ref) {
  throw UnimplementedError('PulseOpsConfig must be provided via overrides');
});

final networkStoreProvider = Provider<NetworkStore>((ref) {
  throw UnimplementedError('NetworkStore must be provided via overrides');
});

final crashDiagnosticsProvider = Provider<CrashDiagnostics>((ref) {
  throw UnimplementedError('CrashDiagnostics must be provided via overrides');
});

final performanceStoreProvider = Provider<PerformanceStore>((ref) {
  throw UnimplementedError('PerformanceStore must be provided via overrides');
});

// ── Network ────────────────────────────────────────────────────────────────

/// Reactive list of captured network records (newest first).
final networkRecordsProvider = StreamProvider<List<NetworkRecord>>((ref) {
  final store = ref.watch(networkStoreProvider);
  return store.stream.asBroadcastStream();
});

// ── Performance ────────────────────────────────────────────────────────────

/// Reactive list of frame metrics from [PerformanceStore].
final frameMetricsProvider = StreamProvider<List<FrameMetric>>((ref) {
  final store = ref.watch(performanceStoreProvider);
  return store.stream.asBroadcastStream();
});

// ── Inspector filter ───────────────────────────────────────────────────────

/// Status-code family used for grouping filter chips.
enum StatusFamily { all, s2xx, s3xx, s4xx, s5xx }

class InspectorFilter {
  const InspectorFilter({
    this.search = '',
    this.method,
    this.failedOnly = false,
    this.slowOnly = false,
    this.groupByHost = false,
    this.statusFamily = StatusFamily.all,
  });

  final String search;
  final String? method;
  final bool failedOnly;
  final bool slowOnly;
  final bool groupByHost;
  final StatusFamily statusFamily;

  InspectorFilter copyWith({
    String? search,
    String? method,
    bool? failedOnly,
    bool? slowOnly,
    bool? groupByHost,
    StatusFamily? statusFamily,
    bool clearMethod = false,
  }) {
    return InspectorFilter(
      search: search ?? this.search,
      method: clearMethod ? null : (method ?? this.method),
      failedOnly: failedOnly ?? this.failedOnly,
      slowOnly: slowOnly ?? this.slowOnly,
      groupByHost: groupByHost ?? this.groupByHost,
      statusFamily: statusFamily ?? this.statusFamily,
    );
  }

  bool matches(NetworkRecord r, {int slowThresholdMs = 2000}) {
    if (method != null && r.method.toUpperCase() != method!.toUpperCase()) {
      return false;
    }
    if (failedOnly && !r.isFailure) return false;
    if (slowOnly && r.duration.inMilliseconds < slowThresholdMs) return false;
    if (statusFamily != StatusFamily.all) {
      final code = r.statusCode;
      if (code == null) return false;
      switch (statusFamily) {
        case StatusFamily.s2xx:
          if (code < 200 || code >= 300) return false;
        case StatusFamily.s3xx:
          if (code < 300 || code >= 400) return false;
        case StatusFamily.s4xx:
          if (code < 400 || code >= 500) return false;
        case StatusFamily.s5xx:
          if (code < 500) return false;
        case StatusFamily.all:
          break;
      }
    }
    if (search.isNotEmpty) {
      final q = search.toLowerCase();
      final haystack = '${r.method} ${r.url} ${r.host} ${r.statusCode ?? ''} '
              '${r.error ?? ''}'
          .toLowerCase();
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
  final config = ref.watch(pulseOpsConfigProvider);
  final async = ref.watch(networkRecordsProvider);
  return async.maybeWhen(
    data: (records) => records
        .where((r) =>
            filter.matches(r, slowThresholdMs: config.slowRequestThresholdMs))
        .toList(growable: false),
    orElse: () => const <NetworkRecord>[],
  );
});

/// Records grouped by host. Preserves original ordering within each group.
final groupedRecordsProvider =
    Provider<Map<String, List<NetworkRecord>>>((ref) {
  final records = ref.watch(filteredRecordsProvider);
  final result = <String, List<NetworkRecord>>{};
  for (final r in records) {
    (result[r.host.isEmpty ? 'unknown' : r.host] ??= []).add(r);
  }
  return result;
});

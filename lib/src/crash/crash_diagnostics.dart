import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/pulse_ops_config.dart';
import '../network/store/network_store.dart';
import 'breadcrumb.dart';
import 'crash_reporter.dart';

/// Glue layer that combines a [PulseCrashReporter], a [BreadcrumbTrail],
/// and the in-memory [NetworkStore] into a single diagnostics surface.
class CrashDiagnostics {
  CrashDiagnostics({
    required PulseCrashReporter reporter,
    required BreadcrumbTrail breadcrumbs,
    required NetworkStore networkStore,
    required PulseOpsConfig config,
  })  : _reporter = reporter,
        _breadcrumbs = breadcrumbs,
        _store = networkStore,
        _config = config;

  final PulseCrashReporter _reporter;
  final BreadcrumbTrail _breadcrumbs;
  final NetworkStore _store;
  final PulseOpsConfig _config;

  BreadcrumbTrail get breadcrumbs => _breadcrumbs;
  PulseCrashReporter get reporter => _reporter;

  /// Manually log a breadcrumb. Useful at high-signal moments such as
  /// successful login, navigation events, or feature-flag toggles.
  void log(
    String message, {
    Map<String, dynamic>? data,
    BreadcrumbLevel level = BreadcrumbLevel.info,
  }) {
    _breadcrumbs.log(message, data: data, level: level);
  }

  /// Report an arbitrary error to the configured backend with the current
  /// breadcrumb trail and recent network activity attached.
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
    Map<String, dynamic>? extra,
  }) async {
    final context = <String, dynamic>{
      if (extra != null) ...extra,
      if (_config.attachNetworkHistoryToCrashes)
        'pulse_ops_recent_requests': _recentRequestSummaries(),
      'pulse_ops_breadcrumbs': _breadcrumbs.entries
          .map((b) => b.toMap())
          .toList(growable: false),
    };

    try {
      await _reporter.attachBreadcrumbs(_breadcrumbs.entries);
      if (_config.attachNetworkHistoryToCrashes) {
        await _reporter.attachNetworkHistory(_store.records);
      }
      if (fatal) {
        await _reporter.recordFatal(
          error,
          stackTrace: stackTrace,
          context: context,
        );
      } else {
        await _reporter.recordNonFatal(
          error,
          stackTrace: stackTrace,
          reason: reason,
          context: context,
        );
      }
    } catch (e, st) {
      debugPrint('PulseOps: failed to report error: $e\n$st');
    }
  }

  /// Install global handlers so all uncaught Flutter and zone errors are
  /// piped through PulseOps. Safe to call multiple times — only the most
  /// recent installation is active.
  void installGlobalErrorHandlers() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      recordError(
        details.exception,
        details.stack,
        reason: details.context?.toDescription(),
        fatal: true,
      );
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      recordError(error, stack, fatal: true);
      return true;
    };
  }

  List<Map<String, dynamic>> _recentRequestSummaries() {
    return _store.records
        .take(20)
        .map((r) => r.toSummaryMap())
        .toList(growable: false);
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../crash/breadcrumb.dart';
import '../crash/crash_diagnostics.dart';
import '../crash/crash_reporter.dart';
import '../network/interceptor/pulse_dio_interceptor.dart';
import '../network/store/network_store.dart';
import '../performance/fps_tracker.dart';
import '../performance/performance_store.dart';
import '../providers/providers.dart';
import '../ui/overlay/pulse_overlay.dart';
import 'pulse_ops_config.dart';

/// Entry point for the PulseOps SDK.
///
/// Lifecycle:
///   1. `await PulseOps.initialize(...)` — once, during `main()`.
///   2. Attach `PulseOps.instance.dioInterceptor` to your Dio instances.
///   3. Wrap your app with `PulseOps.instance.wrap(child: MyApp())` to render
///      the floating overlay, or push the inspector manually with
///      `PulseOps.instance.openInspector(context)`.
class PulseOps {
  PulseOps._({
    required this.config,
    required this.store,
    required this.crashDiagnostics,
    required this.breadcrumbs,
    required this.dioInterceptor,
    required this.enabled,
    required this.performanceStore,
  });

  static PulseOps? _instance;

  /// Returns the singleton. Throws if [initialize] has not been called.
  static PulseOps get instance {
    final i = _instance;
    if (i == null) {
      throw StateError(
        'PulseOps has not been initialized. Call PulseOps.initialize() in main().',
      );
    }
    return i;
  }

  /// Whether PulseOps has been initialized (useful for guarded retries).
  static bool get isInitialized => _instance != null;

  final PulseOpsConfig config;
  final NetworkStore store;
  final CrashDiagnostics crashDiagnostics;
  final BreadcrumbTrail breadcrumbs;
  final PulseDioInterceptor dioInterceptor;
  final PerformanceStore performanceStore;

  /// `false` when running in release mode without [PulseOpsConfig.enableInRelease].
  /// In that state PulseOps becomes a no-op shell so production builds pay
  /// (almost) nothing.
  final bool enabled;

  /// Initialize the SDK. Safe to call exactly once. Subsequent calls return
  /// the existing instance.
  ///
  /// Pass [crashReporter] to wire up Firebase Crashlytics, Sentry, or any
  /// other backend. When omitted, errors are routed to `debugPrint`.
  static Future<PulseOps> initialize({
    PulseOpsConfig config = const PulseOpsConfig(),
    PulseCrashReporter? crashReporter,
    bool installGlobalErrorHandlers = true,
    bool? crashlytics,
    bool? enableInRelease,
    List<String>? sanitizeKeys,
  }) async {
    if (_instance != null) return _instance!;

    final effectiveConfig = config.copyWith(
      enableInRelease: enableInRelease ?? config.enableInRelease,
      sanitizeKeys: sanitizeKeys ?? config.sanitizeKeys,
      captureFailedRequestsAsCrashEvents:
          crashlytics ?? config.captureFailedRequestsAsCrashEvents,
      attachNetworkHistoryToCrashes:
          crashlytics ?? config.attachNetworkHistoryToCrashes,
    );

    final enabled = kDebugMode || effectiveConfig.enableInRelease;

    final store = InMemoryNetworkStore(maxRecords: effectiveConfig.maxRecords);
    final breadcrumbs =
        BreadcrumbTrail(maxEntries: effectiveConfig.maxBreadcrumbs);
    final reporter = crashReporter ?? const NoopCrashReporter();
    final diagnostics = CrashDiagnostics(
      reporter: reporter,
      breadcrumbs: breadcrumbs,
      networkStore: store,
      config: effectiveConfig,
    );
    final interceptor = PulseDioInterceptor(
      store: store,
      config: effectiveConfig,
      crashReporter: reporter,
      breadcrumbs: breadcrumbs,
    );

    final perfStore = PerformanceStore(
        maxFrames: effectiveConfig.fpsFrameBufferSize);
    perfStore.markInit();

    if (installGlobalErrorHandlers && enabled) {
      diagnostics.installGlobalErrorHandlers();
    }

    if (enabled && effectiveConfig.enableFpsMonitor) {
      FpsTracker(perfStore).start();
    }

    _instance = PulseOps._(
      config: effectiveConfig,
      store: store,
      crashDiagnostics: diagnostics,
      breadcrumbs: breadcrumbs,
      dioInterceptor: interceptor,
      enabled: enabled,
      performanceStore: perfStore,
    );

    return _instance!;
  }

  /// Wraps a widget tree to host the floating overlay launcher and the
  /// Riverpod scope used by the inspector.
  ///
  /// Pass [retryDio] to enable one-tap retry from the inspector — typically
  /// your app's authenticated Dio instance.
  Widget wrap({required Widget child, Dio? retryDio}) {
    if (!enabled) return child;
    return ProviderScope(
      overrides: [
        pulseOpsConfigProvider.overrideWithValue(config),
        networkStoreProvider.overrideWithValue(store),
        crashDiagnosticsProvider.overrideWithValue(crashDiagnostics),
        performanceStoreProvider.overrideWithValue(performanceStore),
      ],
      child: PulseOverlay(
        config: config,
        store: store,
        crashDiagnostics: crashDiagnostics,
        performanceStore: performanceStore,
        retryDio: retryDio,
        child: child,
      ),
    );
  }

  /// Imperatively push the inspector. Useful when the overlay is disabled or
  /// you want to surface the inspector from a debug menu.
  Future<void> openInspector(BuildContext context, {Dio? retryDio}) {
    return showPulseInspector(
      context,
      config: config,
      store: store,
      crashDiagnostics: crashDiagnostics,
      performanceStore: performanceStore,
      retryDio: retryDio,
    );
  }

  /// Convenience pass-through: add a breadcrumb.
  void log(
    String message, {
    Map<String, dynamic>? data,
    BreadcrumbLevel level = BreadcrumbLevel.info,
  }) =>
      crashDiagnostics.log(message, data: data, level: level);

  /// Convenience pass-through: report an error.
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
    Map<String, dynamic>? extra,
  }) =>
      crashDiagnostics.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: fatal,
        extra: extra,
      );

  /// Test-only reset.
  @visibleForTesting
  static Future<void> reset() async {
    _instance?.store.dispose();
    _instance?.performanceStore.dispose();
    _instance = null;
  }
}

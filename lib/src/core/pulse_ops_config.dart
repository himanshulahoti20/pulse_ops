import 'package:flutter/foundation.dart';

/// Configuration for the PulseOps runtime.
///
/// Pass an instance to [PulseOps.initialize] to override defaults.
@immutable
class PulseOpsConfig {
  const PulseOpsConfig({
    this.enableInRelease = false,
    this.maxRecords = 200,
    this.maxBreadcrumbs = 50,
    this.sanitizeKeys = const <String>[
      'authorization',
      'token',
      'access_token',
      'refresh_token',
      'password',
      'api_key',
      'apikey',
      'x-api-key',
      'cookie',
      'set-cookie',
    ],
    this.attachNetworkHistoryToCrashes = true,
    this.showOverlay = true,
    this.captureFailedRequestsAsCrashEvents = true,
  });

  /// Whether PulseOps should remain active in release builds.
  ///
  /// Defaults to `false`. In release builds, the inspector and overlay are
  /// disabled to avoid leaking sensitive request/response data to end users.
  final bool enableInRelease;

  /// Maximum number of network records held in memory.
  ///
  /// Older records are evicted when this limit is reached.
  final int maxRecords;

  /// Maximum number of breadcrumbs retained for crash reporting.
  final int maxBreadcrumbs;

  /// Header / body keys whose values should be redacted from inspector views,
  /// breadcrumbs, and crash reports.
  ///
  /// Matching is case-insensitive.
  final List<String> sanitizeKeys;

  /// When `true`, the most recent network activity is attached as crash
  /// context whenever a crash is reported.
  final bool attachNetworkHistoryToCrashes;

  /// Whether to render the floating overlay launcher.
  final bool showOverlay;

  /// When `true`, failed network requests are forwarded to the configured
  /// [PulseCrashReporter] as non-fatal errors.
  final bool captureFailedRequestsAsCrashEvents;

  PulseOpsConfig copyWith({
    bool? enableInRelease,
    int? maxRecords,
    int? maxBreadcrumbs,
    List<String>? sanitizeKeys,
    bool? attachNetworkHistoryToCrashes,
    bool? showOverlay,
    bool? captureFailedRequestsAsCrashEvents,
  }) {
    return PulseOpsConfig(
      enableInRelease: enableInRelease ?? this.enableInRelease,
      maxRecords: maxRecords ?? this.maxRecords,
      maxBreadcrumbs: maxBreadcrumbs ?? this.maxBreadcrumbs,
      sanitizeKeys: sanitizeKeys ?? this.sanitizeKeys,
      attachNetworkHistoryToCrashes:
          attachNetworkHistoryToCrashes ?? this.attachNetworkHistoryToCrashes,
      showOverlay: showOverlay ?? this.showOverlay,
      captureFailedRequestsAsCrashEvents: captureFailedRequestsAsCrashEvents ??
          this.captureFailedRequestsAsCrashEvents,
    );
  }
}

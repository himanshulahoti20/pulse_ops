import 'package:flutter/foundation.dart';

/// How the inspector is presented when the overlay launcher is tapped or
/// [PulseOps.openInspector] is called.
enum InspectorPresentation {
  /// Slide up as an expandable, draggable bottom sheet (default).
  bottomSheet,

  /// Push as a full-screen dialog route.
  fullScreen,
}

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
    this.enableShakeToOpen = true,
    this.shakeThreshold = 22.0,
    this.inspectorPresentation = InspectorPresentation.bottomSheet,
    this.enableFpsMonitor = true,
    this.fpsFrameBufferSize = 300,
    this.slowRequestThresholdMs = 2000,
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

  /// When `true`, shaking the device opens the inspector. Requires the
  /// `sensors_plus` plugin to have an accelerometer available on the host
  /// platform.
  final bool enableShakeToOpen;

  /// Acceleration magnitude (in m/s²) that the device must exceed to register
  /// a shake. The default of `22.0` filters out everyday motion while still
  /// triggering on a deliberate flick.
  final double shakeThreshold;

  /// Controls how the inspector route appears. Defaults to an expandable
  /// bottom sheet; set to [InspectorPresentation.fullScreen] for the legacy
  /// full-screen dialog behavior.
  final InspectorPresentation inspectorPresentation;

  /// When `true`, the FPS tracker subscribes to [WidgetsBinding] frame
  /// timings and feeds the [PerformanceStore].
  final bool enableFpsMonitor;

  /// Number of frame timing samples kept in memory. Older entries are evicted
  /// once the buffer is full.
  final int fpsFrameBufferSize;

  /// Network requests whose round-trip duration exceeds this value (in
  /// milliseconds) are flagged as slow in the inspector.
  final int slowRequestThresholdMs;

  PulseOpsConfig copyWith({
    bool? enableInRelease,
    int? maxRecords,
    int? maxBreadcrumbs,
    List<String>? sanitizeKeys,
    bool? attachNetworkHistoryToCrashes,
    bool? showOverlay,
    bool? captureFailedRequestsAsCrashEvents,
    bool? enableShakeToOpen,
    double? shakeThreshold,
    InspectorPresentation? inspectorPresentation,
    bool? enableFpsMonitor,
    int? fpsFrameBufferSize,
    int? slowRequestThresholdMs,
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
      enableShakeToOpen: enableShakeToOpen ?? this.enableShakeToOpen,
      shakeThreshold: shakeThreshold ?? this.shakeThreshold,
      inspectorPresentation:
          inspectorPresentation ?? this.inspectorPresentation,
      enableFpsMonitor: enableFpsMonitor ?? this.enableFpsMonitor,
      fpsFrameBufferSize: fpsFrameBufferSize ?? this.fpsFrameBufferSize,
      slowRequestThresholdMs:
          slowRequestThresholdMs ?? this.slowRequestThresholdMs,
    );
  }
}

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Listens to device accelerometer events and invokes [onShake] whenever a
/// shake gesture is detected.
///
/// The detector subscribes to [accelerometerEventStream] on mount and cancels
/// the subscription on dispose. If the host platform does not provide
/// accelerometer events the detector silently no-ops.
class ShakeDetector extends StatefulWidget {
  const ShakeDetector({
    super.key,
    required this.onShake,
    required this.child,
    this.enabled = true,
    this.threshold = 22.0,
    this.cooldown = const Duration(milliseconds: 800),
    this.samplingPeriod = const Duration(milliseconds: 50),
  });

  final VoidCallback onShake;
  final Widget child;

  /// When `false` no accelerometer stream is opened.
  final bool enabled;

  /// Magnitude (m/s²) that the accelerometer vector must exceed — gravity
  /// already accounts for ~9.8, so the default of 22 corresponds to a clearly
  /// intentional shake.
  final double threshold;

  /// Minimum gap between consecutive shake events.
  final Duration cooldown;

  /// Requested accelerometer sampling period.
  final Duration samplingPeriod;

  @override
  State<ShakeDetector> createState() => _ShakeDetectorState();
}

class _ShakeDetectorState extends State<ShakeDetector> {
  StreamSubscription<AccelerometerEvent>? _subscription;
  DateTime _lastShake = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _subscribe();
  }

  @override
  void didUpdateWidget(covariant ShakeDetector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled ||
        oldWidget.samplingPeriod != widget.samplingPeriod) {
      _subscription?.cancel();
      _subscription = null;
      if (widget.enabled) _subscribe();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _subscribe() {
    try {
      _subscription = accelerometerEventStream(
        samplingPeriod: widget.samplingPeriod,
      ).listen(
        _onEvent,
        onError: (Object _) {/* sensor unavailable; ignore */},
        cancelOnError: true,
      );
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('PulseOps shake detector unavailable: $e\n$s');
      }
    }
  }

  void _onEvent(AccelerometerEvent event) {
    final magnitude = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    if (magnitude < widget.threshold) return;
    final now = DateTime.now();
    if (now.difference(_lastShake) < widget.cooldown) return;
    _lastShake = now;
    widget.onShake();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

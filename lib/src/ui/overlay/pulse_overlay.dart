import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/pulse_ops_config.dart';
import '../../crash/crash_diagnostics.dart';
import '../../network/store/network_store.dart';
import '../../performance/performance_store.dart';
import '../../providers/providers.dart';
import '../inspector/inspector_screen.dart';
import '../theme/pulse_theme.dart';
import 'shake_detector.dart';

/// Presents the inspector for [PulseOverlay] and [PulseOps.openInspector]
/// using the strategy configured in [PulseOpsConfig.inspectorPresentation].
Future<void> showPulseInspector(
  BuildContext context, {
  required PulseOpsConfig config,
  required NetworkStore store,
  required CrashDiagnostics crashDiagnostics,
  required PerformanceStore performanceStore,
  Dio? retryDio,
}) {
  final navigator = Navigator.of(context, rootNavigator: true);
  final overrides = [
    pulseOpsConfigProvider.overrideWithValue(config),
    networkStoreProvider.overrideWithValue(store),
    crashDiagnosticsProvider.overrideWithValue(crashDiagnostics),
    performanceStoreProvider.overrideWithValue(performanceStore),
  ];

  if (config.inspectorPresentation == InspectorPresentation.fullScreen) {
    return navigator.push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => ProviderScope(
          overrides: overrides,
          child: Theme(
            data: PulseTheme.build(),
            child: InspectorScreen(retryDio: retryDio),
          ),
        ),
      ),
    );
  }

  return showModalBottomSheet<void>(
    context: navigator.context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => ProviderScope(
      overrides: overrides,
      child: Theme(
        data: PulseTheme.build(),
        child: _InspectorSheet(retryDio: retryDio),
      ),
    ),
  );
}

class _InspectorSheet extends StatelessWidget {
  const _InspectorSheet({this.retryDio});

  final Dio? retryDio;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.4, 0.7, 0.95],
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
          child: ColoredBox(
            color: PulseTheme.background,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 4),
                  height: 4,
                  width: 44,
                  decoration: BoxDecoration(
                    color: PulseTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: InspectorScreen(
                    retryDio: retryDio,
                    scrollController: scrollController,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Draggable, dismissible floating launcher that opens the inspector.
class PulseOverlay extends StatefulWidget {
  const PulseOverlay({
    super.key,
    required this.child,
    required this.config,
    required this.store,
    required this.crashDiagnostics,
    required this.performanceStore,
    this.retryDio,
  });

  final Widget child;
  final PulseOpsConfig config;
  final NetworkStore store;
  final CrashDiagnostics crashDiagnostics;
  final PerformanceStore performanceStore;
  final Dio? retryDio;

  @override
  State<PulseOverlay> createState() => _PulseOverlayState();
}

class _PulseOverlayState extends State<PulseOverlay> {
  Offset _offset = const Offset(20, 200);
  bool _inspectorOpen = false;

  @override
  Widget build(BuildContext context) {
    Widget tree = widget.child;
    if (widget.config.showOverlay) {
      tree = Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          textDirection: TextDirection.ltr,
          children: [
            tree,
            Positioned(
              left: _offset.dx,
              top: _offset.dy,
              child: GestureDetector(
                onPanUpdate: (details) {
                  final size = MediaQuery.of(context).size;
                  setState(() {
                    _offset = Offset(
                      (_offset.dx + details.delta.dx)
                          .clamp(8.0, size.width - 64),
                      (_offset.dy + details.delta.dy)
                          .clamp(40.0, size.height - 80),
                    );
                  });
                },
                child: _OverlayButton(onTap: _open),
              ),
            ),
          ],
        ),
      );
    }
    return ShakeDetector(
      enabled: widget.config.enableShakeToOpen,
      threshold: widget.config.shakeThreshold,
      onShake: _open,
      child: tree,
    );
  }

  Future<void> _open() async {
    if (_inspectorOpen || !mounted) return;
    _inspectorOpen = true;
    try {
      await showPulseInspector(
        context,
        config: widget.config,
        store: widget.store,
        crashDiagnostics: widget.crashDiagnostics,
        performanceStore: widget.performanceStore,
        retryDio: widget.retryDio,
      );
    } finally {
      _inspectorOpen = false;
    }
  }
}

class _OverlayButton extends StatelessWidget {
  const _OverlayButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: PulseTheme.surface,
            shape: BoxShape.circle,
            border: Border.all(color: PulseTheme.accent.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: PulseTheme.accent.withValues(alpha: 0.25),
                blurRadius: 14,
                spreadRadius: -2,
              ),
            ],
          ),
          child: const Icon(
            Icons.graphic_eq_rounded,
            color: PulseTheme.accent,
            size: 22,
          ),
        ),
      ),
    );
  }
}

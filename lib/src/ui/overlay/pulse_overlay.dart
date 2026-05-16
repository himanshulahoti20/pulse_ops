import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/pulse_ops_config.dart';
import '../../crash/crash_diagnostics.dart';
import '../../network/store/network_store.dart';
import '../../providers/providers.dart';
import '../inspector/inspector_screen.dart';
import '../theme/pulse_theme.dart';

/// Draggable, dismissible floating launcher that opens the inspector.
class PulseOverlay extends StatefulWidget {
  const PulseOverlay({
    super.key,
    required this.child,
    required this.config,
    required this.store,
    required this.crashDiagnostics,
    this.retryDio,
  });

  final Widget child;
  final PulseOpsConfig config;
  final NetworkStore store;
  final CrashDiagnostics crashDiagnostics;
  final Dio? retryDio;

  @override
  State<PulseOverlay> createState() => _PulseOverlayState();
}

class _PulseOverlayState extends State<PulseOverlay> {
  Offset _offset = const Offset(20, 200);

  @override
  Widget build(BuildContext context) {
    if (!widget.config.showOverlay) return widget.child;
    return Stack(
      children: [
        widget.child,
        Positioned(
          left: _offset.dx,
          top: _offset.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              final size = MediaQuery.of(context).size;
              setState(() {
                _offset = Offset(
                  (_offset.dx + details.delta.dx).clamp(8.0, size.width - 64),
                  (_offset.dy + details.delta.dy).clamp(40.0, size.height - 80),
                );
              });
            },
            child: _OverlayButton(onTap: _open),
          ),
        ),
      ],
    );
  }

  void _open() {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => ProviderScope(
          overrides: [
            pulseOpsConfigProvider.overrideWithValue(widget.config),
            networkStoreProvider.overrideWithValue(widget.store),
            crashDiagnosticsProvider
                .overrideWithValue(widget.crashDiagnostics),
          ],
          child: Theme(
            data: PulseTheme.build(),
            child: InspectorScreen(retryDio: widget.retryDio),
          ),
        ),
      ),
    );
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

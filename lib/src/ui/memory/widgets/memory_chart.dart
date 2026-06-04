import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../memory/memory_snapshot.dart';
import '../../theme/pulse_theme.dart';

/// Sparkline chart of RSS memory over the last N snapshots.
class MemoryChart extends StatelessWidget {
  const MemoryChart({super.key, required this.snapshots, this.height = 80});

  final List<MemorySnapshot> snapshots;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _MemoryPainter(snapshots),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _MemoryPainter extends CustomPainter {
  _MemoryPainter(this.snapshots);

  final List<MemorySnapshot> snapshots;

  @override
  void paint(Canvas canvas, Size size) {
    if (snapshots.isEmpty) return;

    final maxRss =
        snapshots.map((s) => s.rssBytes.toDouble()).fold(1.0, math.max);

    final w = size.width;
    final h = size.height;
    final step = w / math.max(snapshots.length - 1, 1);

    // Grid line at 50% and 75% of peak
    final gridPaint = Paint()
      ..color = PulseTheme.border.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;
    for (final frac in [0.5, 0.75]) {
      final y = h - frac * h;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Spike markers
    final spikePaint = Paint()
      ..color = PulseTheme.error.withValues(alpha: 0.25)
      ..strokeWidth = 1.5;

    for (var i = 0; i < snapshots.length; i++) {
      if (snapshots[i].isSpike) {
        final x = i * step;
        canvas.drawLine(Offset(x, 0), Offset(x, h), spikePaint);
      }
    }

    // Fill path
    final fillPath = Path();
    final linePath = Path();

    for (var i = 0; i < snapshots.length; i++) {
      final frac = (snapshots[i].rssBytes / maxRss).clamp(0.0, 1.0);
      final x = i * step;
      final y = h - frac * h;
      if (i == 0) {
        fillPath.moveTo(x, h);
        fillPath.lineTo(x, y);
        linePath.moveTo(x, y);
      } else {
        fillPath.lineTo(x, y);
        linePath.lineTo(x, y);
      }
    }
    fillPath.lineTo((snapshots.length - 1) * step, h);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            PulseTheme.warning.withValues(alpha: 0.25),
            PulseTheme.warning.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h))
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = PulseTheme.warning
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_MemoryPainter old) => old.snapshots != snapshots;
}

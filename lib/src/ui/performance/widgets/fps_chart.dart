import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../performance/frame_metric.dart';
import '../../theme/pulse_theme.dart';

/// Sparkline chart of FPS values over the last N frames.
class FpsChart extends StatelessWidget {
  const FpsChart({super.key, required this.frames, this.height = 80});

  final List<FrameMetric> frames;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _FpsChartPainter(frames),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _FpsChartPainter extends CustomPainter {
  _FpsChartPainter(this.frames);

  final List<FrameMetric> frames;

  static const _goodFps = 55.0;
  static const _okFps = 40.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (frames.isEmpty) return;

    final w = size.width;
    final h = size.height;

    // Baseline grid lines at 60 fps and 30 fps
    final gridPaint = Paint()
      ..color = PulseTheme.border.withValues(alpha: 0.6)
      ..strokeWidth = 0.5;
    for (final fps in [60.0, 30.0]) {
      final y = h - (fps / 60.0) * h;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    final path = Path();
    final fillPath = Path();

    final step = w / math.max(frames.length - 1, 1);

    for (var i = 0; i < frames.length; i++) {
      final fps = frames[i].fps.clamp(0, 60).toDouble();
      final x = i * step;
      final y = h - (fps / 60.0) * h;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, h);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo((frames.length - 1) * step, h);
    fillPath.close();

    // Fill gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          PulseTheme.accent.withValues(alpha: 0.2),
          PulseTheme.accent.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Line colored by current FPS
    final lastFps = frames.last.fps;
    final lineColor = lastFps >= _goodFps
        ? PulseTheme.success
        : lastFps >= _okFps
            ? PulseTheme.warning
            : PulseTheme.error;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(_FpsChartPainter old) => old.frames != frames;
}

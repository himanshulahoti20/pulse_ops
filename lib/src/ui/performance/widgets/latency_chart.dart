import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../network/models/network_record.dart';
import '../../theme/pulse_theme.dart';

/// Bar chart showing request durations for the last N completed records.
class LatencyChart extends StatelessWidget {
  const LatencyChart({
    super.key,
    required this.records,
    this.slowThresholdMs = 2000,
    this.height = 80,
    this.maxBars = 40,
  });

  final List<NetworkRecord> records;
  final int slowThresholdMs;
  final double height;
  final int maxBars;

  @override
  Widget build(BuildContext context) {
    final completed = records
        .where((r) => r.endedAt != null)
        .toList()
        .reversed
        .take(maxBars)
        .toList()
        .reversed
        .toList();
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _LatencyPainter(completed, slowThresholdMs),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _LatencyPainter extends CustomPainter {
  _LatencyPainter(this.records, this.slowThresholdMs);

  final List<NetworkRecord> records;
  final int slowThresholdMs;

  @override
  void paint(Canvas canvas, Size size) {
    if (records.isEmpty) return;

    final maxMs = records
        .map((r) => r.duration.inMilliseconds.toDouble())
        .fold(1.0, math.max);

    final barWidth = (size.width / records.length) - 2;
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < records.length; i++) {
      final r = records[i];
      final ms = r.duration.inMilliseconds.toDouble();
      final frac = (ms / maxMs).clamp(0.0, 1.0);
      final barH = math.max(frac * size.height, 2.0);
      final x = i * (barWidth + 2);
      final y = size.height - barH;

      paint.color = r.isFailure
          ? PulseTheme.error
          : ms >= slowThresholdMs
              ? PulseTheme.warning
              : PulseTheme.success;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barH),
          const Radius.circular(2),
        ),
        paint,
      );
    }

    // Slow threshold line
    final thresholdFrac = (slowThresholdMs.toDouble() / maxMs).clamp(0.0, 1.0);
    final thresholdY = size.height - thresholdFrac * size.height;
    canvas.drawLine(
      Offset(0, thresholdY),
      Offset(size.width, thresholdY),
      Paint()
        ..color = PulseTheme.warning.withValues(alpha: 0.5)
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(_LatencyPainter old) =>
      old.records != records || old.slowThresholdMs != slowThresholdMs;
}

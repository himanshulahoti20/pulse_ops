import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/models/network_record.dart';
import '../../performance/frame_metric.dart';
import '../../providers/providers.dart';
import '../theme/pulse_theme.dart';
import 'widgets/fps_chart.dart';
import 'widgets/latency_chart.dart';

class PerformanceScreen extends ConsumerWidget {
  const PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frameAsync = ref.watch(frameMetricsProvider);
    final allRecords = ref.watch(networkRecordsProvider).maybeWhen(
          data: (r) => r,
          orElse: () => const <NetworkRecord>[],
        );
    final config = ref.watch(pulseOpsConfigProvider);
    final perfStore = ref.watch(performanceStoreProvider);

    final frames = frameAsync.maybeWhen(
      data: (f) => f,
      orElse: () => const <FrameMetric>[],
    );

    final fps = frames.isEmpty ? 60.0 : perfStore.currentFps();
    final dropped = perfStore.droppedFrameCount;
    final severe = perfStore.severeDropCount;
    final startup = perfStore.startupTime;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance'),
        actions: [
          IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // ── Startup ────────────────────────────────────────────────────
          if (startup != null) ...[
            const _SectionHeader('Startup'),
            _StatCard(
              icon: Icons.rocket_launch_rounded,
              label: 'Time to first frame',
              value: '${startup.inMilliseconds} ms',
              color: startup.inMilliseconds < 500
                  ? PulseTheme.success
                  : startup.inMilliseconds < 1500
                      ? PulseTheme.warning
                      : PulseTheme.error,
            ),
            const SizedBox(height: 16),
          ],

          // ── FPS Overview ───────────────────────────────────────────────
          const _SectionHeader('Frame Rate'),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.speed_rounded,
                  label: 'Current FPS',
                  value: fps.toStringAsFixed(1),
                  color: fps >= 55
                      ? PulseTheme.success
                      : fps >= 40
                          ? PulseTheme.warning
                          : PulseTheme.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.warning_amber_rounded,
                  label: 'Dropped frames',
                  value: '$dropped',
                  color: dropped == 0 ? PulseTheme.success : PulseTheme.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.crisis_alert_rounded,
                  label: 'Severe drops',
                  value: '$severe',
                  color: severe == 0 ? PulseTheme.success : PulseTheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ChartCard(
            label: 'FPS over last ${frames.length} frames',
            child: frames.isEmpty
                ? const _EmptyChart('Start using the app to collect frame data')
                : FpsChart(frames: frames),
          ),
          const SizedBox(height: 16),

          // ── Frame Drops ────────────────────────────────────────────────
          if (dropped > 0) ...[
            const _SectionHeader('Frame Drops'),
            _FrameDropList(frames: perfStore.droppedFrames),
            const SizedBox(height: 16),
          ],

          // ── API Latency ────────────────────────────────────────────────
          const _SectionHeader('API Latency'),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.timer_outlined,
                  label: 'Avg latency',
                  value: _avgLatency(allRecords),
                  color: PulseTheme.info,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.hourglass_top_rounded,
                  label: 'Slow requests',
                  value:
                      '${_slowCount(allRecords, config.slowRequestThresholdMs)}',
                  color:
                      _slowCount(allRecords, config.slowRequestThresholdMs) == 0
                          ? PulseTheme.success
                          : PulseTheme.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ChartCard(
            label: 'Request durations (last 40)',
            child: allRecords.isEmpty
                ? const _EmptyChart('Fire network requests to see latency data')
                : LatencyChart(
                    records: allRecords,
                    slowThresholdMs: config.slowRequestThresholdMs,
                  ),
          ),
        ],
      ),
    );
  }

  String _avgLatency(List<NetworkRecord> records) {
    if (records.isEmpty) return '— ms';
    final completed = records.where((r) => r.endedAt != null).toList();
    if (completed.isEmpty) return '— ms';
    final avg = completed
            .map((r) => r.duration.inMilliseconds)
            .reduce((a, b) => a + b) ~/
        completed.length;
    return '$avg ms';
  }

  int _slowCount(List<NetworkRecord> records, int thresholdMs) => records
      .where(
          (r) => r.endedAt != null && r.duration.inMilliseconds >= thresholdMs)
      .length;
}

// ── Frame drop list ──────────────────────────────────────────────────────────

class _FrameDropList extends StatelessWidget {
  const _FrameDropList({required this.frames});
  final List<FrameMetric> frames;

  @override
  Widget build(BuildContext context) {
    final drops = frames.reversed.take(20).toList();
    return Container(
      decoration: BoxDecoration(
        color: PulseTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PulseTheme.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < drops.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: PulseTheme.border),
            _DropRow(frame: drops[i]),
          ],
        ],
      ),
    );
  }
}

class _DropRow extends StatelessWidget {
  const _DropRow({required this.frame});
  final FrameMetric frame;

  @override
  Widget build(BuildContext context) {
    final ms = frame.totalDuration.inMilliseconds;
    final isSevere = frame.isSevere;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(
            isSevere ? Icons.crisis_alert_rounded : Icons.warning_amber_rounded,
            color: isSevere ? PulseTheme.error : PulseTheme.warning,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isSevere ? 'Severe jank — $ms ms' : 'Frame drop — $ms ms',
              style: const TextStyle(
                  color: PulseTheme.textPrimary,
                  fontSize: 12,
                  fontFamily: 'monospace'),
            ),
          ),
          Text(
            '${frame.fps.toStringAsFixed(1)} fps',
            style: TextStyle(
              color: isSevere ? PulseTheme.error : PulseTheme.warning,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: PulseTheme.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PulseTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PulseTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: PulseTheme.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: PulseTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PulseTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: PulseTheme.textSecondary,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: PulseTheme.textSecondary,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

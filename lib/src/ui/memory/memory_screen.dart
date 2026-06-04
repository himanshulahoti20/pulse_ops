import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../memory/tracked_object.dart';
import '../../providers/providers.dart';
import '../theme/pulse_theme.dart';
import 'widgets/memory_chart.dart';

class MemoryScreen extends ConsumerWidget {
  const MemoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshots = ref.watch(memorySnapshotsProvider);
    final leaks = ref.watch(potentialLeaksProvider);
    final store = ref.watch(memoryStoreProvider);

    final currentMb = store.currentRssBytes / (1024 * 1024);
    final peakMb = store.peakRssBytes / (1024 * 1024);
    final spikeCount = snapshots.where((s) => s.isSpike).length;
    final rebuilds = store.rebuildCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory'),
        actions: [
          IconButton(
            tooltip: 'Reset rebuild counts',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => store.resetRebuildCounts(),
          ),
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
          // ── RSS overview ────────────────────────────────────────────────
          const _SectionHeader('RSS Memory'),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.memory_rounded,
                  label: 'Current',
                  value: '${currentMb.toStringAsFixed(1)} MB',
                  color: currentMb < 200
                      ? PulseTheme.success
                      : currentMb < 400
                          ? PulseTheme.warning
                          : PulseTheme.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.show_chart_rounded,
                  label: 'Peak',
                  value: '${peakMb.toStringAsFixed(1)} MB',
                  color: PulseTheme.info,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.bolt_rounded,
                  label: 'Spikes',
                  value: '$spikeCount',
                  color:
                      spikeCount == 0 ? PulseTheme.success : PulseTheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ChartCard(
            label: 'RSS over last ${snapshots.length} samples',
            child: snapshots.isEmpty
                ? const _EmptyChart('Waiting for memory samples…')
                : MemoryChart(snapshots: snapshots),
          ),
          if (spikeCount > 0) ...[
            const SizedBox(height: 8),
            _SpikeWarning(count: spikeCount),
          ],
          const SizedBox(height: 16),

          // ── Potential leaks ─────────────────────────────────────────────
          _SectionHeader('Potential Leaks (${leaks.length})'),
          leaks.isEmpty
              ? const _EmptyCard(
                  'No leaks detected — all tracked objects disposed correctly.')
              : _LeakList(leaks: leaks),
          const SizedBox(height: 16),

          // ── Widget lifecycle ────────────────────────────────────────────
          const _SectionHeader('Widget Lifecycle'),
          _LifecycleSummary(store: ref.watch(memoryStoreProvider)),
          const SizedBox(height: 16),

          // ── Rebuild tracker ─────────────────────────────────────────────
          if (rebuilds.isNotEmpty) ...[
            const _SectionHeader('Rebuild Counts'),
            _RebuildList(entries: rebuilds.take(20).toList()),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

// ── Spike warning ────────────────────────────────────────────────────────────

class _SpikeWarning extends StatelessWidget {
  const _SpikeWarning({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: PulseTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PulseTheme.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: PulseTheme.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$count memory spike${count == 1 ? '' : 's'} detected — RSS jumped >20% above the rolling average.',
              style: const TextStyle(color: PulseTheme.error, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Leak list ────────────────────────────────────────────────────────────────

class _LeakList extends StatelessWidget {
  const _LeakList({required this.leaks});
  final List<TrackedObject> leaks;

  @override
  Widget build(BuildContext context) {
    final shown = leaks.take(20).toList();
    return Container(
      decoration: BoxDecoration(
        color: PulseTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PulseTheme.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < shown.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: PulseTheme.border),
            _LeakRow(obj: shown[i]),
          ],
        ],
      ),
    );
  }
}

class _LeakRow extends StatelessWidget {
  const _LeakRow({required this.obj});
  final TrackedObject obj;

  @override
  Widget build(BuildContext context) {
    final age = obj.age;
    final ageLabel = age.inSeconds < 60
        ? '${age.inSeconds}s'
        : '${age.inMinutes}m ${age.inSeconds % 60}s';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.leak_add_rounded, color: PulseTheme.error, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              obj.type,
              style: const TextStyle(
                color: PulseTheme.textPrimary,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Text(
            'alive $ageLabel',
            style: const TextStyle(
              color: PulseTheme.error,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widget lifecycle summary ─────────────────────────────────────────────────

class _LifecycleSummary extends StatelessWidget {
  const _LifecycleSummary({required this.store});
  final dynamic store; // MemoryStore

  @override
  Widget build(BuildContext context) {
    final all = store.trackedObjects as List<TrackedObject>;
    final created = all.length;
    final disposed = all.where((o) => o.disposed).length;
    final active = created - disposed;

    // Type breakdown — top 5
    final typeCounts = <String, int>{};
    for (final o in all) {
      if (!o.disposed) typeCounts[o.type] = (typeCounts[o.type] ?? 0) + 1;
    }
    final topTypes = typeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PulseTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PulseTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Pill(
                  label: 'Created',
                  value: '$created',
                  color: PulseTheme.textSecondary),
              const SizedBox(width: 10),
              _Pill(
                  label: 'Disposed',
                  value: '$disposed',
                  color: PulseTheme.success),
              const SizedBox(width: 10),
              _Pill(
                  label: 'Active',
                  value: '$active',
                  color: active > 50 ? PulseTheme.warning : PulseTheme.info),
            ],
          ),
          if (topTypes.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final e in topTypes.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.key,
                        style: const TextStyle(
                          color: PulseTheme.textPrimary,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    Text(
                      '${e.value}',
                      style: const TextStyle(
                        color: PulseTheme.accent,
                        fontSize: 11,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace')),
        Text(label,
            style:
                const TextStyle(color: PulseTheme.textSecondary, fontSize: 10)),
      ],
    );
  }
}

// ── Rebuild list ─────────────────────────────────────────────────────────────

class _RebuildList extends StatelessWidget {
  const _RebuildList({required this.entries});
  final List<MapEntry<String, int>> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PulseTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PulseTheme.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: PulseTheme.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                children: [
                  const Icon(Icons.replay_rounded,
                      color: PulseTheme.accent, size: 14),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entries[i].key,
                      style: const TextStyle(
                        color: PulseTheme.textPrimary,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  Text(
                    '${entries[i].value}×',
                    style: TextStyle(
                      color: entries[i].value > 50
                          ? PulseTheme.error
                          : entries[i].value > 20
                              ? PulseTheme.warning
                              : PulseTheme.textSecondary,
                      fontSize: 12,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
  Widget build(BuildContext context) => Padding(
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
  Widget build(BuildContext context) => Container(
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
                fontSize: 16,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: PulseTheme.textSecondary, fontSize: 11)),
          ],
        ),
      );
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: PulseTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PulseTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: PulseTheme.textSecondary,
                    fontSize: 11,
                    fontFamily: 'monospace')),
            const SizedBox(height: 10),
            child,
          ],
        ),
      );
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 80,
        child: Center(
          child: Text(message,
              style: const TextStyle(
                  color: PulseTheme.textSecondary, fontSize: 12),
              textAlign: TextAlign.center),
        ),
      );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: PulseTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PulseTheme.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: PulseTheme.success, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: PulseTheme.textSecondary, fontSize: 12)),
            ),
          ],
        ),
      );
}

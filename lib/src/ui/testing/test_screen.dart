import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/providers.dart';
import '../../testing/test_report_exporter.dart';
import '../../testing/test_session.dart';
import '../theme/pulse_theme.dart';
import 'test_session_screen.dart';

class TestScreen extends ConsumerWidget {
  const TestScreen({super.key});

  static const _exporter = TestReportExporter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(testSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Observability'),
        actions: [
          IconButton(
            tooltip: 'Export report',
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: sessions.isEmpty
                ? null
                : () => _exportReport(context, sessions),
          ),
          IconButton(
            tooltip: 'Clear',
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: sessions.isEmpty
                ? null
                : () => ref.read(testStoreProvider).clear(),
          ),
          IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
      body: sessions.isEmpty
          ? const _EmptyState()
          : _SessionList(sessions: sessions),
    );
  }

  Future<void> _exportReport(
    BuildContext context,
    List<TestSession> sessions,
  ) async {
    final selected = await showModalBottomSheet<TestReportFormat>(
      context: context,
      backgroundColor: PulseTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Export test report',
                  style: TextStyle(
                    color: PulseTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.data_object_rounded,
                  color: PulseTheme.accent),
              title: const Text('JSON',
                  style: TextStyle(
                      color: PulseTheme.textPrimary,
                      fontWeight: FontWeight.w600)),
              subtitle: const Text(
                  'Structured report with events and network calls.',
                  style:
                      TextStyle(color: PulseTheme.textSecondary, fontSize: 12)),
              onTap: () => Navigator.of(ctx).pop(TestReportFormat.json),
            ),
            ListTile(
              leading:
                  const Icon(Icons.notes_rounded, color: PulseTheme.accent),
              title: const Text('Plain text',
                  style: TextStyle(
                      color: PulseTheme.textPrimary,
                      fontWeight: FontWeight.w600)),
              subtitle: const Text('Readable summary per test session.',
                  style:
                      TextStyle(color: PulseTheme.textSecondary, fontSize: 12)),
              onTap: () => Navigator.of(ctx).pop(TestReportFormat.text),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (selected == null || !context.mounted) return;
    final payload = _exporter.export(sessions, format: selected);
    final ext = selected == TestReportFormat.json ? 'json' : 'txt';
    final filename = 'pulse-test-${DateTime.now().millisecondsSinceEpoch}.$ext';
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              Uint8List.fromList(payload.codeUnits),
              name: filename,
              mimeType: selected == TestReportFormat.json
                  ? 'application/json'
                  : 'text/plain',
            ),
          ],
          fileNameOverrides: [filename],
        ),
      );
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: payload));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test report copied to clipboard')),
      );
    }
  }
}

// ── Session list ───────────────────────────────────────────────────────────

class _SessionList extends StatelessWidget {
  const _SessionList({required this.sessions});

  final List<TestSession> sessions;

  @override
  Widget build(BuildContext context) {
    final passed = sessions.where((s) => s.isPassed).length;
    final failed = sessions.where((s) => s.isFailed).length;
    return Column(
      children: [
        _SummaryBar(total: sessions.length, passed: passed, failed: failed),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: sessions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _SessionTile(session: sessions[i]),
          ),
        ),
      ],
    );
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.total,
    required this.passed,
    required this.failed,
  });

  final int total;
  final int passed;
  final int failed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: PulseTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PulseTheme.border),
      ),
      child: Row(
        children: [
          _Stat(
              label: 'Total',
              value: total.toString(),
              color: PulseTheme.textPrimary),
          const SizedBox(width: 24),
          _Stat(
              label: 'Passed',
              value: passed.toString(),
              color: PulseTheme.success),
          const SizedBox(width: 24),
          _Stat(
              label: 'Failed',
              value: failed.toString(),
              color: PulseTheme.error),
          const Spacer(),
          if (total > 0) ...[
            Text(
              '${(passed / total * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                color: PulseTheme.accent,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'pass rate',
              style: TextStyle(color: PulseTheme.textSecondary, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              fontFamily: 'monospace'),
        ),
        Text(
          label,
          style: const TextStyle(color: PulseTheme.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final TestSession session;

  @override
  Widget build(BuildContext context) {
    final statusColor = session.isPassed
        ? PulseTheme.success
        : session.isFailed
            ? PulseTheme.error
            : session.isRunning
                ? PulseTheme.warning
                : PulseTheme.textSecondary;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Theme(
            data: Theme.of(context),
            child: TestSessionScreen(session: session),
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: PulseTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: session.isFailed
                ? PulseTheme.error.withValues(alpha: 0.3)
                : PulseTheme.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.name,
                    style: const TextStyle(
                      color: PulseTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (session.group != null)
                    Text(
                      session.group!,
                      style: const TextStyle(
                          color: PulseTheme.textSecondary, fontSize: 11),
                    ),
                  if (session.isFailed && session.failureMessage != null)
                    Text(
                      session.failureMessage!,
                      style: const TextStyle(
                          color: PulseTheme.error, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${session.duration.inMilliseconds} ms',
                  style: const TextStyle(
                    color: PulseTheme.textSecondary,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (session.networkRequests.isNotEmpty)
                      _Badge(
                        icon: Icons.wifi_rounded,
                        value: '${session.networkRequests.length}',
                        color: PulseTheme.info,
                      ),
                    if (session.events.isNotEmpty)
                      _Badge(
                        icon: Icons.receipt_long_rounded,
                        value: '${session.events.length}',
                        color: PulseTheme.textSecondary,
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                color: PulseTheme.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.value, required this.color});

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 2),
          Text(
            value,
            style:
                TextStyle(color: color, fontSize: 10, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: PulseTheme.accent.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.science_rounded,
                  color: PulseTheme.accent, size: 34),
            ),
            const SizedBox(height: 20),
            const Text(
              'No test sessions yet',
              style: TextStyle(
                color: PulseTheme.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Call PulseTestObserver.beginTest() in your test setUp to start tracking.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: PulseTheme.textSecondary, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

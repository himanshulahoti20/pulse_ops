import 'package:flutter/material.dart';

import '../../crash/breadcrumb.dart';
import '../../network/models/network_record.dart';
import '../../testing/test_event.dart';
import '../../testing/test_session.dart';
import '../theme/pulse_theme.dart';

class TestSessionScreen extends StatelessWidget {
  const TestSessionScreen({super.key, required this.session});

  final TestSession session;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          session.name,
          style: const TextStyle(fontSize: 15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _StatusCard(session: session),
          if (session.isFailed && session.failureMessage != null) ...[
            const SizedBox(height: 12),
            _FailureCard(session: session),
          ],
          if (session.networkRequests.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionHeader(
                title:
                    'API Logs (${session.networkRequests.length} request${session.networkRequests.length == 1 ? '' : 's'})'),
            const SizedBox(height: 8),
            ...session.networkRequests.map((r) => _NetworkRow(record: r)),
          ],
          if (session.events.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionHeader(
                title:
                    'Timeline (${session.events.length} event${session.events.length == 1 ? '' : 's'})'),
            const SizedBox(height: 8),
            _EventTimeline(events: session.events),
          ],
        ],
      ),
    );
  }
}

// ── Status card ────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.session});

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

    return Container(
      padding: const EdgeInsets.all(16),
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  session.status.name.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${session.duration.inMilliseconds} ms',
                style: const TextStyle(
                  color: PulseTheme.textSecondary,
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (session.group != null) ...[
            _Row(label: 'Group', value: session.group!),
            const SizedBox(height: 6),
          ],
          _Row(label: 'Started', value: _fmtTime(session.startedAt)),
          if (session.endedAt != null) ...[
            const SizedBox(height: 6),
            _Row(label: 'Ended', value: _fmtTime(session.endedAt!)),
          ],
          const SizedBox(height: 6),
          _Row(label: 'Events', value: '${session.events.length}'),
          const SizedBox(height: 6),
          _Row(
              label: 'Network calls',
              value: '${session.networkRequests.length}'),
        ],
      ),
    );
  }

  String _fmtTime(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}'
      ':${dt.minute.toString().padLeft(2, '0')}'
      ':${dt.second.toString().padLeft(2, '0')}'
      '.${dt.millisecond.toString().padLeft(3, '0')}';
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style:
                const TextStyle(color: PulseTheme.textSecondary, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: PulseTheme.textPrimary,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}

// ── Failure card ───────────────────────────────────────────────────────────

class _FailureCard extends StatelessWidget {
  const _FailureCard({required this.session});

  final TestSession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PulseTheme.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PulseTheme.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline_rounded,
                  color: PulseTheme.error, size: 16),
              SizedBox(width: 6),
              Text(
                'Failure',
                style: TextStyle(
                  color: PulseTheme.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            session.failureMessage!,
            style: const TextStyle(
              color: PulseTheme.textPrimary,
              fontSize: 12,
              fontFamily: 'monospace',
              height: 1.5,
            ),
          ),
          if (session.stackTrace != null) ...[
            const SizedBox(height: 10),
            const Text(
              'Stack trace',
              style: TextStyle(
                color: PulseTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              session.stackTrace!.split('\n').take(12).join('\n'),
              style: const TextStyle(
                color: PulseTheme.textSecondary,
                fontSize: 10,
                fontFamily: 'monospace',
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── API log rows ───────────────────────────────────────────────────────────

class _NetworkRow extends StatelessWidget {
  const _NetworkRow({required this.record});

  final NetworkRecord record;

  @override
  Widget build(BuildContext context) {
    final statusColor = record.isFailure
        ? PulseTheme.error
        : record.isSuccess
            ? PulseTheme.success
            : PulseTheme.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: PulseTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PulseTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color:
                  PulseTheme.methodColor(record.method).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              record.method,
              style: TextStyle(
                color: PulseTheme.methodColor(record.method),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              record.endpoint,
              style: const TextStyle(
                color: PulseTheme.textPrimary,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            record.statusCode != null
                ? '${record.statusCode}'
                : record.status.name,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${record.duration.inMilliseconds} ms',
            style: const TextStyle(
              color: PulseTheme.textSecondary,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

// ── Event timeline ─────────────────────────────────────────────────────────

class _EventTimeline extends StatelessWidget {
  const _EventTimeline({required this.events});

  final List<TestEvent> events;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < events.length; i++)
          _EventRow(
            event: events[i],
            isLast: i == events.length - 1,
          ),
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.isLast});

  final TestEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final dotColor = _dotColor();
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 4),
                  decoration:
                      BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: PulseTheme.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _TypeBadge(type: event.type),
                      const Spacer(),
                      Text(
                        _fmtTime(event.timestamp),
                        style: const TextStyle(
                          color: PulseTheme.textSecondary,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.message,
                    style: TextStyle(
                      color: event.level == BreadcrumbLevel.error
                          ? PulseTheme.error
                          : PulseTheme.textPrimary,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (event.duration != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${event.duration!.inMilliseconds} ms',
                      style: const TextStyle(
                        color: PulseTheme.textSecondary,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _dotColor() {
    switch (event.type) {
      case TestEventType.networkRequest:
        return event.level == BreadcrumbLevel.error
            ? PulseTheme.error
            : PulseTheme.info;
      case TestEventType.assertion:
        return event.level == BreadcrumbLevel.error
            ? PulseTheme.error
            : PulseTheme.success;
      case TestEventType.failure:
        return PulseTheme.error;
      case TestEventType.performance:
        return PulseTheme.warning;
      case TestEventType.widgetPump:
        return PulseTheme.accent;
      case TestEventType.log:
        return PulseTheme.textSecondary;
    }
  }

  String _fmtTime(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}'
      ':${dt.minute.toString().padLeft(2, '0')}'
      ':${dt.second.toString().padLeft(2, '0')}';
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final TestEventType type;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      TestEventType.log => ('LOG', PulseTheme.textSecondary),
      TestEventType.networkRequest => ('NET', PulseTheme.info),
      TestEventType.assertion => ('ASSERT', PulseTheme.success),
      TestEventType.widgetPump => ('PUMP', PulseTheme.accent),
      TestEventType.failure => ('FAIL', PulseTheme.error),
      TestEventType.performance => ('PERF', PulseTheme.warning),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ── helpers ────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: PulseTheme.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}

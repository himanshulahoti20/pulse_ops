import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../network/models/network_record.dart';
import '../../theme/pulse_theme.dart';
import '../widgets/method_chip.dart';
import '../widgets/status_chip.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key, required this.record});

  final NetworkRecord record;

  static final _fullDateFmt = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Card(
          children: [
            Row(
              children: [
                MethodChip(method: record.method),
                const SizedBox(width: 8),
                StatusChip(record: record),
                const Spacer(),
                Text(
                  '${record.duration.inMilliseconds}ms',
                  style: const TextStyle(
                    color: PulseTheme.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SelectableText(
              record.url,
              style: const TextStyle(
                color: PulseTheme.textPrimary,
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Card(
          children: [
            _row('Status', _statusText()),
            _row('Started', _fullDateFmt.format(record.startedAt)),
            if (record.endedAt != null)
              _row('Ended', _fullDateFmt.format(record.endedAt!)),
            _row('Duration', '${record.duration.inMilliseconds} ms'),
            if (record.requestSizeBytes != null)
              _row('Request size', _bytes(record.requestSizeBytes!)),
            if (record.responseSizeBytes != null)
              _row('Response size', _bytes(record.responseSizeBytes!)),
            if (record.isMultipart) _row('Body', 'multipart/form-data'),
          ],
        ),
        if (record.error != null) ...[
          const SizedBox(height: 12),
          _Card(
            accent: PulseTheme.error,
            children: [
              const Text(
                'Error',
                style: TextStyle(
                  color: PulseTheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              SelectableText(
                record.error!,
                style: const TextStyle(
                  color: PulseTheme.textPrimary,
                  fontFamily: 'monospace',
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _statusText() {
    final code = record.statusCode;
    final msg = record.statusMessage;
    if (code == null && msg == null) return record.status.name;
    return '${code ?? '-'} ${msg ?? ''}'.trim();
  }

  String _bytes(int n) {
    if (n < 1024) return '$n B';
    if (n < 1024 * 1024) return '${(n / 1024).toStringAsFixed(1)} KB';
    return '${(n / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: PulseTheme.textSecondary),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                color: PulseTheme.textPrimary,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children, this.accent});
  final List<Widget> children;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PulseTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent?.withValues(alpha: 0.4) ?? PulseTheme.border,
        ),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../network/models/network_record.dart';
import '../../theme/pulse_theme.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.record});

  final NetworkRecord record;

  @override
  Widget build(BuildContext context) {
    final color = _color();
    final label = _label();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (record.status == NetworkStatus.pending)
            const SizedBox(
              height: 8,
              width: 8,
              child: CircularProgressIndicator(
                strokeWidth: 1.4,
                color: PulseTheme.textSecondary,
              ),
            )
          else
            Container(
              height: 6,
              width: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Color _color() {
    if (record.status == NetworkStatus.cancelled) return PulseTheme.textSecondary;
    if (record.status == NetworkStatus.error && record.statusCode == null) {
      return PulseTheme.error;
    }
    return PulseTheme.statusColor(record.statusCode);
  }

  String _label() {
    if (record.status == NetworkStatus.pending) return '...';
    if (record.status == NetworkStatus.cancelled) return 'CXL';
    if (record.statusCode != null) return record.statusCode.toString();
    return 'ERR';
  }
}

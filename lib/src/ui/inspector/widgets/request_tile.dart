import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../network/models/network_record.dart';
import '../../theme/pulse_theme.dart';
import 'method_chip.dart';
import 'status_chip.dart';

class RequestTile extends StatelessWidget {
  const RequestTile({super.key, required this.record, required this.onTap});

  final NetworkRecord record;
  final VoidCallback onTap;

  static final _timeFmt = DateFormat('HH:mm:ss.SSS');

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: PulseTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PulseTheme.border),
          ),
          child: Row(
            children: [
              MethodChip(method: record.method),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.endpoint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PulseTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            record.host,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: PulseTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 2,
                          width: 2,
                          decoration: const BoxDecoration(
                            color: PulseTheme.textSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _timeFmt.format(record.startedAt),
                          style: const TextStyle(
                            color: PulseTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        if (record.endedAt != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            height: 2,
                            width: 2,
                            decoration: const BoxDecoration(
                              color: PulseTheme.textSecondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${record.duration.inMilliseconds}ms',
                            style: const TextStyle(
                              color: PulseTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              StatusChip(record: record),
            ],
          ),
        ),
      ),
    );
  }
}

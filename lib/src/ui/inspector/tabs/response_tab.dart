import 'package:flutter/material.dart';

import '../../../network/models/network_record.dart';
import '../../theme/pulse_theme.dart';
import '../widgets/json_viewer.dart';

class ResponseTab extends StatelessWidget {
  const ResponseTab({super.key, required this.record});

  final NetworkRecord record;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (record.error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PulseTheme.error.withValues(alpha: 0.08),
              border: Border.all(
                color: PulseTheme.error.withValues(alpha: 0.4),
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: PulseTheme.error, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: SelectableText(
                    record.error!,
                    style: const TextStyle(
                      color: PulseTheme.error,
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        JsonViewer(
          value: record.responseBody,
          emptyHint: record.status == NetworkStatus.pending
              ? 'Awaiting response…'
              : 'No response body',
        ),
      ],
    );
  }
}

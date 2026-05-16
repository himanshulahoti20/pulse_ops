import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../network/models/network_record.dart';
import '../../../network/utils/curl_builder.dart';
import '../../theme/pulse_theme.dart';

class CurlTab extends StatelessWidget {
  const CurlTab({super.key, required this.record});

  final NetworkRecord record;

  @override
  Widget build(BuildContext context) {
    final curl = const CurlBuilder().build(record);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'cURL',
                style: TextStyle(
                  color: PulseTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copy'),
                style: FilledButton.styleFrom(
                  backgroundColor: PulseTheme.accent.withValues(alpha: 0.18),
                  foregroundColor: PulseTheme.accent,
                ),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: curl));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('cURL copied to clipboard')),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: PulseTheme.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: PulseTheme.border),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  curl,
                  style: const TextStyle(
                    color: PulseTheme.textPrimary,
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/pulse_theme.dart';

class HeadersTab extends StatelessWidget {
  const HeadersTab({
    super.key,
    required this.request,
    required this.response,
  });

  final Map<String, dynamic> request;
  final Map<String, dynamic> response;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _section(context, 'Request Headers', request),
        const SizedBox(height: 16),
        _section(context, 'Response Headers', response),
      ],
    );
  }

  Widget _section(
    BuildContext context,
    String title,
    Map<String, dynamic> headers,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: PulseTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PulseTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: PulseTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Copy all',
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  color: PulseTheme.textSecondary,
                  onPressed: headers.isEmpty
                      ? null
                      : () async {
                          final text = headers.entries
                              .map((e) => '${e.key}: ${e.value}')
                              .join('\n');
                          await Clipboard.setData(ClipboardData(text: text));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Headers copied')),
                            );
                          }
                        },
                ),
              ],
            ),
          ),
          if (headers.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 4, 14, 14),
              child: Text(
                'No headers',
                style: TextStyle(color: PulseTheme.textSecondary),
              ),
            )
          else
            ...headers.entries.map((e) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: PulseTheme.border.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 140,
                      child: Text(
                        e.key,
                        style: const TextStyle(
                          color: PulseTheme.jsonKey,
                          fontFamily: 'monospace',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SelectableText(
                        '${e.value}',
                        style: const TextStyle(
                          color: PulseTheme.textPrimary,
                          fontFamily: 'monospace',
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          if (headers.isNotEmpty) const SizedBox(height: 4),
        ],
      ),
    );
  }
}

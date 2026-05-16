import 'package:flutter/material.dart';

import '../../../network/models/network_record.dart';
import '../../theme/pulse_theme.dart';
import '../widgets/json_viewer.dart';

class RequestTab extends StatelessWidget {
  const RequestTab({super.key, required this.record});

  final NetworkRecord record;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (record.queryParameters.isNotEmpty) ...[
          const _SectionLabel(text: 'Query Parameters'),
          const SizedBox(height: 8),
          JsonViewer(value: record.queryParameters),
          const SizedBox(height: 16),
        ],
        const _SectionLabel(text: 'Body'),
        const SizedBox(height: 8),
        JsonViewer(
          value: record.requestBody,
          emptyHint: 'No request body',
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: PulseTheme.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}

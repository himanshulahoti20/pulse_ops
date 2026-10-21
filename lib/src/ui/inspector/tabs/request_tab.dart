import 'package:flutter/material.dart';

import '../../../network/models/graphql_info.dart';
import '../../../network/models/network_record.dart';
import '../../theme/pulse_theme.dart';
import '../widgets/json_viewer.dart';
import '../widgets/multipart_viewer.dart';

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
        if (record.multipart != null) ...[
          const _SectionLabel(text: 'Multipart'),
          const SizedBox(height: 8),
          MultipartViewer(parts: record.multipart!),
        ] else if (record.graphql != null) ...[
          _GraphQLSection(info: record.graphql!),
        ] else ...[
          const _SectionLabel(text: 'Body'),
          const SizedBox(height: 8),
          JsonViewer(
            value: record.requestBody,
            emptyHint: 'No request body',
          ),
        ],
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
      style: TextStyle(
        color: PulseTheme.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _GraphQLSection extends StatelessWidget {
  const _GraphQLSection({required this.info});

  final GraphQLInfo info;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(text: 'GraphQL'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _Pill(info.type, PulseTheme.accent),
            _Pill(info.operationName ?? 'anonymous', PulseTheme.info),
            if (info.batchSize > 1)
              _Pill('batch of ${info.batchSize}', PulseTheme.warning),
          ],
        ),
        const SizedBox(height: 12),
        const _SectionLabel(text: 'Query'),
        const SizedBox(height: 8),
        JsonViewer(value: info.query),
        const SizedBox(height: 16),
        const _SectionLabel(text: 'Variables'),
        const SizedBox(height: 8),
        JsonViewer(value: info.variables, emptyHint: 'No variables'),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../theme/pulse_theme.dart';

/// Lists the text fields and files of a multipart request, as described by
/// the interceptor (`{boundary, fields, files}`).
class MultipartViewer extends StatelessWidget {
  const MultipartViewer({super.key, required this.parts});

  final Map<String, dynamic> parts;

  @override
  Widget build(BuildContext context) {
    final fields = (parts['fields'] as Map?) ?? const {};
    final files = (parts['files'] as List?) ?? const [];
    final boundary = parts['boundary'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PulseTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PulseTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (boundary != null) _kv('boundary', '$boundary', dim: true),
          if (fields.isEmpty && files.isEmpty)
            Text('No parts', style: TextStyle(color: PulseTheme.textSecondary)),
          for (final e in fields.entries)
            _part(Icons.text_fields_rounded, '${e.key}', '${e.value}'),
          for (final f in files.cast<Map>())
            _part(
              Icons.attach_file_rounded,
              '${f['field']}',
              [
                '${f['filename'] ?? 'unnamed'}',
                if (f['contentType'] != null) '${f['contentType']}',
                if (f['length'] != null) _bytes(f['length'] as int),
              ].join(' · '),
            ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v, {bool dim = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          '$k: $v',
          style: TextStyle(
            color: dim ? PulseTheme.textSecondary : PulseTheme.textPrimary,
            fontSize: 12,
          ),
        ),
      );

  Widget _part(IconData icon, String name, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: PulseTheme.accent),
            const SizedBox(width: 8),
            Expanded(
              child: SelectableText.rich(
                TextSpan(children: [
                  TextSpan(
                    text: name,
                    style: TextStyle(
                      color: PulseTheme.jsonKey,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: '  $value',
                    style: TextStyle(color: PulseTheme.textPrimary),
                  ),
                ]),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
              ),
            ),
          ],
        ),
      );

  static String _bytes(int b) => b < 1024
      ? '$b B'
      : b < 1024 * 1024
          ? '${(b / 1024).toStringAsFixed(1)} KB'
          : '${(b / 1024 / 1024).toStringAsFixed(1)} MB';
}

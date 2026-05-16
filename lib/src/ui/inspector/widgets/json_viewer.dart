import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/pulse_theme.dart';

/// Pretty-prints and syntax-highlights arbitrary JSON-shaped values.
///
/// Falls back to a plain monospace block for non-decodable payloads.
class JsonViewer extends StatelessWidget {
  const JsonViewer({super.key, required this.value, this.emptyHint});

  final Object? value;
  final String? emptyHint;

  @override
  Widget build(BuildContext context) {
    if (value == null) {
      return _empty(emptyHint ?? 'No payload');
    }

    final normalized = _normalize(value);
    if (normalized is String) {
      return _PlainBlock(text: normalized);
    }
    final pretty = const JsonEncoder.withIndent('  ').convert(normalized);
    return _HighlightedBlock(text: pretty);
  }

  Widget _empty(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PulseTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PulseTheme.border),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: PulseTheme.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Object? _normalize(Object? v) {
    if (v == null) return null;
    if (v is String) {
      try {
        return jsonDecode(v);
      } catch (_) {
        return v;
      }
    }
    return v;
  }
}

class _PlainBlock extends StatelessWidget {
  const _PlainBlock({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return _Block(
      raw: text,
      child: SelectableText(
        text,
        style: const TextStyle(
          color: PulseTheme.textPrimary,
          fontFamily: 'monospace',
          fontSize: 12.5,
          height: 1.4,
        ),
      ),
    );
  }
}

class _HighlightedBlock extends StatelessWidget {
  const _HighlightedBlock({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return _Block(
      raw: text,
      child: SelectableText.rich(
        TextSpan(
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12.5,
            height: 1.45,
            color: PulseTheme.textPrimary,
          ),
          children: _highlight(text),
        ),
      ),
    );
  }

  List<TextSpan> _highlight(String src) {
    final spans = <TextSpan>[];
    final regex = RegExp(
      r'("(?:\\.|[^"\\])*"\s*:)' // keys
      r'|("(?:\\.|[^"\\])*")' // strings
      r'|\b(true|false|null)\b' // bool/null
      r'|(-?\d+(?:\.\d+)?(?:[eE][+\-]?\d+)?)' // numbers
      r'|([{}\[\],])', // punctuation
    );

    var idx = 0;
    for (final m in regex.allMatches(src)) {
      if (m.start > idx) {
        spans.add(TextSpan(text: src.substring(idx, m.start)));
      }
      final text = m.group(0)!;
      Color? color;
      if (m.group(1) != null) {
        color = PulseTheme.jsonKey;
      } else if (m.group(2) != null) {
        color = PulseTheme.jsonString;
      } else if (m.group(3) != null) {
        color = text == 'null' ? PulseTheme.jsonNull : PulseTheme.jsonBool;
      } else if (m.group(4) != null) {
        color = PulseTheme.jsonNumber;
      } else if (m.group(5) != null) {
        color = PulseTheme.jsonPunctuation;
      }
      spans.add(TextSpan(text: text, style: TextStyle(color: color)));
      idx = m.end;
    }
    if (idx < src.length) {
      spans.add(TextSpan(text: src.substring(idx)));
    }
    return spans;
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.child, required this.raw});
  final Widget child;
  final String raw;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 44, 14),
          decoration: BoxDecoration(
            color: PulseTheme.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: PulseTheme.border),
          ),
          child: child,
        ),
        Positioned(
          top: 6,
          right: 6,
          child: IconButton(
            tooltip: 'Copy',
            icon: const Icon(Icons.copy_rounded, size: 16),
            color: PulseTheme.textSecondary,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: raw));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../theme/pulse_theme.dart';

class MethodChip extends StatelessWidget {
  const MethodChip({super.key, required this.method, this.dense = false});

  final String method;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final color = PulseTheme.methodColor(method);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 6 : 8,
        vertical: dense ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        method.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: dense ? 10 : 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/throttle.dart';
import '../../providers/providers.dart';
import '../theme/pulse_theme.dart';

Future<void> showPulseSettings(BuildContext context, WidgetRef ref) {
  final config = ref.read(pulseOpsConfigProvider);
  final throttle = ref.read(throttleProvider);
  final palettes = <PulsePalette>[
    ...PulsePalette.builtIn,
    ...config.extraThemes,
  ];
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ListenableBuilder(
      listenable: Listenable.merge([
        PulseTheme.palette,
        PulseTheme.compact,
        PulseTheme.animations,
        throttle,
      ]),
      builder: (context, _) => _SettingsBody(
        palettes: palettes,
        throttle: throttle,
      ),
    ),
  );
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody({required this.palettes, required this.throttle});

  final List<PulsePalette> palettes;
  final ValueNotifier<NetworkThrottle> throttle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PulseTheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _heading('Theme'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in palettes)
                    _Choice(
                      label: p.name,
                      swatch: p.accent,
                      selected: PulseTheme.palette.value == p,
                      onTap: () => PulseTheme.palette.value = p,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Compact mode',
                    style: TextStyle(color: PulseTheme.textPrimary)),
                value: PulseTheme.compact.value,
                onChanged: (v) => PulseTheme.compact.value = v,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Animations',
                    style: TextStyle(color: PulseTheme.textPrimary)),
                value: PulseTheme.animations.value,
                onChanged: (v) => PulseTheme.animations.value = v,
              ),
              const SizedBox(height: 8),
              _heading('Network throttling'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in NetworkThrottle.values)
                    _Choice(
                      label: t.label,
                      selected: throttle.value == t,
                      onTap: () => throttle.value = t,
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Delays requests sent through the PulseOps Dio interceptor.',
                style: TextStyle(color: PulseTheme.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heading(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: TextStyle(
            color: PulseTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
    this.swatch,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? swatch;

  @override
  Widget build(BuildContext context) {
    final color = selected ? PulseTheme.accent : PulseTheme.textSecondary;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? PulseTheme.accent.withValues(alpha: 0.14)
              : PulseTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? PulseTheme.accent.withValues(alpha: 0.5)
                : PulseTheme.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (swatch != null) ...[
              CircleAvatar(radius: 5, backgroundColor: swatch),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pulse_theme.dart';

/// Applies [PulseTheme] to [child] and rebuilds it when the palette or
/// compact mode changes (the widgets read [PulseTheme] colours directly, so
/// they need a fresh subtree to pick the new values up).
class PulseThemed extends StatelessWidget {
  const PulseThemed({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([PulseTheme.palette, PulseTheme.compact]),
      builder: (context, _) => Theme(
        data: PulseTheme.build(),
        child: KeyedSubtree(
          key: ValueKey((PulseTheme.palette.value, PulseTheme.compact.value)),
          child: child,
        ),
      ),
    );
  }
}

/// Pushes [page] on the current navigator, carrying over the inspector's
/// providers and theme. Pages pushed from the inspector sit outside its
/// `ProviderScope` / `Theme`, so a plain `Navigator.push` would lose both.
Future<T?> pushPulse<T>(BuildContext context, Widget page) {
  final container = ProviderScope.containerOf(context);
  return Navigator.of(context).push(
    MaterialPageRoute<T>(
      builder: (_) => UncontrolledProviderScope(
        container: container,
        child: PulseThemed(child: page),
      ),
    ),
  );
}

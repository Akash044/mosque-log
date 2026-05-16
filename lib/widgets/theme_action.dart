import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';

/// AppBar icon that cycles through System → Light → Dark on tap.
class ThemeAction extends ConsumerWidget {
  const ThemeAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final mode = ref.watch(settingsProvider).themeMode;
    final controller = ref.read(settingsProvider.notifier);

    final IconData icon;
    final String tooltip;
    final ThemeMode next;
    switch (mode) {
      case ThemeMode.system:
        icon = Icons.brightness_auto;
        tooltip = l.themeSystem;
        next = ThemeMode.light;
      case ThemeMode.light:
        icon = Icons.light_mode;
        tooltip = l.themeLight;
        next = ThemeMode.dark;
      case ThemeMode.dark:
        icon = Icons.dark_mode;
        tooltip = l.themeDark;
        next = ThemeMode.system;
    }

    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: () => controller.setThemeMode(next),
    );
  }
}

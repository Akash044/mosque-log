import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l.navSettings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.settingsLanguage,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                          value: 'bn', label: Text(l.languageBangla)),
                      ButtonSegment(
                          value: 'en', label: Text(l.languageEnglish)),
                    ],
                    selected: {settings.locale.languageCode},
                    onSelectionChanged: (s) =>
                        controller.setLocale(Locale(s.first)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.settingsTheme,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment(
                          value: ThemeMode.system,
                          label: Text(l.themeSystem),
                          icon: const Icon(Icons.brightness_auto)),
                      ButtonSegment(
                          value: ThemeMode.light,
                          label: Text(l.themeLight),
                          icon: const Icon(Icons.light_mode)),
                      ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text(l.themeDark),
                          icon: const Icon(Icons.dark_mode)),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (s) =>
                        controller.setThemeMode(s.first),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.tonalIcon(
            onPressed: () => ref.read(authServiceProvider).signOut(),
            icon: const Icon(Icons.logout),
            label: Text(l.signOut),
          ),
        ],
      ),
    );
  }
}

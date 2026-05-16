import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';

/// AppBar icon that toggles between Bangla and English. Tooltip shows the
/// language you would switch to.
class LanguageAction extends ConsumerWidget {
  const LanguageAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(settingsProvider).locale;
    final controller = ref.read(settingsProvider.notifier);
    final isEnglish = locale.languageCode == 'en';

    return IconButton(
      icon: const Icon(Icons.translate),
      tooltip: isEnglish ? l.languageBangla : l.languageEnglish,
      onPressed: () => controller.setLocale(
        Locale(isEnglish ? 'bn' : 'en'),
      ),
    );
  }
}

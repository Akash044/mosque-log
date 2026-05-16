import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/settings_service.dart';

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._service) : super(AppSettings.defaults) {
    _load();
  }

  final SettingsService _service;

  Future<void> _load() async {
    state = await _service.load();
  }

  Future<void> setLocale(Locale locale) async {
    state = state.copyWith(locale: locale);
    await _service.saveLocale(locale);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _service.saveThemeMode(mode);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.watch(settingsServiceProvider));
});

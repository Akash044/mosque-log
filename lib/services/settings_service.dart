import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

class AppSettings {
  final Locale locale;
  final ThemeMode themeMode;
  final bool soundsEnabled;

  const AppSettings({
    required this.locale,
    required this.themeMode,
    required this.soundsEnabled,
  });

  AppSettings copyWith({
    Locale? locale,
    ThemeMode? themeMode,
    bool? soundsEnabled,
  }) {
    return AppSettings(
      locale: locale ?? this.locale,
      themeMode: themeMode ?? this.themeMode,
      soundsEnabled: soundsEnabled ?? this.soundsEnabled,
    );
  }

  static const defaults = AppSettings(
    locale: AppConstants.defaultLocale,
    themeMode: ThemeMode.system,
    soundsEnabled: true,
  );
}

class SettingsService {
  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString(AppConstants.prefLocale);
    final themeCode = prefs.getString(AppConstants.prefThemeMode);
    return AppSettings(
      locale: _parseLocale(localeCode) ?? AppSettings.defaults.locale,
      themeMode: _parseThemeMode(themeCode) ?? AppSettings.defaults.themeMode,
      soundsEnabled: prefs.getBool(AppConstants.prefSoundsEnabled) ??
          AppSettings.defaults.soundsEnabled,
    );
  }

  Future<void> saveLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefLocale, locale.languageCode);
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefThemeMode, mode.name);
  }

  Future<void> saveSoundsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefSoundsEnabled, enabled);
  }

  Locale? _parseLocale(String? code) {
    if (code == null) return null;
    for (final l in AppConstants.supportedLocales) {
      if (l.languageCode == code) return l;
    }
    return null;
  }

  ThemeMode? _parseThemeMode(String? code) {
    switch (code) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return null;
    }
  }
}

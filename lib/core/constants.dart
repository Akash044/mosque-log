import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  // Firestore collection names
  static const personsCollection = 'persons';
  static const incomeCollection = 'income';
  static const expensesCollection = 'expenses';
  static const expenseTypesCollection = 'expenseTypes';
  static const auditLogsCollection = 'audit_logs';
  static const mosquesCollection = 'mosques';
  static const usersCollection = 'users';

  // SharedPreferences keys
  static const prefLocale = 'pref_locale';
  static const prefThemeMode = 'pref_theme_mode';
  static const prefSoundsEnabled = 'pref_sounds_enabled';

  // Default expense types used when no custom list is configured
  static const defaultExpenseTypes = <String>[
    'Imam Salary',
    'Muazzin Salary',
    'Electricity Bill',
    'Water Bill',
    'Maintenance',
    'Cleaning',
    'Gas Bill',
    'Construction',
    'Transportation',
    'Sound System',
    'Repairs',
    'Books',
    'Other',
  ];

  // Eid types
  static const eidTypes = <String>['Eid al-Fitr', 'Eid al-Adha'];

  // Supported locales
  static const supportedLocales = <Locale>[Locale('bn'), Locale('en')];

  // Default locale on first launch — Bangla per project decision
  static const defaultLocale = Locale('bn');

  // Week starts on Saturday (Bangladesh / Islamic week)
  static const int weekStartWeekday = DateTime.saturday;
}

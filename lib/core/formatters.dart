import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'constants.dart';

/// Locale-aware utilities. In Bangla mode, numerals and dates use Bangla
/// digits (০–৯) automatically via [NumberFormat] / [DateFormat] with the
/// `bn` locale. Stored values in Firestore remain plain numbers — this is
/// display-only.
class Formatters {
  Formatters._();

  static String currency(BuildContext context, num amount) {
    final code = Localizations.localeOf(context).languageCode;
    // Whole-number BDT (no decimals)
    final formatter = NumberFormat.decimalPattern(code);
    formatter.maximumFractionDigits = 0;
    return '৳ ${formatter.format(amount)}';
  }

  static String number(BuildContext context, num value) {
    final code = Localizations.localeOf(context).languageCode;
    return NumberFormat.decimalPattern(code).format(value);
  }

  static String date(BuildContext context, DateTime date,
      {String pattern = 'd MMM y'}) {
    final code = Localizations.localeOf(context).languageCode;
    return DateFormat(pattern, code).format(date);
  }

  static String monthLabel(BuildContext context, DateTime date) {
    final code = Localizations.localeOf(context).languageCode;
    return DateFormat('MMMM y', code).format(date);
  }

  /// Returns the start of the current week (Saturday by project convention),
  /// at midnight.
  static DateTime startOfWeek(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    // weekday: Mon=1 ... Sun=7
    // Saturday=6 should map to 0 days back. Compute days since last Saturday.
    int daysBack = today.weekday - AppConstants.weekStartWeekday;
    if (daysBack < 0) daysBack += 7;
    return today.subtract(Duration(days: daysBack));
  }

  static DateTime endOfWeek(DateTime now) =>
      startOfWeek(now).add(const Duration(days: 7));

  /// YYYY-MM key used in Income.months arrays.
  static String monthKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

  static DateTime monthFromKey(String key) {
    final parts = key.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]));
  }

  static String localizedMonthFromKey(BuildContext context, String key) {
    return monthLabel(context, monthFromKey(key));
  }
}

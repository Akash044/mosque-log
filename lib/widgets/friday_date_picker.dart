import 'package:flutter/material.dart';

Future<DateTime?> showFridayPicker(
  BuildContext context, {
  DateTime? initial,
}) async {
  final now = DateTime.now();
  DateTime initialDate = initial ?? _lastFriday(now);
  if (initialDate.weekday != DateTime.friday) {
    initialDate = _lastFriday(initialDate);
  }
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(now.year - 5),
    lastDate: DateTime(now.year + 5),
    selectableDayPredicate: (d) => d.weekday == DateTime.friday,
  );
}

DateTime _lastFriday(DateTime d) {
  final base = DateTime(d.year, d.month, d.day);
  final diff = (base.weekday - DateTime.friday + 7) % 7;
  return base.subtract(Duration(days: diff));
}

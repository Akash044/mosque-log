import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../l10n/app_localizations.dart';

class MonthMultiSelect extends StatefulWidget {
  const MonthMultiSelect({
    super.key,
    required this.selected,
    required this.onChanged,
    this.paidMonths = const <String>{},
  });

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  /// Month keys (YYYY-MM) to hide from the picker — typically the months
  /// the currently-selected person has already paid.
  final Set<String> paidMonths;

  @override
  State<MonthMultiSelect> createState() => _MonthMultiSelectState();
}

class _MonthMultiSelectState extends State<MonthMultiSelect> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final selected = widget.selected;

    final chips = <Widget>[];
    for (var i = 0; i < 12; i++) {
      final month = DateTime(_year, i + 1);
      final key = Formatters.monthKey(month);
      if (widget.paidMonths.contains(key)) continue;
      final on = selected.contains(key);
      chips.add(FilterChip(
        label: Text(Formatters.date(context, month, pattern: 'MMM')),
        selected: on,
        onSelected: (v) {
          final next = Set<String>.from(selected);
          if (v) {
            next.add(key);
          } else {
            next.remove(key);
          }
          widget.onChanged(next);
        },
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(l.selectMonths,
                style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() => _year -= 1),
            ),
            Text(
              Formatters.number(context, _year),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(() => _year += 1),
            ),
          ],
        ),
        if (chips.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              l.allMonthsPaid,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          Wrap(spacing: 8, runSpacing: 8, children: chips),
      ],
    );
  }
}

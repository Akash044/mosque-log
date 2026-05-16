import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/income.dart';
import '../../../models/person.dart';
import '../../../providers/income_provider.dart';
import '../../../providers/person_provider.dart';
import 'income_csv_export.dart';
import 'income_history_list.dart';

/// Monthly payments history with Person / Month filters and a year navigator
/// inline with the "History" heading.
class MonthlyHistory extends ConsumerStatefulWidget {
  const MonthlyHistory({super.key});

  @override
  ConsumerState<MonthlyHistory> createState() => _MonthlyHistoryState();
}

class _MonthlyHistoryState extends ConsumerState<MonthlyHistory> {
  String? _personId; // null = all
  int? _month; // 1..12, null = all
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
  }

  bool _matches(Income i) {
    if (_personId != null && i.personId != _personId) return false;
    final yearStr = _year.toString().padLeft(4, '0');
    if (_month != null) {
      final key = '$yearStr-${_month.toString().padLeft(2, '0')}';
      return i.months.contains(key);
    }
    return i.months.any((m) => m.startsWith('$yearStr-'));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final incomeAsync = ref.watch(incomeProvider);
    final personsAsync = ref.watch(personsProvider);

    final filtered = incomeAsync.maybeWhen(
      data: (all) => all
          .where((i) => i.type == IncomeType.monthly && _matches(i))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date)),
      orElse: () => const <Income>[],
    );
    final personsById = personsAsync.maybeWhen(
      data: (xs) => {for (final p in xs) p.id: p},
      orElse: () => <String, Person>{},
    );

    return Column(
      children: [
        _HeadingWithYear(
          year: _year,
          onPrev: () => setState(() => _year -= 1),
          onNext: () => setState(() => _year += 1),
          onExport: filtered.isEmpty
              ? null
              : () => shareIncomeCsv(
                    context,
                    records: filtered,
                    personsById: personsById,
                    filenameStem: 'monthly_payments',
                  ),
        ),
        _FilterBar(
          personId: _personId,
          month: _month,
          year: _year,
          personsAsync: personsAsync,
          onPersonChanged: (id) => setState(() => _personId = id),
          onMonthChanged: (m) => setState(() => _month = m),
        ),
        const Divider(height: 1),
        Expanded(
          child: incomeAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
            data: (_) {
              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(l.noData),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => IncomeTile(
                  income: filtered[i],
                  personsById: personsById,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HeadingWithYear extends StatelessWidget {
  const _HeadingWithYear({
    required this.year,
    required this.onPrev,
    required this.onNext,
    required this.onExport,
  });

  final int year;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l.history, style: Theme.of(context).textTheme.titleMedium),
          Row(
            children: [
              if (onExport != null)
                IconButton(
                  icon: const Icon(Icons.ios_share),
                  tooltip: l.exportCsv,
                  onPressed: onExport,
                ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: onPrev,
              ),
              Text(
                Formatters.year(context, year),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: onNext,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.personId,
    required this.month,
    required this.year,
    required this.personsAsync,
    required this.onPersonChanged,
    required this.onMonthChanged,
  });

  final String? personId;
  final int? month;
  final int year;
  final AsyncValue<List<Person>> personsAsync;
  final ValueChanged<String?> onPersonChanged;
  final ValueChanged<int?> onMonthChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: personsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(e.toString()),
              data: (persons) {
                final exists = personId == null ||
                    persons.any((p) => p.id == personId);
                if (!exists) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => onPersonChanged(null),
                  );
                }
                return DropdownMenu<String?>(
                  key: ValueKey(personId ?? ''),
                  initialSelection: exists ? personId : null,
                  enableFilter: true,
                  enableSearch: true,
                  requestFocusOnTap: true,
                  expandedInsets: EdgeInsets.zero,
                  label: Text(l.person),
                  menuHeight: 320,
                  inputDecorationTheme:
                      Theme.of(context).inputDecorationTheme,
                  dropdownMenuEntries: <DropdownMenuEntry<String?>>[
                    DropdownMenuEntry<String?>(
                        value: null, label: l.allPersons),
                    ...persons.map((p) => DropdownMenuEntry<String?>(
                          value: p.id,
                          label: p.name,
                        )),
                  ],
                  onSelected: onPersonChanged,
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<int?>(
              initialValue: month,
              decoration: InputDecoration(
                labelText: l.month,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
              ),
              items: <DropdownMenuItem<int?>>[
                DropdownMenuItem(value: null, child: Text(l.allMonths)),
                ...List.generate(
                  12,
                  (i) => DropdownMenuItem<int?>(
                    value: i + 1,
                    child: Text(
                      Formatters.date(context, DateTime(year, i + 1),
                          pattern: 'MMM'),
                    ),
                  ),
                ),
              ],
              onChanged: onMonthChanged,
            ),
          ),
        ],
      ),
    );
  }
}

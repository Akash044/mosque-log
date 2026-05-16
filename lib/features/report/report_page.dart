import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../l10n/app_localizations.dart';
import '../../models/income.dart';
import '../../providers/expense_provider.dart';
import '../../providers/income_provider.dart';
import '../../widgets/settings_action.dart';

class ReportPage extends ConsumerStatefulWidget {
  const ReportPage({super.key});

  @override
  ConsumerState<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends ConsumerState<ReportPage> {
  late DateTimeRange _range;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _range = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _range,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => _range = picked);
  }

  String _incomeTypeLabel(BuildContext context, IncomeType t) {
    final l = AppLocalizations.of(context);
    switch (t) {
      case IncomeType.general:
        return l.incomeGeneral;
      case IncomeType.jumma:
        return l.incomeJumma;
      case IncomeType.monthly:
        return l.incomeMonthly;
      case IncomeType.eid:
        return l.incomeEid;
      case IncomeType.ramadan:
        return l.incomeRamadan;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final incomeAsync = ref.watch(incomeProvider);
    final expenseAsync = ref.watch(expenseProvider);
    final endExclusive = DateTime(
      _range.end.year,
      _range.end.month,
      _range.end.day + 1,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l.reportTitle),
        actions: const [SettingsAction()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.date_range),
              title: Text(
                '${Formatters.date(context, _range.start)} — '
                '${Formatters.date(context, _range.end)}',
              ),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _pickRange,
            ),
          ),
          const SizedBox(height: 12),
          incomeAsync.when(
            loading: () =>
                const LinearProgressIndicator(),
            error: (e, _) => Text(e.toString()),
            data: (allIncome) {
              final scoped = allIncome
                  .where((i) =>
                      !i.date.isBefore(_range.start) &&
                      i.date.isBefore(endExclusive))
                  .toList();
              final byType = <IncomeType, double>{};
              for (final i in scoped) {
                byType.update(i.type, (v) => v + i.amount,
                    ifAbsent: () => i.amount);
              }
              final totalIncome =
                  scoped.fold<double>(0, (s, i) => s + i.amount);

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.incomeBreakdown,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      if (scoped.isEmpty)
                        Text(l.noData)
                      else
                        ...IncomeType.values.map((t) {
                          final v = byType[t] ?? 0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(child: Text(_incomeTypeLabel(context, t))),
                                Text(Formatters.currency(context, v)),
                              ],
                            ),
                          );
                        }),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l.totalIncome,
                              style: Theme.of(context).textTheme.titleSmall),
                          Text(
                            Formatters.currency(context, totalIncome),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          expenseAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(e.toString()),
            data: (allExp) {
              final scoped = allExp
                  .where((e) =>
                      !e.date.isBefore(_range.start) &&
                      e.date.isBefore(endExclusive))
                  .toList();
              final byType = <String, double>{};
              for (final e in scoped) {
                byType.update(e.expenseType, (v) => v + e.amount,
                    ifAbsent: () => e.amount);
              }
              final totalExp =
                  scoped.fold<double>(0, (s, e) => s + e.amount);

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.totalExpense,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      if (scoped.isEmpty)
                        Text(l.noData)
                      else
                        ...byType.entries.map((e) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(child: Text(e.key)),
                                Text(Formatters.currency(context, e.value)),
                              ],
                            ),
                          );
                        }),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l.totalExpense,
                              style: Theme.of(context).textTheme.titleSmall),
                          Text(
                            Formatters.currency(context, totalExp),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _NetBalanceCard(rangeStart: _range.start, rangeEndExclusive: endExclusive),
        ],
      ),
    );
  }
}

class _NetBalanceCard extends ConsumerWidget {
  const _NetBalanceCard({
    required this.rangeStart,
    required this.rangeEndExclusive,
  });

  final DateTime rangeStart;
  final DateTime rangeEndExclusive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final incomeAsync = ref.watch(incomeProvider);
    final expenseAsync = ref.watch(expenseProvider);

    final income = incomeAsync.maybeWhen(
      data: (xs) => xs
          .where((i) =>
              !i.date.isBefore(rangeStart) &&
              i.date.isBefore(rangeEndExclusive))
          .fold<double>(0, (s, i) => s + i.amount),
      orElse: () => 0.0,
    );
    final exp = expenseAsync.maybeWhen(
      data: (xs) => xs
          .where((e) =>
              !e.date.isBefore(rangeStart) &&
              e.date.isBefore(rangeEndExclusive))
          .fold<double>(0, (s, e) => s + e.amount),
      orElse: () => 0.0,
    );
    final net = income - exp;
    return Card(
      child: ListTile(
        title: Text(l.netBalance,
            style: Theme.of(context).textTheme.titleMedium),
        trailing: Text(
          Formatters.currency(context, net),
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

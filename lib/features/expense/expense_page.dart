import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../l10n/app_localizations.dart';
import '../../models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../providers/firestore_provider.dart';
import '../../widgets/settings_action.dart';
import 'widgets/add_expense_dialog.dart';

class ExpensePage extends ConsumerStatefulWidget {
  const ExpensePage({super.key});

  @override
  ConsumerState<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends ConsumerState<ExpensePage>
    with SingleTickerProviderStateMixin {
  late int _year;
  TabController? _tab;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _tab = TabController(
      length: 12,
      vsync: this,
      initialIndex: now.month - 1,
    );
  }

  @override
  void dispose() {
    _tab?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final expensesAsync = ref.watch(expenseProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.navExpense),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() => _year -= 1),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                Formatters.year(context, _year),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() => _year += 1),
          ),
          const SettingsAction(),
        ],
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabs: List.generate(12, (i) {
            final month = DateTime(_year, i + 1);
            return Tab(
              text: Formatters.date(context, month, pattern: 'MMM'),
            );
          }),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final monthIndex = _tab?.index ?? 0;
          final defaultDate = _defaultDateForTab(monthIndex);
          await showDialog(
            context: context,
            builder: (_) => AddExpenseDialog(initialDate: defaultDate),
          );
        },
        icon: const Icon(Icons.add),
        label: Text(l.addExpense),
      ),
      body: expensesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (all) {
          return TabBarView(
            controller: _tab,
            children: List.generate(12, (i) {
              final from = DateTime(_year, i + 1);
              final to = DateTime(_year, i + 2);
              final monthList = all
                  .where((e) =>
                      !e.date.isBefore(from) && e.date.isBefore(to))
                  .toList()
                ..sort((a, b) => b.date.compareTo(a.date));
              return _ExpenseList(items: monthList);
            }),
          );
        },
      ),
    );
  }

  DateTime _defaultDateForTab(int monthIndex) {
    final now = DateTime.now();
    if (_year == now.year && monthIndex == now.month - 1) return now;
    return DateTime(_year, monthIndex + 1, 1);
  }
}

class _ExpenseList extends ConsumerWidget {
  const _ExpenseList({required this.items});
  final List<Expense> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    if (items.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(child: Text(l.noExpenses)),
        ],
      );
    }
    final total = items.fold<double>(0, (s, e) => s + e.amount);
    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l.totalExpense,
                  style: Theme.of(context).textTheme.titleSmall),
              Text(
                Formatters.currency(context, total),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final e = items[i];
              return Dismissible(
                key: ValueKey(e.id),
                background: Container(
                  color: Theme.of(context).colorScheme.errorContainer,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: const Icon(Icons.delete_outline),
                ),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                        context: context,
                        builder: (dialogCtx) => AlertDialog(
                          content: Text(l.deleteConfirm),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogCtx).pop(false),
                              child: Text(l.no),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.of(dialogCtx).pop(true),
                              child: Text(l.yes),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                },
                onDismissed: (_) {
                  ref
                      .read(firestoreServiceProvider)
                      .deleteExpense(e.id);
                },
                child: ListTile(
                  title: Text(e.expenseType),
                  subtitle: Text(Formatters.date(context, e.date)),
                  trailing: Text(
                    Formatters.currency(context, e.amount),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

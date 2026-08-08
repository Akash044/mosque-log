import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../l10n/app_localizations.dart';
import '../../models/income.dart';
import '../../providers/expense_provider.dart';
import '../../providers/income_provider.dart';
import '../../providers/mosque_provider.dart';
import '../../widgets/language_action.dart';
import '../../widgets/settings_action.dart';
import '../../widgets/theme_action.dart';
import 'widgets/summary_card.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final incomeAsync = ref.watch(incomeProvider);
    final expenseAsync = ref.watch(expenseProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.navDashboard),
        actions: const [
          LanguageAction(),
          ThemeAction(),
          SettingsAction(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(incomeProvider);
          ref.invalidate(expenseProvider);
        },
        child: incomeAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => _errorList(e.toString()),
          data: (incomes) => expenseAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => _errorList(e.toString()),
            data: (expenses) {
              final totalIncome =
                  incomes.fold<double>(0, (s, i) => s + i.amount);
              final totalExpense =
                  expenses.fold<double>(0, (s, e) => s + e.amount);

              final now = DateTime.now();
              final weekStart = Formatters.startOfWeek(now);
              final weekEnd = Formatters.endOfWeek(now);
              final weekIncome = incomes
                  .where((i) =>
                      !i.date.isBefore(weekStart) && i.date.isBefore(weekEnd))
                  .fold<double>(0, (s, i) => s + i.amount);

              final jummaIncome = incomes
                  .where((i) => i.type == IncomeType.jumma)
                  .fold<double>(0, (s, i) => s + i.amount);

              final net = totalIncome - totalExpense;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const _MosqueHeader(),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.25,
                    children: [
                      SummaryCard(
                        title: l.totalIncome,
                        value: Formatters.currency(context, totalIncome),
                        icon: Icons.trending_up,
                      ),
                      SummaryCard(
                        title: l.totalExpense,
                        value: Formatters.currency(context, totalExpense),
                        icon: Icons.trending_down,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      SummaryCard(
                        title: l.currentWeekIncome,
                        value: Formatters.currency(context, weekIncome),
                        icon: Icons.calendar_today,
                      ),
                      SummaryCard(
                        title: l.jummaIncome,
                        value: Formatters.currency(context, jummaIncome),
                        icon: Icons.mosque,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: Icon(
                        net >= 0 ? Icons.account_balance_wallet : Icons.warning,
                        color: net >= 0
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.error,
                      ),
                      title: Text(l.netBalance),
                      trailing: Text(
                        Formatters.currency(context, net),
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _errorList(String message) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red)),
      ],
    );
  }
}

class _MosqueHeader extends ConsumerWidget {
  const _MosqueHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final mosque = ref.watch(currentMosqueProvider).valueOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.mosque, size: 36, color: scheme.primary),
        const SizedBox(height: 6),
        Text(
          mosque?.name ?? l.mosqueName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          mosque?.address ?? l.mosqueAddress,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

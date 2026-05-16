import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/income.dart';
import '../../../models/person.dart';
import '../../../providers/firestore_provider.dart';
import '../../../providers/income_provider.dart';
import '../../../providers/person_provider.dart';

/// Sticky heading shown above an [IncomeHistoryList] when it sits inside a
/// fixed-form-on-top / scrollable-history-below layout.
Widget historyHeading(BuildContext context, String text) {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      border: Border(
        top: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
    ),
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

/// Shared "recent entries" list shown below each income form. Filters
/// `incomeProvider` to a single [IncomeType] and renders one row per doc,
/// with swipe-to-delete and a per-type subtitle.
class IncomeHistoryList extends ConsumerWidget {
  const IncomeHistoryList({super.key, required this.type, this.maxItems = 50});

  final IncomeType type;
  final int maxItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final incomeAsync = ref.watch(incomeProvider);
    // Persons map only needed for monthly rows.
    final personsAsync = type == IncomeType.monthly
        ? ref.watch(personsProvider)
        : const AsyncValue<List<Person>>.data([]);

    return incomeAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (all) {
        final scoped = all.where((i) => i.type == type).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        final items = scoped.take(maxItems).toList();
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l.noData),
            ),
          );
        }
        final personsById = personsAsync.maybeWhen(
          data: (xs) => {for (final p in xs) p.id: p},
          orElse: () => <String, Person>{},
        );
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) => IncomeTile(
            income: items[i],
            personsById: personsById,
          ),
        );
      },
    );
  }
}

class IncomeTile extends ConsumerWidget {
  const IncomeTile({super.key, required this.income, required this.personsById});

  final Income income;
  final Map<String, Person> personsById;

  String _title(BuildContext context) {
    final l = AppLocalizations.of(context);
    switch (income.type) {
      case IncomeType.general:
        return (income.donorName == null || income.donorName!.isEmpty)
            ? l.anonymous
            : income.donorName!;
      case IncomeType.jumma:
        return l.incomeJumma;
      case IncomeType.monthly:
        return personsById[income.personId]?.name ?? l.unknown;
      case IncomeType.eid:
        return _eidLabel(context, income.eidType);
    }
  }

  String _eidLabel(BuildContext context, String? key) {
    final l = AppLocalizations.of(context);
    if (key == 'Eid al-Fitr') return l.eidFitr;
    if (key == 'Eid al-Adha') return l.eidAdha;
    return l.incomeEid;
  }

  String _subtitle(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dateStr = Formatters.date(context, income.date);
    switch (income.type) {
      case IncomeType.general:
        final qty = income.quantity;
        final note = income.note?.trim();
        final head = (qty != null && qty > 0)
            ? '$dateStr  ·  ${Formatters.number(context, qty)} ${l.qty}'
            : dateStr;
        if (note != null && note.isNotEmpty) {
          return '$head\n$note';
        }
        return head;
      case IncomeType.jumma:
        return Formatters.date(context, income.date,
            pattern: 'EEEE, d MMM y');
      case IncomeType.monthly:
        final months = income.months
            .map((k) => Formatters.localizedMonthFromKey(context, k))
            .join(', ');
        return '$months\n$dateStr';
      case IncomeType.eid:
        return dateStr;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final title = _title(context);
    final subtitle = _subtitle(context);
    final isThreeLine =
        (income.type == IncomeType.monthly && income.months.isNotEmpty) ||
            (income.type == IncomeType.general &&
                (income.note?.trim().isNotEmpty ?? false));

    return Dismissible(
      key: ValueKey(income.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const Icon(Icons.delete_outline),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                content: Text(l.deleteConfirm),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l.no),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(l.yes),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) =>
          ref.read(firestoreServiceProvider).deleteIncome(income.id),
      child: ListTile(
        title: Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        isThreeLine: isThreeLine,
        trailing: income.amount > 0
            ? Text(
                Formatters.currency(context, income.amount),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              )
            : null,
      ),
    );
  }
}

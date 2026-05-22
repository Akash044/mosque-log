import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audit.dart';
import '../../../core/feedback.dart';
import '../../../core/formatters.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/income.dart';
import '../../../models/person.dart';
import '../../../providers/firestore_provider.dart';
import '../../../providers/income_provider.dart';
import '../../../providers/person_provider.dart';
import 'income_csv_export.dart';

/// Shared "recent entries" list with a built-in heading + export button.
/// Filters `incomeProvider` to a single [IncomeType] and renders one row per
/// doc, with swipe-to-delete and a per-type subtitle.
class IncomeHistoryList extends ConsumerWidget {
  const IncomeHistoryList({super.key, required this.type, this.maxItems = 50});

  final IncomeType type;
  final int maxItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final incomeAsync = ref.watch(incomeProvider);
    final needsPersons =
        type == IncomeType.monthly || type == IncomeType.ramadan;
    final personsAsync = needsPersons
        ? ref.watch(personsProvider)
        : const AsyncValue<List<Person>>.data([]);

    return incomeAsync.when(
      loading: () => Column(
        children: [
          historyHeading(context, l.history),
          const Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      ),
      error: (e, _) => Column(
        children: [
          historyHeading(context, l.history),
          Expanded(child: Center(child: Text(e.toString()))),
        ],
      ),
      data: (all) {
        final scoped = all.where((i) => i.type == type).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        final items = scoped.take(maxItems).toList();
        final personsById = personsAsync.maybeWhen(
          data: (xs) => {for (final p in xs) p.id: p},
          orElse: () => <String, Person>{},
        );

        return Column(
          children: [
            historyHeading(
              context,
              l.history,
              onExport: items.isEmpty
                  ? null
                  : () => shareIncomeCsv(
                        context,
                        records: items,
                        personsById: personsById,
                        filenameStem: '${type.key}_history',
                      ),
            ),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(l.noData),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) => IncomeTile(
                        income: items[i],
                        personsById: personsById,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// Top-bordered heading row used above a history list. Renders the title on
/// the left and, when [onExport] is non-null, an export-CSV icon on the right.
Widget historyHeading(
  BuildContext context,
  String text, {
  VoidCallback? onExport,
}) {
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
      children: [
        Text(text, style: Theme.of(context).textTheme.titleMedium),
        const Spacer(),
        if (onExport != null)
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: l.exportCsv,
            onPressed: onExport,
          ),
      ],
    ),
  );
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
      case IncomeType.ramadan:
        return personsById[income.personId]?.name ?? l.unknown;
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
      case IncomeType.ramadan:
        final note = income.note?.trim();
        if (note != null && note.isNotEmpty) {
          return '$dateStr\n$note';
        }
        return dateStr;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final title = _title(context);
    final subtitle = _subtitle(context);
    final hasNote = income.note?.trim().isNotEmpty ?? false;
    final isThreeLine =
        (income.type == IncomeType.monthly && income.months.isNotEmpty) ||
            (income.type == IncomeType.general && hasNote) ||
            (income.type == IncomeType.ramadan && hasNote);

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
              builder: (dialogCtx) => AlertDialog(
                content: Text(l.deleteConfirm),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(false),
                    child: Text(l.no),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(true),
                    child: Text(l.yes),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) async {
        await ref.read(firestoreServiceProvider).deleteIncome(income.id);
        await logAudit(
          ref,
          action: 'delete',
          entityType: 'income.${income.type.key}',
          entityId: income.id,
          summary:
              'Deleted ${income.type.key} entry ৳${income.amount.toInt()} (${income.date.toIso8601String().substring(0, 10)})',
        );
        playEntryDeleted(ref);
      },
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

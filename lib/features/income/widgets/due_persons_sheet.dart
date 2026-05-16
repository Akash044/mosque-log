import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/income_provider.dart';
import '../../../providers/person_provider.dart';

class DuePersonsSheet extends ConsumerStatefulWidget {
  const DuePersonsSheet({super.key});

  @override
  ConsumerState<DuePersonsSheet> createState() => _DuePersonsSheetState();
}

class _DuePersonsSheetState extends ConsumerState<DuePersonsSheet> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() => _month = DateTime(picked.year, picked.month));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final monthKey = Formatters.monthKey(_month);
    final personsAsync = ref.watch(activePersonsProvider);
    final paidAsync = ref.watch(monthlyDueProvider(monthKey));

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: Text(l.duePersonsTitle),
                subtitle: Text(Formatters.monthLabel(context, _month)),
                trailing: TextButton.icon(
                  onPressed: _pickMonth,
                  icon: const Icon(Icons.event),
                  label: Text(l.selectDate),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: personsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text(e.toString())),
                  data: (persons) => paidAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text(e.toString())),
                    data: (paidDocs) {
                      final paidIds = paidDocs
                          .map((i) => i.personId)
                          .whereType<String>()
                          .toSet();
                      final due = persons
                          .where((p) => !paidIds.contains(p.id))
                          .toList();
                      if (due.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(l.noDuePersons),
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: due.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final p = due[i];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                p.name.isEmpty ? '?' : p.name[0].toUpperCase(),
                              ),
                            ),
                            title: Text(p.name),
                            subtitle: p.phone == null ? null : Text(p.phone!),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

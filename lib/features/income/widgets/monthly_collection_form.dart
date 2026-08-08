import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/income.dart';
import '../../../models/person.dart';
import '../../../core/audit.dart';
import '../../../core/feedback.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/firestore_provider.dart';
import '../../../providers/income_provider.dart';
import '../../../providers/mosque_provider.dart';
import '../../../providers/person_provider.dart';
import '../../../widgets/month_multi_select.dart';
import 'add_person_dialog.dart';
import 'income_history_list.dart';
import 'monthly_history.dart';

class MonthlyCollectionForm extends ConsumerStatefulWidget {
  const MonthlyCollectionForm({super.key});

  @override
  ConsumerState<MonthlyCollectionForm> createState() =>
      _MonthlyCollectionFormState();
}

class _MonthlyCollectionFormState
    extends ConsumerState<MonthlyCollectionForm> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  Person? _person;
  Set<String> _months = <String>{};
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_person == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.selectPerson)));
      return;
    }
    if (_months.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.noMonthsSelected)));
      return;
    }
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) return;
    setState(() => _saving = true);
    final uid = ref.read(authServiceProvider).currentUser?.uid ?? '';
    final mosqueId = ref.read(currentMosqueIdProvider) ?? '';
    final sortedMonths = _months.toList()..sort();
    final docId = await ref.read(firestoreServiceProvider).addIncome(Income(
          id: '',
          mosqueId: mosqueId,
          type: IncomeType.monthly,
          amount: amount,
          date: DateTime.now(),
          personId: _person!.id,
          months: sortedMonths,
          createdBy: uid,
          createdAt: DateTime.now(),
        ));
    await logAudit(
      ref,
      action: 'create',
      entityType: 'income.monthly',
      entityId: docId,
      summary:
          'Added monthly payment ৳${amount.toInt()} from ${_person!.name} for ${sortedMonths.join(", ")}',
    );
    playEntryAdded(ref);
    if (!mounted) return;
    _amount.clear();
    setState(() {
      _months = <String>{};
      _saving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.save), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final personsAsync = ref.watch(activePersonsProvider);
    final incomeAsync = ref.watch(incomeProvider);

    // Build paidMonths set for the currently-selected person.
    final paidMonths = <String>{};
    if (_person != null) {
      incomeAsync.whenData((all) {
        for (final i in all) {
          if (i.type == IncomeType.monthly && i.personId == _person!.id) {
            paidMonths.addAll(i.months);
          }
        }
      });
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                  personsAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text(e.toString()),
                    data: (persons) {
                      if (_person != null &&
                          !persons.any((p) => p.id == _person!.id)) {
                        _person = null;
                      }
                      return Row(
                        children: [
                          Expanded(
                            child: DropdownMenu<Person>(
                              key: ValueKey(_person?.id ?? ''),
                              initialSelection: _person,
                              enableFilter: true,
                              enableSearch: true,
                              requestFocusOnTap: true,
                              expandedInsets: EdgeInsets.zero,
                              label: Text(l.person),
                              menuHeight: 320,
                              inputDecorationTheme:
                                  Theme.of(context).inputDecorationTheme,
                              dropdownMenuEntries: persons
                                  .map((p) => DropdownMenuEntry<Person>(
                                        value: p,
                                        label: p.name,
                                      ))
                                  .toList(),
                              onSelected: (p) => setState(() {
                                _person = p;
                                _months = <String>{};
                              }),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.person_add),
                            tooltip: l.addPerson,
                            onPressed: () => showDialog(
                              context: context,
                              builder: (_) => const AddPersonDialog(),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  MonthMultiSelect(
                    selected: _months,
                    paidMonths: paidMonths,
                    onChanged: (v) => setState(() => _months = v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _amount,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: l.amount),
                          validator: (v) {
                            if ((v ?? '').trim().isEmpty) {
                              return l.amountRequired;
                            }
                            final n = double.tryParse(v!.trim());
                            if (n == null || n <= 0) return l.amountInvalid;
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 56,
                        width: 140,
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : Text(l.save),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const Expanded(
          child: MonthlyHistory(),
        ),
      ],
    );
  }
}

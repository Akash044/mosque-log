import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/income.dart';
import '../../../models/person.dart';
import '../../../core/audit.dart';
import '../../../core/feedback.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/firestore_provider.dart';
import '../../../providers/person_provider.dart';
import 'add_person_dialog.dart';
import 'income_history_list.dart';

class RamadanForm extends ConsumerStatefulWidget {
  const RamadanForm({super.key});

  @override
  ConsumerState<RamadanForm> createState() => _RamadanFormState();
}

class _RamadanFormState extends ConsumerState<RamadanForm> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  Person? _person;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_person == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.selectPerson)));
      return;
    }
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) return;
    setState(() => _saving = true);
    final uid = ref.read(authServiceProvider).currentUser?.uid ?? '';
    final docId = await ref.read(firestoreServiceProvider).addIncome(Income(
          id: '',
          type: IncomeType.ramadan,
          amount: amount,
          date: _date,
          personId: _person!.id,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          createdBy: uid,
          createdAt: DateTime.now(),
        ));
    await logAudit(
      ref,
      action: 'create',
      entityType: 'income.ramadan',
      entityId: docId,
      summary: 'Added Ramadan payment ৳${amount.toInt()} from ${_person!.name}',
    );
    playEntryAdded(ref);
    if (!mounted) return;
    _amount.clear();
    _note.clear();
    setState(() {
      _date = DateTime.now();
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
                            onSelected: (p) => setState(() => _person = p),
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
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l.date,
                      prefixIcon: const Icon(Icons.calendar_today),
                    ),
                    child: Text(Formatters.date(context, _date)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l.amount),
                  validator: (v) {
                    if ((v ?? '').trim().isEmpty) return l.amountRequired;
                    final n = double.tryParse(v!.trim());
                    if (n == null || n <= 0) return l.amountInvalid;
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _note,
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(labelText: l.noteOptional),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l.save),
                ),
              ],
            ),
          ),
        ),
        const Expanded(
          child: IncomeHistoryList(type: IncomeType.ramadan),
        ),
      ],
    );
  }
}

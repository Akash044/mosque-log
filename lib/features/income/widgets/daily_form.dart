import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audit.dart';
import '../../../core/feedback.dart';
import '../../../core/formatters.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/income.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/firestore_provider.dart';
import '../../../providers/income_provider.dart';
import '../../../providers/mosque_provider.dart';
import 'income_history_list.dart';

class DailyForm extends ConsumerStatefulWidget {
  const DailyForm({super.key});

  @override
  ConsumerState<DailyForm> createState() => _DailyFormState();
}

class _DailyFormState extends ConsumerState<DailyForm> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
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
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) return;
    // Block duplicates for the same day.
    final existing = ref.read(incomeProvider).value ?? const <Income>[];
    final dupe = existing.any((i) =>
        i.type == IncomeType.daily &&
        i.date.year == _date.year &&
        i.date.month == _date.month &&
        i.date.day == _date.day);
    if (dupe) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.dailyDuplicate)));
      return;
    }
    setState(() => _saving = true);
    final uid = ref.read(authServiceProvider).currentUser?.uid ?? '';
    final mosqueId = ref.read(currentMosqueIdProvider) ?? '';
    final noteText = _note.text.trim();
    final docId = await ref.read(firestoreServiceProvider).addIncome(Income(
          id: '',
          mosqueId: mosqueId,
          type: IncomeType.daily,
          amount: amount,
          date: _date,
          note: noteText.isEmpty ? null : noteText,
          createdBy: uid,
          createdAt: DateTime.now(),
        ));
    await logAudit(
      ref,
      action: 'create',
      entityType: 'income.daily',
      entityId: docId,
      summary:
          'Added daily collection ৳${amount.toInt()} on ${_date.toIso8601String().substring(0, 10)}',
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
          child: IncomeHistoryList(type: IncomeType.daily),
        ),
      ],
    );
  }
}

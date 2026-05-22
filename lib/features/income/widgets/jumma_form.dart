import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/income.dart';
import '../../../core/audit.dart';
import '../../../core/feedback.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/firestore_provider.dart';
import '../../../providers/income_provider.dart';
import '../../../widgets/friday_date_picker.dart';
import 'income_history_list.dart';

class JummaForm extends ConsumerStatefulWidget {
  const JummaForm({super.key});

  @override
  ConsumerState<JummaForm> createState() => _JummaFormState();
}

class _JummaFormState extends ConsumerState<JummaForm> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  DateTime? _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _date = _lastFriday();
  }

  DateTime _lastFriday() {
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day);
    final diff = (base.weekday - DateTime.friday + 7) % 7;
    return base.subtract(Duration(days: diff));
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showFridayPicker(context, initial: _date);
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_date == null) return;
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.amountInvalid)));
      return;
    }
    // Block duplicates for the same Friday.
    final existing = ref.read(incomeProvider).value ?? const <Income>[];
    final dupe = existing.any((i) =>
        i.type == IncomeType.jumma &&
        i.date.year == _date!.year &&
        i.date.month == _date!.month &&
        i.date.day == _date!.day);
    if (dupe) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.jummaDuplicate)));
      return;
    }
    setState(() => _saving = true);
    final uid = ref.read(authServiceProvider).currentUser?.uid ?? '';
    final docId = await ref.read(firestoreServiceProvider).addIncome(Income(
          id: '',
          type: IncomeType.jumma,
          amount: amount,
          date: _date!,
          createdBy: uid,
          createdAt: DateTime.now(),
        ));
    await logAudit(
      ref,
      action: 'create',
      entityType: 'income.jumma',
      entityId: docId,
      summary:
          'Added Jumma collection ৳${amount.toInt()} on ${_date!.toIso8601String().substring(0, 10)}',
    );
    playEntryAdded(ref);
    if (!mounted) return;
    _amount.clear();
    setState(() {
      _date = _lastFriday();
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
                        labelText: l.fridayOnly,
                        prefixIcon: const Icon(Icons.event),
                      ),
                      child: Text(
                        _date == null
                            ? l.selectDate
                            : Formatters.date(context, _date!,
                                pattern: 'EEEE, d MMM y'),
                      ),
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
          child: IncomeHistoryList(type: IncomeType.jumma),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/formatters.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/income.dart';
import '../../../core/audit.dart';
import '../../../core/feedback.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/firestore_provider.dart';
import 'income_history_list.dart';

class EidForm extends ConsumerStatefulWidget {
  const EidForm({super.key});

  @override
  ConsumerState<EidForm> createState() => _EidFormState();
}

class _EidFormState extends ConsumerState<EidForm> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  String? _eidType;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  String _label(BuildContext context, String key) {
    final l = AppLocalizations.of(context);
    if (key == 'Eid al-Fitr') return l.eidFitr;
    return l.eidAdha;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_eidType == null) return;
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) return;
    setState(() => _saving = true);
    final uid = ref.read(authServiceProvider).currentUser?.uid ?? '';
    final docId = await ref.read(firestoreServiceProvider).addIncome(Income(
          id: '',
          type: IncomeType.eid,
          amount: amount,
          date: _date,
          eidType: _eidType,
          createdBy: uid,
          createdAt: DateTime.now(),
        ));
    await logAudit(
      ref,
      action: 'create',
      entityType: 'income.eid',
      entityId: docId,
      summary: 'Added ${_eidType ?? "Eid"} collection ৳${amount.toInt()}',
    );
    playEntryAdded(ref);
    if (!mounted) return;
    _amount.clear();
    setState(() {
      _eidType = null;
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
                  DropdownButtonFormField<String>(
                    initialValue: _eidType,
                    decoration: InputDecoration(labelText: l.eidType),
                    items: AppConstants.eidTypes
                        .map((e) => DropdownMenuItem(
                            value: e, child: Text(_label(context, e))))
                        .toList(),
                    onChanged: (v) => setState(() => _eidType = v),
                    validator: (v) => v == null ? l.selectExpenseType : null,
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
          child: IncomeHistoryList(type: IncomeType.eid),
        ),
      ],
    );
  }
}

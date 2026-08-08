import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audit.dart';
import '../../../core/feedback.dart';
import '../../../core/formatters.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/income.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/firestore_provider.dart';
import '../../../providers/mosque_provider.dart';
import 'income_history_list.dart';

class GeneralDonationForm extends ConsumerStatefulWidget {
  const GeneralDonationForm({super.key});

  @override
  ConsumerState<GeneralDonationForm> createState() =>
      _GeneralDonationFormState();
}

class _GeneralDonationFormState extends ConsumerState<GeneralDonationForm> {
  final _formKey = GlobalKey<FormState>();
  final _donor = TextEditingController();
  final _amount = TextEditingController();
  final _quantity = TextEditingController();
  final _note = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _donor.dispose();
    _amount.dispose();
    _quantity.dispose();
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
    final qty = int.tryParse(_quantity.text.trim());
    if ((amount == null || amount <= 0) && (qty == null || qty <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.generalAmountOrQty)),
      );
      return;
    }
    setState(() => _saving = true);
    final uid = ref.read(authServiceProvider).currentUser?.uid ?? '';
    final mosqueId = ref.read(currentMosqueIdProvider) ?? '';
    final now = DateTime.now();
    final income = Income(
      id: '',
      mosqueId: mosqueId,
      type: IncomeType.general,
      amount: amount ?? 0,
      quantity: qty,
      donorName: _donor.text.trim().isEmpty ? null : _donor.text.trim(),
      date: _date,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      createdBy: uid,
      createdAt: now,
    );
    final docId =
        await ref.read(firestoreServiceProvider).addIncome(income);
    final donor = income.donorName ?? 'Anonymous';
    await logAudit(
      ref,
      action: 'create',
      entityType: 'income.general',
      entityId: docId,
      summary:
          'Added general donation ৳${income.amount.toInt()} from $donor',
    );
    playEntryAdded(ref);
    if (!mounted) return;
    _donor.clear();
    _amount.clear();
    _quantity.clear();
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
                  TextFormField(
                    controller: _donor,
                    decoration: InputDecoration(labelText: l.donorName),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l.amount),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _quantity,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l.quantity),
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
          child: IncomeHistoryList(type: IncomeType.general),
        ),
      ],
    );
  }
}

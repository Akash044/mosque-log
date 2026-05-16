import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/formatters.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/expense.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/firestore_provider.dart';
import 'calculator_dialog.dart';

class AddExpenseDialog extends ConsumerStatefulWidget {
  const AddExpenseDialog({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  ConsumerState<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends ConsumerState<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  String? _expenseType;
  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _amount.dispose();
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

  Future<void> _openCalculator() async {
    final v = await showDialog<double?>(
      context: context,
      builder: (_) => CalculatorDialog(initial: _amount.text),
    );
    if (v != null) {
      _amount.text = v == v.roundToDouble()
          ? v.toInt().toString()
          : v.toString();
      setState(() {});
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_expenseType == null) return;
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) return;
    setState(() => _saving = true);
    final uid = ref.read(authServiceProvider).currentUser?.uid ?? '';
    await ref.read(firestoreServiceProvider).addExpense(Expense(
          id: '',
          expenseType: _expenseType!,
          amount: amount,
          date: _date,
          createdBy: uid,
          createdAt: DateTime.now(),
        ));
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.addExpense),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _expenseType,
                decoration: InputDecoration(labelText: l.expenseType),
                items: AppConstants.defaultExpenseTypes
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _expenseType = v),
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
                readOnly: true,
                onTap: _openCalculator,
                decoration: InputDecoration(
                  labelText: l.amount,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calculate_outlined),
                    onPressed: _openCalculator,
                  ),
                ),
                validator: (v) {
                  if ((v ?? '').trim().isEmpty) return l.amountRequired;
                  final n = double.tryParse(v!.trim());
                  if (n == null || n <= 0) return l.amountInvalid;
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: Text(l.cancel),
        ),
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
    );
  }
}

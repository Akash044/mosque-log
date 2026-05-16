import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Simple infix calculator with +, -, *, /. Returns the computed value or
/// null when the user cancels.
class CalculatorDialog extends StatefulWidget {
  const CalculatorDialog({super.key, this.initial});

  final String? initial;

  @override
  State<CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<CalculatorDialog> {
  late String _expr;
  String _display = '0';

  @override
  void initState() {
    super.initState();
    _expr = widget.initial?.trim() ?? '';
    _display = _expr.isEmpty ? '0' : _expr;
  }

  void _input(String s) {
    setState(() {
      if (s == 'C') {
        _expr = '';
        _display = '0';
        return;
      }
      if (s == '=') {
        final v = _evaluate(_expr);
        if (v != null) {
          _display = _stripTrailingZero(v);
          _expr = _display;
        } else {
          _display = 'Err';
        }
        return;
      }
      if (s == '⌫') {
        if (_expr.isNotEmpty) {
          _expr = _expr.substring(0, _expr.length - 1);
        }
        _display = _expr.isEmpty ? '0' : _expr;
        return;
      }
      _expr += s;
      _display = _expr;
    });
  }

  String _stripTrailingZero(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toString();
  }

  double? _evaluate(String expr) {
    if (expr.trim().isEmpty) return null;
    try {
      final tokens = _tokenize(expr);
      final rpn = _toRpn(tokens);
      return _evalRpn(rpn);
    } catch (_) {
      return null;
    }
  }

  List<String> _tokenize(String expr) {
    final out = <String>[];
    final buf = StringBuffer();
    for (var i = 0; i < expr.length; i++) {
      final c = expr[i];
      if ('0123456789.'.contains(c)) {
        buf.write(c);
      } else if ('+-*/×÷'.contains(c)) {
        if (buf.isNotEmpty) {
          out.add(buf.toString());
          buf.clear();
        }
        final op = (c == '×')
            ? '*'
            : (c == '÷')
                ? '/'
                : c;
        out.add(op);
      } else if (c == ' ') {
        continue;
      } else {
        throw const FormatException();
      }
    }
    if (buf.isNotEmpty) out.add(buf.toString());
    return out;
  }

  int _prec(String op) => (op == '+' || op == '-') ? 1 : 2;

  List<String> _toRpn(List<String> tokens) {
    final out = <String>[];
    final ops = <String>[];
    for (final t in tokens) {
      if (double.tryParse(t) != null) {
        out.add(t);
      } else {
        while (ops.isNotEmpty && _prec(ops.last) >= _prec(t)) {
          out.add(ops.removeLast());
        }
        ops.add(t);
      }
    }
    while (ops.isNotEmpty) {
      out.add(ops.removeLast());
    }
    return out;
  }

  double _evalRpn(List<String> rpn) {
    final stack = <double>[];
    for (final t in rpn) {
      final n = double.tryParse(t);
      if (n != null) {
        stack.add(n);
      } else {
        if (stack.length < 2) throw const FormatException();
        final b = stack.removeLast();
        final a = stack.removeLast();
        switch (t) {
          case '+':
            stack.add(a + b);
            break;
          case '-':
            stack.add(a - b);
            break;
          case '*':
            stack.add(a * b);
            break;
          case '/':
            if (b == 0) throw const FormatException();
            stack.add(a / b);
            break;
        }
      }
    }
    if (stack.length != 1) throw const FormatException();
    return stack.single;
  }

  void _finish() {
    final v = _evaluate(_expr) ?? double.tryParse(_display);
    Navigator.of(context).pop(v);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final btnRows = <List<String>>[
      ['7', '8', '9', '÷'],
      ['4', '5', '6', '×'],
      ['1', '2', '3', '-'],
      ['0', '.', '⌫', '+'],
    ];

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.calculator,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerRight,
              child: Text(
                _display,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 12),
            for (final row in btnRows)
              Row(
                children: [
                  for (final s in row) ...[
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 18),
                          ),
                          onPressed: () => _input(s),
                          child: Text(s,
                              style: Theme.of(context).textTheme.titleLarge),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _input('C'),
                    child: Text(l.clear),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _input('='),
                    child: Text(l.equals),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: Text(l.cancel),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _finish,
                    child: Text(l.save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

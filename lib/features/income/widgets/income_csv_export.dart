import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/income.dart';
import '../../../models/person.dart';

/// Build a CSV string from a list of [Income] records, with person names
/// resolved from [personsById]. Columns:
/// `type, date, amount, donor_name, quantity, person, months, eid_type, note`.
String buildIncomeCsv(
  List<Income> rows,
  Map<String, Person> personsById,
) {
  final df = DateFormat('yyyy-MM-dd');
  final buf = StringBuffer();
  buf.writeln(
      'type,date,amount,donor_name,quantity,person,months,eid_type,note');
  for (final i in rows) {
    buf.writeln([
      i.type.key,
      df.format(i.date),
      i.amount,
      _csv(i.donorName),
      i.quantity ?? '',
      _csv(personsById[i.personId]?.name),
      _csv(i.months.join('|')),
      _csv(i.eidType),
      _csv(i.note),
    ].join(','));
  }
  return buf.toString();
}

String _csv(String? v) {
  if (v == null || v.isEmpty) return '';
  final needsQuotes = v.contains(',') || v.contains('"') || v.contains('\n');
  final escaped = v.replaceAll('"', '""');
  return needsQuotes ? '"$escaped"' : escaped;
}

/// Show the system share sheet with a CSV of [records]. If there's nothing
/// to export, shows a SnackBar instead.
Future<void> shareIncomeCsv(
  BuildContext context, {
  required List<Income> records,
  required Map<String, Person> personsById,
  required String filenameStem,
}) async {
  final l = AppLocalizations.of(context);
  if (records.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.exportEmpty)),
    );
    return;
  }
  final csv = buildIncomeCsv(records, personsById);
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  await Share.shareXFiles(
    [
      XFile.fromData(
        Uint8List.fromList(utf8.encode(csv)),
        name: '${filenameStem}_$today.csv',
        mimeType: 'text/csv',
      ),
    ],
    subject: 'Mosque Log — ${filenameStem.replaceAll('_', ' ')}',
  );
}

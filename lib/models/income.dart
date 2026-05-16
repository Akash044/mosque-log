import 'package:cloud_firestore/cloud_firestore.dart';

enum IncomeType { general, jumma, monthly, eid, ramadan }

extension IncomeTypeX on IncomeType {
  String get key => name;

  static IncomeType fromKey(String? value) {
    switch (value) {
      case 'general':
        return IncomeType.general;
      case 'jumma':
        return IncomeType.jumma;
      case 'monthly':
        return IncomeType.monthly;
      case 'eid':
        return IncomeType.eid;
      case 'ramadan':
        return IncomeType.ramadan;
      default:
        return IncomeType.general;
    }
  }
}

class Income {
  final String id;
  final IncomeType type;
  final double amount;
  final int? quantity;
  final String? donorName;
  final DateTime date;
  final String? personId;
  final List<String> months;
  final String? eidType;
  final String? note;
  final String createdBy;
  final DateTime createdAt;

  const Income({
    required this.id,
    required this.type,
    required this.amount,
    this.quantity,
    this.donorName,
    required this.date,
    this.personId,
    this.months = const [],
    this.eidType,
    this.note,
    required this.createdBy,
    required this.createdAt,
  });

  factory Income.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Income(
      id: doc.id,
      type: IncomeTypeX.fromKey(d['type'] as String?),
      amount: (d['amount'] as num?)?.toDouble() ?? 0,
      quantity: (d['quantity'] as num?)?.toInt(),
      donorName: d['donorName'] as String?,
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      personId: d['personId'] as String?,
      months: ((d['months'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
      eidType: d['eidType'] as String?,
      note: d['note'] as String?,
      createdBy: (d['createdBy'] as String?) ?? '',
      createdAt:
          (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.key,
      'amount': amount,
      'quantity': quantity,
      'donorName': donorName,
      'date': Timestamp.fromDate(date),
      'personId': personId,
      'months': months,
      'eidType': eidType,
      'note': note,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

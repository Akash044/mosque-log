import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String mosqueId;
  final String expenseType;
  final double amount;
  final DateTime date;
  final String? note;
  final String createdBy;
  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.mosqueId,
    required this.expenseType,
    required this.amount,
    required this.date,
    this.note,
    required this.createdBy,
    required this.createdAt,
  });

  factory Expense.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Expense(
      id: doc.id,
      mosqueId: (d['mosqueId'] as String?) ?? '',
      expenseType: (d['expenseType'] as String?) ?? '',
      amount: (d['amount'] as num?)?.toDouble() ?? 0,
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: d['note'] as String?,
      createdBy: (d['createdBy'] as String?) ?? '',
      createdAt:
          (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'mosqueId': mosqueId,
      'expenseType': expenseType,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'note': note,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

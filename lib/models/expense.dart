import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String expenseType;
  final double amount;
  final DateTime date;
  final String createdBy;
  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.expenseType,
    required this.amount,
    required this.date,
    required this.createdBy,
    required this.createdAt,
  });

  factory Expense.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Expense(
      id: doc.id,
      expenseType: (d['expenseType'] as String?) ?? '',
      amount: (d['amount'] as num?)?.toDouble() ?? 0,
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: (d['createdBy'] as String?) ?? '',
      createdAt:
          (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'expenseType': expenseType,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

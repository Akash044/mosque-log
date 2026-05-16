import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/person.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // ---------- Persons ----------

  CollectionReference<Map<String, dynamic>> get _personsRef =>
      _db.collection(AppConstants.personsCollection);

  Stream<List<Person>> personsStream({bool onlyActive = false}) {
    return _personsRef.orderBy('name').snapshots().map((snap) {
      final all = snap.docs.map(Person.fromFirestore);
      return (onlyActive ? all.where((p) => p.active) : all).toList();
    });
  }

  Future<String> addPerson({required String name, String? phone}) async {
    final doc = await _personsRef.add({
      'name': name.trim(),
      'phone': (phone == null || phone.trim().isEmpty) ? null : phone.trim(),
      'active': true,
      'createdAt': Timestamp.now(),
    });
    return doc.id;
  }

  Future<void> setPersonActive(String id, bool active) {
    return _personsRef.doc(id).update({'active': active});
  }

  Future<void> deletePerson(String id) => _personsRef.doc(id).delete();

  // ---------- Income ----------

  CollectionReference<Map<String, dynamic>> get _incomeRef =>
      _db.collection(AppConstants.incomeCollection);

  Stream<List<Income>> incomeStream() {
    return _incomeRef
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Income.fromFirestore).toList());
  }

  Stream<List<Income>> incomeStreamForRange(DateTime start, DateTime end) {
    return _incomeRef
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Income.fromFirestore).toList());
  }

  Stream<List<Income>> incomeStreamByType(IncomeType type) {
    return _incomeRef
        .where('type', isEqualTo: type.key)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Income.fromFirestore).toList());
  }

  /// Monthly collection docs that include [monthKey] (YYYY-MM) in their months array.
  /// Filtered client-side to avoid a composite index on (type, months).
  Stream<List<Income>> monthlyIncomeFor(String monthKey) {
    return _incomeRef
        .where('months', arrayContains: monthKey)
        .snapshots()
        .map((snap) => snap.docs
            .map(Income.fromFirestore)
            .where((i) => i.type == IncomeType.monthly)
            .toList());
  }

  Future<String> addIncome(Income income) async {
    final doc = await _incomeRef.add(income.toFirestore());
    return doc.id;
  }

  Future<void> deleteIncome(String id) => _incomeRef.doc(id).delete();

  // ---------- Expenses ----------

  CollectionReference<Map<String, dynamic>> get _expenseRef =>
      _db.collection(AppConstants.expensesCollection);

  Stream<List<Expense>> expenseStream() {
    return _expenseRef
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Expense.fromFirestore).toList());
  }

  Stream<List<Expense>> expenseStreamForRange(DateTime start, DateTime end) {
    return _expenseRef
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Expense.fromFirestore).toList());
  }

  Future<String> addExpense(Expense expense) async {
    final doc = await _expenseRef.add(expense.toFirestore());
    return doc.id;
  }

  Future<void> deleteExpense(String id) => _expenseRef.doc(id).delete();
}

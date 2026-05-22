import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants.dart';
import '../models/audit_log.dart';
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

  // All mutation methods below are intentionally "fire-and-forget": Firestore
  // commits to the local cache synchronously, but the Future returned by
  // set/update/delete only resolves once the server acknowledges the write.
  // When the device is offline that Future never completes, which would hang
  // any caller that awaits it. We unawait the network confirmation and rely
  // on Firestore's built-in offline queue to sync when connectivity returns.

  Future<String> addPerson({required String name, String? phone}) async {
    final doc = _personsRef.doc();
    unawaited(doc.set({
      'name': name.trim(),
      'phone': (phone == null || phone.trim().isEmpty) ? null : phone.trim(),
      'active': true,
      'createdAt': Timestamp.now(),
    }));
    return doc.id;
  }

  Future<void> setPersonActive(String id, bool active) async {
    unawaited(_personsRef.doc(id).update({'active': active}));
  }

  Future<void> deletePerson(String id) async {
    unawaited(_personsRef.doc(id).delete());
  }

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
    final doc = _incomeRef.doc();
    unawaited(doc.set(income.toFirestore()));
    return doc.id;
  }

  Future<void> deleteIncome(String id) async {
    unawaited(_incomeRef.doc(id).delete());
  }

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
    final doc = _expenseRef.doc();
    unawaited(doc.set(expense.toFirestore()));
    return doc.id;
  }

  Future<void> deleteExpense(String id) async {
    unawaited(_expenseRef.doc(id).delete());
  }

  // ---------- Audit log ----------

  CollectionReference<Map<String, dynamic>> get _auditRef =>
      _db.collection('audit_logs');

  Stream<List<AuditLog>> auditLogsStream({int limit = 200}) {
    return _auditRef
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(AuditLog.fromFirestore).toList());
  }

  Future<void> writeAuditLog({
    required String userId,
    required String userEmail,
    required String action,
    required String entityType,
    String? entityId,
    required String summary,
  }) async {
    unawaited(_auditRef.add({
      'userId': userId,
      'userEmail': userEmail,
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      'summary': summary,
      'timestamp': FieldValue.serverTimestamp(),
    }));
  }
}

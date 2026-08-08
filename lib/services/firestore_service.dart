import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants.dart';
import '../models/audit_log.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/mosque.dart';
import '../models/person.dart';
import '../models/user_profile.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // ---------- Mosques & user profiles ----------

  CollectionReference<Map<String, dynamic>> get _mosquesRef =>
      _db.collection(AppConstants.mosquesCollection);

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _db.collection(AppConstants.usersCollection);

  Stream<UserProfile?> userProfileStream(String uid) {
    return _usersRef
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserProfile.fromFirestore(doc) : null);
  }

  Stream<Mosque?> mosqueStream(String mosqueId) {
    return _mosquesRef
        .doc(mosqueId)
        .snapshots()
        .map((doc) => doc.exists ? Mosque.fromFirestore(doc) : null);
  }

  // ---------- Persons ----------

  CollectionReference<Map<String, dynamic>> get _personsRef =>
      _db.collection(AppConstants.personsCollection);

  Stream<List<Person>> personsStream(String mosqueId, {bool onlyActive = false}) {
    return _personsRef
        .where('mosqueId', isEqualTo: mosqueId)
        .orderBy('name')
        .snapshots()
        .map((snap) {
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

  Future<String> addPerson({
    required String mosqueId,
    required String name,
    String? phone,
  }) async {
    final doc = _personsRef.doc();
    unawaited(doc.set({
      'mosqueId': mosqueId,
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

  Stream<List<Income>> incomeStream(String mosqueId) {
    return _incomeRef
        .where('mosqueId', isEqualTo: mosqueId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Income.fromFirestore).toList());
  }

  Stream<List<Income>> incomeStreamForRange(
      String mosqueId, DateTime start, DateTime end) {
    return _incomeRef
        .where('mosqueId', isEqualTo: mosqueId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Income.fromFirestore).toList());
  }

  Stream<List<Income>> incomeStreamByType(String mosqueId, IncomeType type) {
    return _incomeRef
        .where('mosqueId', isEqualTo: mosqueId)
        .where('type', isEqualTo: type.key)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Income.fromFirestore).toList());
  }

  /// Monthly collection docs that include [monthKey] (YYYY-MM) in their months array.
  /// Filtered client-side to avoid a composite index on (type, months).
  Stream<List<Income>> monthlyIncomeFor(String mosqueId, String monthKey) {
    return _incomeRef
        .where('mosqueId', isEqualTo: mosqueId)
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

  Stream<List<Expense>> expenseStream(String mosqueId) {
    return _expenseRef
        .where('mosqueId', isEqualTo: mosqueId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Expense.fromFirestore).toList());
  }

  Stream<List<Expense>> expenseStreamForRange(
      String mosqueId, DateTime start, DateTime end) {
    return _expenseRef
        .where('mosqueId', isEqualTo: mosqueId)
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
      _db.collection(AppConstants.auditLogsCollection);

  Stream<List<AuditLog>> auditLogsStream(String mosqueId, {int limit = 200}) {
    return _auditRef
        .where('mosqueId', isEqualTo: mosqueId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(AuditLog.fromFirestore).toList());
  }

  Future<void> writeAuditLog({
    required String mosqueId,
    required String userId,
    required String userEmail,
    required String action,
    required String entityType,
    String? entityId,
    required String summary,
  }) async {
    unawaited(_auditRef.add({
      'mosqueId': mosqueId,
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

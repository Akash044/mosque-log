import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense.dart';
import 'auth_provider.dart';
import 'firestore_provider.dart';

final expenseProvider = StreamProvider<List<Expense>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  return ref.watch(firestoreServiceProvider).expenseStream();
});

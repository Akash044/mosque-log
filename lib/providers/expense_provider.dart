import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense.dart';
import 'firestore_provider.dart';
import 'mosque_provider.dart';

final expenseProvider = StreamProvider<List<Expense>>((ref) {
  final mosqueId = ref.watch(currentMosqueIdProvider);
  if (mosqueId == null) return const Stream.empty();
  return ref.watch(firestoreServiceProvider).expenseStream(mosqueId);
});

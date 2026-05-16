import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/income.dart';
import 'auth_provider.dart';
import 'firestore_provider.dart';

final incomeProvider = StreamProvider<List<Income>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  return ref.watch(firestoreServiceProvider).incomeStream();
});

final monthlyDueProvider =
    StreamProvider.family<List<Income>, String>((ref, monthKey) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  return ref.watch(firestoreServiceProvider).monthlyIncomeFor(monthKey);
});

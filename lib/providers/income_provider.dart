import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/income.dart';
import 'firestore_provider.dart';
import 'mosque_provider.dart';

final incomeProvider = StreamProvider<List<Income>>((ref) {
  final mosqueId = ref.watch(currentMosqueIdProvider);
  if (mosqueId == null) return const Stream.empty();
  return ref.watch(firestoreServiceProvider).incomeStream(mosqueId);
});

final monthlyDueProvider =
    StreamProvider.family<List<Income>, String>((ref, monthKey) {
  final mosqueId = ref.watch(currentMosqueIdProvider);
  if (mosqueId == null) return const Stream.empty();
  return ref.watch(firestoreServiceProvider).monthlyIncomeFor(mosqueId, monthKey);
});

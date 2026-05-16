import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/person.dart';
import 'auth_provider.dart';
import 'firestore_provider.dart';

final personsProvider = StreamProvider<List<Person>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  return ref.watch(firestoreServiceProvider).personsStream();
});

final activePersonsProvider = StreamProvider<List<Person>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  return ref
      .watch(firestoreServiceProvider)
      .personsStream(onlyActive: true);
});

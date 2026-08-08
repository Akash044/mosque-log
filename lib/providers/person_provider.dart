import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/person.dart';
import 'firestore_provider.dart';
import 'mosque_provider.dart';

final personsProvider = StreamProvider<List<Person>>((ref) {
  final mosqueId = ref.watch(currentMosqueIdProvider);
  if (mosqueId == null) return const Stream.empty();
  return ref.watch(firestoreServiceProvider).personsStream(mosqueId);
});

final activePersonsProvider = StreamProvider<List<Person>>((ref) {
  final mosqueId = ref.watch(currentMosqueIdProvider);
  if (mosqueId == null) return const Stream.empty();
  return ref
      .watch(firestoreServiceProvider)
      .personsStream(mosqueId, onlyActive: true);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/audit_log.dart';
import 'auth_provider.dart';
import 'firestore_provider.dart';

final auditLogsProvider = StreamProvider<List<AuditLog>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  return ref.watch(firestoreServiceProvider).auditLogsStream();
});

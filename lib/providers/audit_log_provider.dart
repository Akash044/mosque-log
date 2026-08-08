import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/audit_log.dart';
import 'firestore_provider.dart';
import 'mosque_provider.dart';

final auditLogsProvider = StreamProvider<List<AuditLog>>((ref) {
  final mosqueId = ref.watch(currentMosqueIdProvider);
  if (mosqueId == null) return const Stream.empty();
  return ref.watch(firestoreServiceProvider).auditLogsStream(mosqueId);
});

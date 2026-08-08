import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/firestore_provider.dart';
import '../providers/mosque_provider.dart';

/// Convenience wrapper that writes an audit log entry stamped with the
/// currently-signed-in user. Call after a successful mutation.
Future<void> logAudit(
  WidgetRef ref, {
  required String action,
  required String entityType,
  String? entityId,
  required String summary,
}) async {
  final user = ref.read(authServiceProvider).currentUser;
  final mosqueId = ref.read(currentMosqueIdProvider) ?? '';
  await ref.read(firestoreServiceProvider).writeAuditLog(
        mosqueId: mosqueId,
        userId: user?.uid ?? '',
        userEmail: user?.email ?? user?.displayName ?? 'unknown',
        action: action,
        entityType: entityType,
        entityId: entityId,
        summary: summary,
      );
}

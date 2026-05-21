import 'package:cloud_firestore/cloud_firestore.dart';

/// A single audit log entry. Immutable — once written, never edited or
/// deleted (enforced by Firestore rules).
class AuditLog {
  final String id;
  final String userId;
  final String userEmail;
  final String action; // 'create' | 'update' | 'delete'
  final String entityType; // 'income' | 'expense' | 'person'
  final String? entityId;
  final String summary;
  final DateTime timestamp;

  const AuditLog({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.action,
    required this.entityType,
    this.entityId,
    required this.summary,
    required this.timestamp,
  });

  factory AuditLog.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AuditLog(
      id: doc.id,
      userId: (d['userId'] as String?) ?? '',
      userEmail: (d['userEmail'] as String?) ?? '',
      action: (d['action'] as String?) ?? '',
      entityType: (d['entityType'] as String?) ?? '',
      entityId: d['entityId'] as String?,
      summary: (d['summary'] as String?) ?? '',
      timestamp:
          (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

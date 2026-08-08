import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String name;
  final String mosqueId;
  final String role; // only 'admin' in v1
  final DateTime createdAt;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.name,
    required this.mosqueId,
    this.role = 'admin',
    required this.createdAt,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return UserProfile(
      uid: doc.id,
      email: (d['email'] as String?) ?? '',
      name: (d['name'] as String?) ?? '',
      mosqueId: (d['mosqueId'] as String?) ?? '',
      role: (d['role'] as String?) ?? 'admin',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'mosqueId': mosqueId,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

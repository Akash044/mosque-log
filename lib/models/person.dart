import 'package:cloud_firestore/cloud_firestore.dart';

class Person {
  final String id;
  final String name;
  final String? phone;
  final bool active;
  final DateTime createdAt;

  const Person({
    required this.id,
    required this.name,
    this.phone,
    this.active = true,
    required this.createdAt,
  });

  factory Person.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Person(
      id: doc.id,
      name: (d['name'] as String?) ?? '',
      phone: d['phone'] as String?,
      active: (d['active'] as bool?) ?? true,
      createdAt:
          (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'active': active,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

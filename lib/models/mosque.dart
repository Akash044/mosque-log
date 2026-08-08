import 'package:cloud_firestore/cloud_firestore.dart';

class Mosque {
  final String id;
  final String name;
  final String address;
  final String? phone;
  final String createdBy;
  final DateTime createdAt;

  const Mosque({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    required this.createdBy,
    required this.createdAt,
  });

  factory Mosque.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Mosque(
      id: doc.id,
      name: (d['name'] as String?) ?? '',
      address: (d['address'] as String?) ?? '',
      phone: d['phone'] as String?,
      createdBy: (d['createdBy'] as String?) ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants.dart';

/// Creates a new mosque together with its (single, v1) admin account.
///
/// Firestore rules require an authenticated request to write, so a brand-new
/// signup must create the Firebase Auth account first and only then write
/// the `mosques`/`users` docs — the two-step "mosque info, then admin info"
/// wizard in the UI is purely a data-collection order, not a write order.
class RegistrationService {
  RegistrationService({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  /// New email/password admin account + new mosque, in one go.
  Future<void> registerMosqueWithNewAdmin({
    required String mosqueName,
    required String address,
    String? phone,
    required String adminName,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user!;
    await user.updateDisplayName(adminName.trim());
    await _createMosqueAndProfile(
      uid: user.uid,
      email: user.email ?? email.trim(),
      adminName: adminName,
      mosqueName: mosqueName,
      address: address,
      phone: phone,
    );
  }

  /// Finishes registration for a user who is already authenticated (e.g.
  /// signed in with Google) but has no mosque/profile doc yet.
  Future<void> finishRegistrationForCurrentUser({
    required String mosqueName,
    required String address,
    String? phone,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user to finish registration for.');
    }
    await _createMosqueAndProfile(
      uid: user.uid,
      email: user.email ?? '',
      adminName: user.displayName ?? '',
      mosqueName: mosqueName,
      address: address,
      phone: phone,
    );
  }

  Future<void> _createMosqueAndProfile({
    required String uid,
    required String email,
    required String adminName,
    required String mosqueName,
    required String address,
    String? phone,
  }) async {
    final now = Timestamp.now();
    final mosqueRef = _db.collection(AppConstants.mosquesCollection).doc();
    final userRef = _db.collection(AppConstants.usersCollection).doc(uid);
    final batch = _db.batch();
    batch.set(mosqueRef, {
      'name': mosqueName.trim(),
      'address': address.trim(),
      'phone': (phone == null || phone.trim().isEmpty) ? null : phone.trim(),
      'createdBy': uid,
      'createdAt': now,
    });
    batch.set(userRef, {
      'email': email,
      'name': adminName.trim(),
      'mosqueId': mosqueRef.id,
      'role': 'admin',
      'createdAt': now,
    });
    // Fire-and-forget, matching FirestoreService's convention: the local
    // cache is updated synchronously so the profile stream (and therefore
    // the router redirect) advances immediately, even offline.
    unawaited(batch.commit());
  }
}

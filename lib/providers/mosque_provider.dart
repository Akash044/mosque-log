import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mosque.dart';
import '../models/user_profile.dart';
import '../services/registration_service.dart';
import 'auth_provider.dart';
import 'firestore_provider.dart';

final registrationServiceProvider = Provider<RegistrationService>((ref) {
  return RegistrationService();
});

/// The signed-in user's mosque/admin profile doc (`users/{uid}`).
///
/// Stays in the loading state while logged out (nothing reads it there —
/// the router redirects on [authStateProvider] first). Once logged in it
/// resolves to `null` if no profile exists yet (brand-new Google sign-in, or
/// an interrupted registration) or to the [UserProfile] once found.
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  return ref.watch(firestoreServiceProvider).userProfileStream(user.uid);
});

/// Synchronous access to the current mosqueId, for the many call sites that
/// stamp it onto a new document (mirrors reading the uid via
/// `authServiceProvider.currentUser?.uid`).
final currentMosqueIdProvider = Provider<String?>((ref) {
  final mosqueId = ref.watch(userProfileProvider).valueOrNull?.mosqueId;
  return (mosqueId == null || mosqueId.isEmpty) ? null : mosqueId;
});

final currentMosqueProvider = StreamProvider<Mosque?>((ref) {
  final mosqueId = ref.watch(currentMosqueIdProvider);
  if (mosqueId == null) return const Stream.empty();
  return ref.watch(firestoreServiceProvider).mosqueStream(mosqueId);
});

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Explicit offline-first config: writes are queued in a local cache and
  // sync to the cloud whenever connectivity returns. With unlimited size the
  // app keeps working through long offline stretches.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Pre-load locale data so date formatters work in Bangla immediately.
  await initializeDateFormatting('bn');
  await initializeDateFormatting('en');

  runApp(const ProviderScope(child: MosqueApp()));
}

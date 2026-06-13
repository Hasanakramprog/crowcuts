import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ═══════════════════════════════════════════════════════════════════════
  // STARTUP: Initialize Firebase
  // ═══════════════════════════════════════════════════════════════════════
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // NOTE: We do NOT sign out on cold start — Firebase Auth persists sessions
  // automatically, so returning users go directly to their home screen.

  // Status bar style is managed dynamically per theme via AppBarTheme
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const ProviderScope(child: CrownCutsApp()));
}

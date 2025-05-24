import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:revision/app/app.dart';
import 'package:revision/bootstrap.dart';
import 'package:revision/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
      name: 'revision-development',
    );

    // Check if we should use Firebase emulator
    const useEmulator = bool.fromEnvironment('USE_AUTH_EMULATOR');
    if (useEmulator) {
      debugPrint('🔧 Using Firebase Auth Emulator');
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    }

    debugPrint('✅ Firebase initialized successfully for com.sly.revision.dev');
  } catch (e) {
    debugPrint('❌ Firebase initialization failed: $e');
  }

  await bootstrap(() => const App());
}

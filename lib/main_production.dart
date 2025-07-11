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
      name: 'revision-production',
    );

    debugPrint('✅ Firebase initialized successfully for com.sly.revision');
  } catch (e) {
    debugPrint('❌ Firebase initialization failed: $e');
  }

  await bootstrap(() => const App());
}

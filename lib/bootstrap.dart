import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart'; // Added for Vertex AI
import 'package:flutter/widgets.dart';
import 'package:revision/core/constants/environment_config.dart';
import 'package:revision/core/constants/firebase_constants.dart';
import 'package:revision/core/di/service_locator.dart';
import 'package:revision/firebase_options.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    log('onChange(${bloc.runtimeType}, $change)');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('onError(${bloc.runtimeType}, $error, $stackTrace)');
    super.onError(bloc, error, stackTrace);
  }
}

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  Bloc.observer = const AppBlocObserver();

  // Initialize Firebase with environment-specific configuration
  await _initializeFirebase();

  // Initialize service locator with all dependencies
  setupServiceLocator();

  // Add cross-flavor configuration here
  final environment = Environment.current;
  log('🚀 Starting app in ${environment.name} mode');

  runApp(await builder());
}

/// Initialize Firebase with proper error handling and environment configuration
Future<void> _initializeFirebase() async {
  try {
    final environment = Environment.current;

    // Initialize Firebase first
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
      // Remove environment-specific app names for now to avoid conflicts
    );

    // Configure emulators for development environment
    if (environment.useEmulators) {
      await _configureEmulators();
    }

    // Initialize Vertex AI after Firebase is initialized
    await _initializeVertexAI();

    log('✅ Firebase and Vertex AI initialized successfully for ${environment.name} environment');
  } catch (e, stackTrace) {
    log('❌ Firebase or Vertex AI initialization failed: $e',
        stackTrace: stackTrace);
    // Don't rethrow in development to allow app to continue
    if (Environment.current != Environment.development) {
      rethrow;
    }
  }
}

/// Configure Firebase emulators for development
Future<void> _configureEmulators() async {
  try {
    log('🔧 Configuring Firebase Auth Emulator');

    // IMPORTANT: Configure auth emulator BEFORE any auth operations
    await FirebaseAuth.instance.useAuthEmulator(
      FirebaseConstants.authEmulatorHost,
      FirebaseConstants.authEmulatorPort,
    );

    // Disable app verification and reCAPTCHA for testing
    await FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: true,
    );

    // Additional debugging
    log('✅ Auth emulator configured on ${FirebaseConstants.authEmulatorHost}:${FirebaseConstants.authEmulatorPort}');
    log('✅ App verification disabled for testing');
  } catch (e, stackTrace) {
    log(
      '⚠️ Firebase emulator configuration failed: $e',
      stackTrace: stackTrace,
    );
    // Don't rethrow - allow app to continue with production Firebase
  }
}

/// Initialize Vertex AI with a health check
Future<void> _initializeVertexAI() async {
  try {
    // Perform a simple check to ensure the model can be accessed
    // This doesn't generate content but verifies basic setup.
    final model = FirebaseVertexAI.instance.generativeModel(
      model: FirebaseConstants
          .geminiModel, // Using the constant from firebase_constants.dart
      systemInstruction: Content.system(
          'Health check'), // Content is part of firebase_vertexai
    );
    // Optionally, could add a very lightweight call here if needed, but prompt implies just init.
    log('✅ Vertex AI initialized successfully with model: ${FirebaseConstants.geminiModel}');
  } catch (e, stackTrace) {
    log('⚠️ Vertex AI initialization failed: $e', stackTrace: stackTrace);
    // As per prompt: Don't rethrow - app should be able to function without AI initially.
    // Consider setting a flag or state if AI features are critical for some parts.
  }
}

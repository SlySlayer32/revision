import 'dart:async';
import 'dart:developer';
import 'dart:io' show Platform;

import 'package:bloc/bloc.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:revision/core/config/env_config.dart';
import 'package:revision/core/config/environment_detector.dart';
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
  try {
    debugPrint('bootstrap: Starting app initialization...');

    // Load environment variables from .env file (skip if already loaded for hot reload)
    debugPrint('bootstrap: Loading environment variables...');
    try {
      await dotenv.load(fileName: '.env');
      debugPrint('bootstrap: Environment variables loaded');
    } catch (e) {
      debugPrint('bootstrap: Environment variables already loaded or not found: $e');
    }

    FlutterError.onError = (details) {
      log(details.exceptionAsString(), stackTrace: details.stack);
    };

    Bloc.observer = const AppBlocObserver();
    debugPrint('bootstrap: BlocObserver configured');

    // Initialize Firebase with environment-specific configuration
    debugPrint('bootstrap: Starting Firebase initialization...');
    await _initializeFirebase();
    debugPrint('bootstrap: Firebase initialization completed');

    // Initialize service locator with all dependencies
    debugPrint('bootstrap: Setting up service locator...');
    setupServiceLocator();
    debugPrint('bootstrap: Service locator setup completed');

    // Log comprehensive environment debug info
    final debugInfo = EnvConfig.getDebugInfo();
    log('🚀 Starting app in ${EnvironmentDetector.environmentString} mode');
    log('🔍 Environment Debug Info: $debugInfo');

    debugPrint('bootstrap: Building app widget...');
    runApp(await builder());
    debugPrint('bootstrap: App widget built and started');
  } catch (e, stackTrace) {
    debugPrint('❌ CRITICAL: Bootstrap failed: $e');
    debugPrint('❌ Stack trace: $stackTrace');
    rethrow;
  }
}

Future<void> _initializeFirebase() async {
  try {
    debugPrint('_initializeFirebase: Starting Firebase initialization...');
    debugPrint(
        '_initializeFirebase: Environment is ${EnvironmentDetector.environmentString}');

    // Log Firebase configuration debug info
    final firebaseDebugInfo = DefaultFirebaseOptions.getDebugInfo();
    log('🔥 Firebase Debug Info: $firebaseDebugInfo');

    // Check if Firebase is already initialized to prevent duplicate app error
    if (Firebase.apps.isEmpty) {
      debugPrint(
          'bootstrap: Firebase not initialized, calling initializeApp...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('bootstrap: Firebase.initializeApp() completed.');
    } else {
      debugPrint('bootstrap: Firebase already initialized.');
    }

    // Configure emulators for development environment
    if (EnvironmentDetector.isDevelopment) {
      debugPrint(
          '_initializeFirebase: Configuring emulators for development...');
      await _configureEmulators();
    } else {
      debugPrint(
          '_initializeFirebase: Skipping emulator configuration for ${EnvironmentDetector.environmentString}');
    }

    // Initialize Vertex AI after Firebase is initialized
    debugPrint('_initializeFirebase: Starting Firebase AI initialization...');
    await _initializeVertexAI();
    debugPrint('_initializeFirebase: Firebase AI initialization completed');

    log('✅ Firebase setup completed for ${EnvironmentDetector.environmentString} environment');
  } catch (e, stackTrace) {
    debugPrint('❌ Firebase initialization failed: $e');
    debugPrint('❌ Stack trace: $stackTrace');
    log(
      '❌ Firebase or Vertex AI initialization failed: $e',
      stackTrace: stackTrace,
    );
    // Don't rethrow in development to allow app to continue
    if (!EnvironmentDetector.isDevelopment) {
      rethrow;
    } else {
      debugPrint('⚠️ Continuing in development mode despite Firebase error');
    }
  }
}

/// Configure Firebase emulators for development
Future<void> _configureEmulators() async {
  try {
    debugPrint('_configureEmulators: Starting emulator configuration...');

    // CRITICAL: Call connectAuthEmulator RIGHT AFTER initializing Auth
    // Use platform-specific host for better compatibility
    final auth = FirebaseAuth.instance;
    final host = _getPlatformSpecificEmulatorHost();
    debugPrint('_configureEmulators: Using host $host for Auth emulator');

    await auth.useAuthEmulator(host, FirebaseConstants.authEmulatorPort);
    debugPrint('_configureEmulators: Auth emulator connected');

    // Disable app verification and reCAPTCHA for testing
    await auth.setSettings(appVerificationDisabledForTesting: true);
    debugPrint('_configureEmulators: App verification disabled');

    // Additional debugging
    log(
      '✅ Auth emulator configured on $host:${FirebaseConstants.authEmulatorPort}',
    );
    log('✅ App verification disabled for testing');
  } catch (e, stackTrace) {
    debugPrint('⚠️ Firebase emulator configuration failed: $e');
    debugPrint('⚠️ Stack trace: $stackTrace');
    log(
      '⚠️ Firebase emulator configuration failed: $e',
      stackTrace: stackTrace,
    );
    // Don't rethrow - allow app to continue with production Firebase
  }
}

/// Returns the correct emulator host for the current platform
String _getPlatformSpecificEmulatorHost() {
  try {
    if (Platform.isAndroid) {
      log('Host platform is Android, using 10.0.2.2 for emulators.');
      return '10.0.2.2';
    } else if (Platform.isIOS) {
      log('Host platform is iOS, using localhost for emulators.');
      return 'localhost';
    }
  } catch (e) {
    log(
      'Platform detection failed in _getPlatformSpecificEmulatorHost: $e. Defaulting to localhost.',
    );
  }
  log('Defaulting to localhost for emulators (e.g., web, desktop, or fallback).');
  return 'localhost';
}

/// Initialize Firebase AI with GoogleAI (Gemini Developer API)
Future<void> _initializeVertexAI() async {
  try {
    debugPrint(
        '_initializeVertexAI: Starting Firebase AI (GoogleAI) initialization...');

    // IMPORTANT: Ensure API key is available before initializing Firebase AI
    // Firebase AI Logic uses API keys managed by Firebase Console
    if (!EnvConfig.isFirebaseAIConfigured) {
      log('❌ CRITICAL: GEMINI_API_KEY is not set. AI features will fail.');
      log('👉 RUN WITH: flutter run --dart-define=GEMINI_API_KEY=YOUR_KEY_HERE');
    }

    // Initialize the Gemini Developer API backend service
    // Create a `GenerativeModel` instance with a model that supports your use case
    final model = FirebaseAI.googleAI().generativeModel(
      model: FirebaseConstants.geminiModel,
    );

    // Register the model with the service locator if not already registered
    if (!getIt.isRegistered<GenerativeModel>()) {
      getIt.registerSingleton<GenerativeModel>(model);
    }

    log('✅ Firebase AI (GoogleAI) initialized successfully with model: ${model.model}');
  } catch (e, stackTrace) {
    log(
      '❌ Vertex AI initialization failed: $e',
      stackTrace: stackTrace,
    );
    // Don't rethrow in development to allow app to continue
    if (!EnvironmentDetector.isDevelopment) {
      rethrow;
    } else {
      debugPrint('⚠️ Continuing in development mode despite Vertex AI error');
    }
  }
}

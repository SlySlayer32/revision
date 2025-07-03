import 'dart:async';
import 'dart:developer';
import 'dart:io' show Platform;

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:revision/core/config/env_config.dart';
import 'package:revision/core/config/environment_detector.dart';
import 'package:revision/core/constants/firebase_constants.dart';
import 'package:revision/core/di/service_locator.dart';
import 'package:revision/core/services/firebase_ai_remote_config_service.dart';
import 'package:revision/core/services/gemini_ai_service.dart';
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
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('bootstrap: Starting app initialization...');

    // Load environment variables from .env file (skip if already loaded for hot reload)
    debugPrint('bootstrap: Loading environment variables...');
    try {
      await dotenv.load(fileName: '.env');
      debugPrint('bootstrap: Environment variables loaded successfully');

      // Verify critical environment variables are loaded
      try {
        final geminiApiKey = dotenv.env['GEMINI_API_KEY'];
        debugPrint(
            'bootstrap: GEMINI_API_KEY ${geminiApiKey != null && geminiApiKey.isNotEmpty ? "found" : "missing"}');

        if (geminiApiKey == null || geminiApiKey.isEmpty) {
          debugPrint('⚠️ GEMINI_API_KEY not found in environment variables');
          debugPrint('⚠️ Available env vars: ${dotenv.env.keys.toList()}');
        }
      } catch (e) {
        debugPrint('⚠️ Error accessing environment variables: $e');
      }
    } catch (e) {
      debugPrint(
          'bootstrap: Environment variables load failed or already loaded: $e');
      debugPrint('⚠️ Will attempt to use dart-define fallbacks');
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

    // Initialize service locator with all dependencies FIRST
    debugPrint('_initializeFirebase: Setting up service locator...');
    setupServiceLocator();
    debugPrint('_initializeFirebase: Service locator setup completed');

    // Configure emulators for development environment
    if (EnvironmentDetector.isDevelopment) {
      debugPrint(
          '_initializeFirebase: Configuring emulators for development...');
      await _configureEmulators();
    } else {
      debugPrint(
          '_initializeFirebase: Skipping emulator configuration for ${EnvironmentDetector.environmentString}');
    }

    // Initialize Firebase Remote Config after service locator is ready
    debugPrint('_initializeFirebase: Initializing Firebase Remote Config...');
    try {
      final remoteConfigService = getIt<FirebaseAIRemoteConfigService>();
      await remoteConfigService.initialize();
      debugPrint(
          '_initializeFirebase: Firebase Remote Config initialization completed');
    } catch (e) {
      debugPrint('⚠️ Firebase Remote Config initialization failed: $e');
    }

    // Initialize Firebase AI Logic after Firebase is initialized
    debugPrint(
        '_initializeFirebase: Starting Firebase AI Logic initialization...');
    await _initializeFirebaseAI();
    debugPrint(
        '_initializeFirebase: Firebase AI Logic initialization completed');

    // Initialize GeminiAI Service after Firebase AI is ready
    debugPrint(
        '_initializeFirebase: Starting GeminiAI Service initialization...');
    try {
      // Verify the service is registered before trying to get it
      if (!getIt.isRegistered<GeminiAIService>()) {
        debugPrint('❌ GeminiAIService is not registered in service locator');
        throw StateError('GeminiAIService not registered');
      }

      debugPrint('✅ GeminiAIService is registered, getting instance...');
      final geminiService = getIt<GeminiAIService>();
      debugPrint(
          '✅ GeminiAIService instance obtained, waiting for initialization...');

      // Add a small delay to ensure all Firebase services are ready
      await Future.delayed(const Duration(milliseconds: 500));

      await geminiService.waitForInitialization();
      debugPrint(
          '_initializeFirebase: GeminiAI Service initialization completed');
    } catch (e, stackTrace) {
      debugPrint('⚠️ GeminiAI Service initialization failed: $e');
      debugPrint('⚠️ Stack trace: $stackTrace');
      // Log the error but don't rethrow in development to allow app to continue
      if (!EnvironmentDetector.isDevelopment) {
        rethrow;
      } else {
        debugPrint(
            '⚠️ Continuing in development mode despite GeminiAI Service error');
      }
    }

    // Firebase AI is ready for use by services

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

/// Initialize Firebase AI Logic with Google AI (Gemini API)
Future<void> _initializeFirebaseAI() async {
  try {
    debugPrint(
        '_initializeFirebaseAI: Starting Firebase AI Logic (Google AI) initialization...');

    // Firebase AI Logic uses API keys managed by Firebase Console
    // No explicit API key initialization needed - handled by Firebase Console
    debugPrint(
        '_initializeFirebaseAI: Using Firebase Console managed API keys');

    // Firebase AI Logic is automatically available when Firebase is initialized
    // Models are created on-demand by GeminiAIService
    debugPrint(
        '_initializeFirebaseAI: Firebase AI Logic models will be initialized by GeminiAIService');

    log('✅ Firebase AI Logic (Google AI) initialization completed successfully');
  } catch (e, stackTrace) {
    log(
      '❌ Firebase AI Logic initialization failed: $e',
      stackTrace: stackTrace,
    );
    // Don't rethrow in development to allow app to continue
    if (!EnvironmentDetector.isDevelopment) {
      rethrow;
    } else {
      debugPrint(
          '⚠️ Continuing in development mode despite Firebase AI Logic error');
    }
  }
}

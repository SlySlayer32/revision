import 'dart:async';
import 'dart:developer';
import 'dart:io' show Platform;

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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
  try {
    debugPrint('bootstrap: Starting app initialization...');
    
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

    // Add cross-flavor configuration here
    final environment = Environment.current;
    log('🚀 Starting app in ${environment.name} mode');

    debugPrint('bootstrap: Building app widget...');
    runApp(await builder());
    debugPrint('bootstrap: App widget built and started');
  } catch (e, stackTrace) {
    debugPrint('❌ CRITICAL: Bootstrap failed: $e');
    debugPrint('❌ Stack trace: $stackTrace');
    rethrow;
  }
}

/// Initialize Firebase with proper error handling and environment configuration
Future<void> _initializeFirebase() async {
  try {
    final environment = Environment.current;

    // Check if Firebase is already initialized to prevent duplicate app error
    try {
      Firebase.app(); // Try to get existing default app
      log('✅ Firebase already initialized, reusing existing app');
    } catch (e) {
      // App doesn't exist, initialize it
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      log('✅ Firebase initialized successfully');
    }

    // Configure emulators for development environment
    if (environment.useEmulators) {
      await _configureEmulators();
    }

    // Initialize Vertex AI after Firebase is initialized
    // TODO: Implement AI initialization when needed
    // await _initializeVertexAI();

    log('✅ Firebase setup completed for ${environment.name} environment');
  } catch (e, stackTrace) {
    log(
      '❌ Firebase or Vertex AI initialization failed: $e',
      stackTrace: stackTrace,
    );
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

    // CRITICAL: Call connectAuthEmulator RIGHT AFTER initializing Auth
    // Use platform-specific host for better compatibility
    final auth = FirebaseAuth.instance;
    final host = _getPlatformSpecificEmulatorHost();
    await auth.useAuthEmulator(host, FirebaseConstants.authEmulatorPort);

    // Disable app verification and reCAPTCHA for testing
    await auth.setSettings(appVerificationDisabledForTesting: true);

    // Additional debugging
    log(
      '✅ Auth emulator configured on $host:${FirebaseConstants.authEmulatorPort}',
    );
    log('✅ App verification disabled for testing');
  } catch (e, stackTrace) {
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
  log(
    'Defaulting to localhost for emulators (e.g., web, desktop, or fallback).',
  );
  return 'localhost';
}

/// Initialize Vertex AI with a health check
/// TODO: Implement when AI features are needed
/*
Future<void> _initializeVertexAI() async {
  try {
    // Perform a simple check to ensure the model can be accessed
    // This doesn't generate content but verifies basic setup.
    final firebaseAI = FirebaseAI.vertexAI(location: FirebaseConstants.vertexAiLocation);
    firebaseAI.generativeModel(
      model: FirebaseConstants.geminiModel,
      systemInstruction: Content.system('Health check'),
    );
    log('✅ Vertex AI initialized successfully with model: ${FirebaseConstants.geminiModel}');
  } catch (e, stackTrace) {
    log('⚠️ Vertex AI initialization failed: $e', stackTrace: stackTrace);
    // Don't rethrow - app should be able to function without AI initially.
  }
}
*/

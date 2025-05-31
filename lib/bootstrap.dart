import 'dart:async';
import 'dart:developer';

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

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
      name: environment.firebaseAppName,
    );

    // Configure emulators for development environment
    if (environment.useEmulators) {
      await _configureEmulators();
    }

    log('✅ Firebase initialized successfully for '
        '${environment.firebaseAppName}');
  } catch (e, stackTrace) {
    log('❌ Firebase initialization failed: $e', stackTrace: stackTrace);
    rethrow;
  }
}

/// Configure Firebase emulators for development
Future<void> _configureEmulators() async {
  if (FirebaseConstants.useAuthEmulator) {
    log('🔧 Configuring Firebase Auth Emulator');

    await FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: true,
    );

    await FirebaseAuth.instance.useAuthEmulator(
      FirebaseConstants.authEmulatorHost,
      FirebaseConstants.authEmulatorPort,
    );
  }
}

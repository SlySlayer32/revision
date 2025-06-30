// Copyright (c) 2022, Very Good Ventures
// https://verygood.ventures
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:revision/app/app.dart';
import 'package:revision/bootstrap.dart';
import 'package:revision/core/di/service_locator.dart';
import 'package:revision/core/services/error_handler_service.dart';
import 'package:revision/core/services/logging_service.dart';
import 'package:revision/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Register global error handlers first
  ErrorHandlerService.registerGlobalHandlers();
  
  // Initialize logging
  LoggingService.instance.info('Application starting up');
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Setup Firebase services for production
  await _setupFirebaseServices();
  
  // Initialize service locator
  setupServiceLocator();
  
  LoggingService.instance.info('All services initialized successfully');

  bootstrap(() => const App());
}

Future<void> _setupFirebaseServices() async {
  // Setup Crashlytics
  if (!kDebugMode) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }
  
  // Setup Analytics
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(!kDebugMode);
  
  // Setup Remote Config
  final remoteConfig = FirebaseRemoteConfig.instance;
  await remoteConfig.setConfigSettings(RemoteConfigSettings(
    fetchTimeout: const Duration(minutes: 1),
    minimumFetchInterval: const Duration(hours: 1),
  ));
  
  // Set default values for remote config
  await remoteConfig.setDefaults(const {
    'ai_processing_enabled': true,
    'max_image_size_mb': 10,
    'supported_image_formats': 'jpg,png,gif,webp',
  });
  
  try {
    await remoteConfig.fetchAndActivate();
  } catch (e) {
    // Log error but don't prevent app startup
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(
        'Failed to fetch remote config',
        StackTrace.current,
      );
    }
  }
  
  // Use Auth Emulator only in debug mode
  if (kDebugMode) {
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  }
}

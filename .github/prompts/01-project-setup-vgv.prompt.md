# Phase 1: VGV Project Foundation Setup

## Context & Requirements
Initialize a production-ready Flutter project using Very Good Ventures (VGV) boilerplate for an AI photo editor app. This foundation must support scalable architecture, comprehensive testing, and enterprise-grade error handling.

**Critical Technical Requirements:**
- Flutter SDK: Latest stable (3.24+)
- Dart SDK: 3.5+
- Target platforms: iOS 12+, Android API 21+
- Architecture: Clean Architecture with VGV patterns
- State management: flutter_bloc with Cubit pattern
- Dependency injection: get_it service locator
- Testing: 95%+ code coverage requirement

## Exact Implementation Specifications

### 1. Project Initialization
```bash
# Exact commands to run
flutter create ai_photo_editor --org=com.example.aiphotoeditor
cd ai_photo_editor
flutter pub add very_good_analysis flutter_bloc equatable get_it
flutter pub add firebase_core firebase_auth firebase_vertexai
flutter pub add image_picker path_provider share_plus
flutter pub add --dev mocktail bloc_test build_runner
```

### 2. Required Dependencies (Exact Versions)
```yaml
# Add to pubspec.yaml with specific version constraints
dependencies:
  flutter:
    sdk: flutter
  
  # Core VGV Stack
  flutter_bloc: ^8.1.6
  equatable: ^2.0.5
  get_it: ^7.7.0
  
  # Firebase & AI
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  firebase_vertexai: ^0.2.2+4
  
  # Image Processing
  image_picker: ^1.1.2
  image: ^4.2.0
  path_provider: ^2.1.4
  
  # UI & Utilities
  share_plus: ^10.0.2
  uuid: ^4.5.1
  intl: ^0.19.0
  
  # Networking & Storage
  dio: ^5.7.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  
  # Testing & Code Quality
  very_good_analysis: ^6.0.0
  mocktail: ^1.0.4
  bloc_test: ^9.1.7
  build_runner: ^2.4.13
  hive_generator: ^2.0.1
  
  # Coverage & Documentation
  test_coverage: ^0.2.0
  dartdoc: ^8.1.0
```

### 3. VGV Directory Structure (Exact Layout)
```
lib/
├── bootstrap.dart                    # App initialization
├── main_development.dart            # Development entry point
├── main_staging.dart               # Staging entry point  
├── main_production.dart            # Production entry point
├── app/                            # App-level configuration
│   ├── app.dart                   # Main App widget
│   └── view/
│       └── app_view.dart          # App view implementation
├── core/                          # Shared core functionality
│   ├── constants/
│   │   ├── app_constants.dart
│   │   ├── api_constants.dart
│   │   └── storage_constants.dart
│   ├── di/
│   │   ├── injection_container.dart
│   │   └── service_locator.dart
│   ├── error/
│   │   ├── exceptions.dart
│   │   ├── failures.dart
│   │   └── error_handler.dart
│   ├── network/
│   │   ├── network_info.dart
│   │   └── api_client.dart
│   ├── services/
│   │   ├── storage_service.dart
│   │   ├── analytics_service.dart
│   │   └── crash_reporting_service.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   └── app_text_styles.dart
│   ├── utils/
│   │   ├── validators.dart
│   │   ├── formatters.dart
│   │   └── extensions.dart
│   └── widgets/
│       ├── loading_indicator.dart
│       ├── error_widget.dart
│       └── custom_button.dart
└── features/                      # Feature-first organization
    ├── authentication/
    │   ├── domain/
    │   ├── data/
    │   └── presentation/
    ├── image_selection/
    │   ├── domain/
    │   ├── data/
    │   └── presentation/
    ├── image_editor/
    │   ├── domain/
    │   ├── data/
    │   └── presentation/
    ├── ai_processing/
    │   ├── domain/
    │   ├── data/
    │   └── presentation/
    └── results/
        ├── domain/
        ├── data/
        └── presentation/
```

### 4. Bootstrap Configuration (Critical for Scalability)
```dart
// lib/bootstrap.dart - Exact implementation
import 'dart:async';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'core/di/injection_container.dart' as di;
import 'core/services/analytics_service.dart';
import 'core/services/crash_reporting_service.dart';
import 'firebase_options.dart';

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
    // Report to crash analytics
    di.sl<CrashReportingService>().recordError(error, stackTrace);
    super.onError(bloc, error, stackTrace);
  }
}

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
    di.sl<CrashReportingService>().recordFlutterError(details);
  };

  Bloc.observer = const AppBlocObserver();

  // Initialize core services
  await _initializeCoreServices();
  
  // Initialize dependency injection
  await di.init();

  runApp(await builder());
}

Future<void> _initializeCoreServices() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize local storage
    await Hive.initFlutter();
    
    // Initialize analytics
    await di.sl<AnalyticsService>().initialize();
    
    log('Core services initialized successfully');
  } catch (e, stackTrace) {
    log('Failed to initialize core services: $e', stackTrace: stackTrace);
    rethrow;
  }
}
```

### 5. Environment-Specific Entry Points
```dart
// lib/main_development.dart
import 'bootstrap.dart';
import 'app/app.dart';
import 'core/constants/app_constants.dart';

void main() {
  AppConstants.setEnvironment(Environment.development);
  bootstrap(() => const App());
}

// lib/main_staging.dart  
import 'bootstrap.dart';
import 'app/app.dart';
import 'core/constants/app_constants.dart';

void main() {
  AppConstants.setEnvironment(Environment.staging);
  bootstrap(() => const App());
}

// lib/main_production.dart
import 'bootstrap.dart';
import 'app/app.dart';
import 'core/constants/app_constants.dart';

void main() {
  AppConstants.setEnvironment(Environment.production);
  bootstrap(() => const App());
}
```

### 6. Core Constants & Configuration
```dart
// lib/core/constants/app_constants.dart
enum Environment { development, staging, production }

class AppConstants {
  static Environment _environment = Environment.development;
  
  static void setEnvironment(Environment env) => _environment = env;
  
  static Environment get environment => _environment;
  
  static bool get isDevelopment => _environment == Environment.development;
  static bool get isStaging => _environment == Environment.staging;
  static bool get isProduction => _environment == Environment.production;
  
  // App Configuration
  static const String appName = 'AI Photo Editor';
  static const String packageName = 'com.example.aiphotoeditor';
  
  // Image Processing Limits
  static const int maxImageWidth = 4096;
  static const int maxImageHeight = 4096;
  static const int maxMemoryUsageMB = 200;
  static const int maxCacheSize = 3;
  
  // AI Processing Configuration
  static const Duration aiTimeoutDuration = Duration(seconds: 60);
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // Performance Thresholds
  static const int targetFPS = 60;
  static const Duration maxLoadTime = Duration(seconds: 2);
  static const double markerPrecision = 0.1; // pixels
}
```

### 7. Dependency Injection Setup
```dart
// lib/core/di/injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';

import '../services/analytics_service.dart';
import '../services/crash_reporting_service.dart';
import '../services/storage_service.dart';
import '../network/api_client.dart';
import '../network/network_info.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Core Services
  sl.registerLazySingleton<AnalyticsService>(() => AnalyticsServiceImpl());
  sl.registerLazySingleton<CrashReportingService>(() => CrashReportingServiceImpl());
  sl.registerLazySingleton<StorageService>(() => StorageServiceImpl());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
  sl.registerLazySingleton<ApiClient>(() => ApiClientImpl(sl()));
  
  // Firebase Services
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseVertexAI>(() => FirebaseVertexAI.instance);
  
  // Initialize all registered lazy singletons
  await _initializeServices();
}

Future<void> _initializeServices() async {
  final futures = <Future<void>>[
    sl<StorageService>().initialize(),
    sl<AnalyticsService>().initialize(),
    sl<CrashReportingService>().initialize(),
  ];
  
  await Future.wait(futures);
}
```

### 8. Error Handling Framework
```dart
// lib/core/error/exceptions.dart
abstract class AppException implements Exception {
  const AppException(this.message, [this.code]);
  
  final String message;
  final String? code;
  
  @override
  String toString() => 'AppException: $message${code != null ? ' ($code)' : ''}';
}

class NetworkException extends AppException {
  const NetworkException(super.message, [super.code]);
}

class StorageException extends AppException {
  const StorageException(super.message, [super.code]);
}

class AuthenticationException extends AppException {
  const AuthenticationException(super.message, [super.code]);
}

class ImageProcessingException extends AppException {
  const ImageProcessingException(super.message, [super.code]);
}

class AIProcessingException extends AppException {
  const AIProcessingException(super.message, [super.code]);
}

// lib/core/error/failures.dart
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure(this.message, [this.code]);
  
  final String message;
  final String? code;
  
  @override
  List<Object?> get props => [message, code];
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, [super.code]);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message, [super.code]);
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure(super.message, [super.code]);
}

class ImageProcessingFailure extends Failure {
  const ImageProcessingFailure(super.message, [super.code]);
}

class AIProcessingFailure extends Failure {
  const AIProcessingFailure(super.message, [super.code]);
}
```

### 9. Analysis Options (VGV Compliance)
```yaml
# analysis_options.yaml - Exact configuration
include: package:very_good_analysis/analysis_options.yaml

linter:
  rules:
    # Additional rules for enterprise quality
    avoid_print: true
    avoid_unnecessary_containers: true
    avoid_web_libraries_in_flutter: true
    cancel_subscriptions: true
    close_sinks: true
    comment_references: true
    literal_only_boolean_expressions: true
    no_logic_in_create_state: true
    prefer_const_constructors: true
    prefer_const_constructors_in_immutables: true
    prefer_const_declarations: true
    prefer_const_literals_to_create_immutables: true
    prefer_relative_imports: true
    sort_constructors_first: true
    sort_unnamed_constructors_first: true
    unawaited_futures: true
    unsafe_html: true

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/*.mocks.dart"
  
  errors:
    # Treat warnings as errors for production quality
    missing_required_param: error
    missing_return: error
    dead_code: warning
    
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
```

### 10. Testing Setup (Foundation)
```dart
// test/helpers/pump_app.dart - VGV testing helper
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_photo_editor/app/app.dart';

extension PumpApp on WidgetTester {
  Future<void> pumpApp(Widget widget) {
    return pumpWidget(
      MaterialApp(
        home: widget,
      ),
    );
  }

  Future<void> pumpAndSettleApp(Widget widget) async {
    await pumpApp(widget);
    await pumpAndSettle();
  }
}

// test/helpers/helpers.dart
export 'pump_app.dart';
```

## Acceptance Criteria (Must All Pass)
1. ✅ Project structure follows VGV patterns exactly
2. ✅ All dependencies are pinned to specific versions
3. ✅ Bootstrap handles all initialization scenarios
4. ✅ Error handling covers all failure modes
5. ✅ Environment switching works correctly
6. ✅ DI container resolves all dependencies
7. ✅ Analysis passes with zero warnings/errors
8. ✅ Basic app builds and runs on iOS/Android
9. ✅ Memory usage tracking is implemented
10. ✅ Core services initialize properly

**Implementation Priority:** Foundation must be perfect before any features

**Quality Gate:** Zero linting errors, successful builds on both platforms

**Performance Target:** App startup < 3 seconds on mid-range devices

---

**Next Step:** After completion, proceed to Firebase & Vertex AI configuration (Phase 1, Step 2)

# VGV Test Structure Setup

## Context & Requirements
Set up a comprehensive test folder structure that perfectly mirrors the lib/ directory following Very Good Ventures (VGV) testing patterns. This ensures 100% VGV compliance with proper test organization, helper utilities, and testing infrastructure.

**Critical Testing Requirements:**
- Mirror lib/ structure exactly in test/ directory
- VGV-compliant test patterns and naming conventions
- Comprehensive test helpers and utilities
- Golden test support for UI components
- BLoC testing with proper mocking
- Integration test setup for complete workflows

## Current lib/ Structure Analysis
```
lib/
├── bootstrap.dart
├── firebase_options.dart
├── main_development.dart
├── main_production.dart
├── main_staging.dart
├── app/
│   ├── app.dart
│   └── view/
│       └── app.dart
├── core/
│   ├── constants/
│   ├── di/
│   ├── error/
│   ├── network/
│   ├── services/
│   ├── theme/
│   ├── utils/
│   └── widgets/
├── counter/
│   ├── counter.dart
│   ├── cubit/
│   └── view/
├── features/
│   ├── authentication/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── home/
│   │   └── view/
│   └── image_editor/
│       ├── data/
│       ├── domain/
│       └── presentation/
└── l10n/
    ├── l10n.dart
    └── arb/
```

## Exact Implementation Specifications

### 1. Complete Test Directory Structure
Create the following exact test/ structure to mirror lib/:

```
test/
├── bootstrap_test.dart
├── firebase_options_test.dart
├── app/
│   ├── app_test.dart
│   └── view/
│       └── app_test.dart
├── core/
│   ├── constants/
│   │   └── constants_test.dart
│   ├── di/
│   │   └── injection_container_test.dart
│   ├── error/
│   │   ├── exceptions_test.dart
│   │   ├── failures_test.dart
│   │   └── error_handler_test.dart
│   ├── network/
│   │   ├── network_info_test.dart
│   │   └── api_client_test.dart
│   ├── services/
│   │   ├── storage_service_test.dart
│   │   ├── analytics_service_test.dart
│   │   └── crash_reporting_service_test.dart
│   ├── theme/
│   │   ├── app_theme_test.dart
│   │   ├── app_colors_test.dart
│   │   └── app_text_styles_test.dart
│   ├── utils/
│   │   ├── validators_test.dart
│   │   ├── formatters_test.dart
│   │   └── extensions_test.dart
│   └── widgets/
│       ├── loading_indicator_test.dart
│       ├── error_widget_test.dart
│       └── custom_button_test.dart
├── counter/
│   ├── cubit/
│   │   └── counter_cubit_test.dart
│   └── view/
│       └── counter_view_test.dart
├── features/
│   ├── authentication/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── auth_local_datasource_test.dart
│   │   │   │   └── auth_remote_datasource_test.dart
│   │   │   ├── models/
│   │   │   │   └── user_model_test.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl_test.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user_test.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository_test.dart
│   │   │   └── usecases/
│   │   │       ├── sign_in_usecase_test.dart
│   │   │       ├── sign_up_usecase_test.dart
│   │   │       └── sign_out_usecase_test.dart
│   │   └── presentation/
│   │       ├── cubit/
│   │       │   └── authentication_cubit_test.dart
│   │       ├── view/
│   │       │   ├── login_view_test.dart
│   │       │   └── sign_up_view_test.dart
│   │       └── widgets/
│   │           ├── login_form_test.dart
│   │           └── auth_button_test.dart
│   ├── home/
│   │   └── view/
│   │       └── home_view_test.dart
│   └── image_editor/
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── image_local_datasource_test.dart
│       │   │   └── image_remote_datasource_test.dart
│       │   ├── models/
│       │   │   ├── processed_image_model_test.dart
│       │   │   └── image_marker_model_test.dart
│       │   └── repositories/
│       │       └── image_repository_impl_test.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── processed_image_test.dart
│       │   │   └── image_marker_test.dart
│       │   ├── repositories/
│       │   │   └── image_repository_test.dart
│       │   └── usecases/
│       │       ├── pick_image_usecase_test.dart
│       │       ├── add_marker_usecase_test.dart
│       │       └── process_image_usecase_test.dart
│       └── presentation/
│           ├── cubit/
│           │   ├── image_picker_cubit_test.dart
│           │   └── image_editor_cubit_test.dart
│           ├── view/
│           │   ├── image_picker_view_test.dart
│           │   └── image_editor_view_test.dart
│           └── widgets/
│               ├── image_preview_test.dart
│               ├── marker_overlay_test.dart
│               └── editor_toolbar_test.dart
├── helpers/
│   ├── helpers.dart
│   ├── pump_app.dart
│   ├── test_helpers.dart
│   ├── mock_dependencies.dart
│   ├── golden_test_helper.dart
│   └── bloc_test_helper.dart
├── mocks/
│   ├── mock_auth_repository.dart
│   ├── mock_image_repository.dart
│   ├── mock_firebase_auth.dart
│   ├── mock_vertex_ai.dart
│   └── mock_services.dart
└── integration_test/
    ├── app_test.dart
    ├── authentication_flow_test.dart
    ├── image_editing_flow_test.dart
    └── ai_processing_flow_test.dart
```

### 2. VGV Test Helper Infrastructure

#### Core Test Helpers
```dart
// test/helpers/test_helpers.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:get_it/get_it.dart';

import 'mock_dependencies.dart';

class TestHelpers {
  static final GetIt _getIt = GetIt.instance;

  /// Initialize test dependencies
  static Future<void> initializeTestDependencies() async {
    await _getIt.reset();
    
    // Register mock dependencies
    _getIt.registerLazySingleton<MockAuthRepository>(
      () => MockAuthRepository(),
    );
    _getIt.registerLazySingleton<MockImageRepository>(
      () => MockImageRepository(),
    );
    _getIt.registerLazySingleton<MockFirebaseAuth>(
      () => MockFirebaseAuth(),
    );
    _getIt.registerLazySingleton<MockVertexAI>(
      () => MockVertexAI(),
    );
  }

  /// Clean up after tests
  static Future<void> cleanupTestDependencies() async {
    await _getIt.reset();
  }

  /// Create a test widget with all providers
  static Widget createTestApp({
    required Widget child,
    ThemeData? theme,
  }) {
    return MaterialApp(
      theme: theme ?? ThemeData.light(),
      home: child,
    );
  }

  /// Setup common mocks for authentication tests
  static void setupAuthMocks() {
    final mockAuthRepo = _getIt<MockAuthRepository>();
    
    when(() => mockAuthRepo.getCurrentUser())
        .thenAnswer((_) async => null);
    
    when(() => mockAuthRepo.signIn(any(), any()))
        .thenAnswer((_) async => const Right(mockUser));
    
    when(() => mockAuthRepo.signUp(any(), any()))
        .thenAnswer((_) async => const Right(mockUser));
  }

  /// Setup common mocks for image editing tests
  static void setupImageMocks() {
    final mockImageRepo = _getIt<MockImageRepository>();
    
    when(() => mockImageRepo.pickFromGallery())
        .thenAnswer((_) async => const Right(mockImage));
    
    when(() => mockImageRepo.pickFromCamera())
        .thenAnswer((_) async => const Right(mockImage));
  }

  /// Verify no interactions with mocks
  static void verifyNoMoreInteractionsWithMocks() {
    verifyNoMoreInteractions(_getIt<MockAuthRepository>());
    verifyNoMoreInteractions(_getIt<MockImageRepository>());
    verifyNoMoreInteractions(_getIt<MockFirebaseAuth>());
    verifyNoMoreInteractions(_getIt<MockVertexAI>());
  }
}

// Test data constants
const mockUser = User(
  id: 'test-user-id',
  email: 'test@example.com',
  displayName: 'Test User',
);

const mockImage = SelectedImage(
  path: '/test/path/image.jpg',
  name: 'test_image.jpg',
  size: 1024 * 1024, // 1MB
);
```

#### BLoC Test Helper
```dart
// test/helpers/bloc_test_helper.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

class BlocTestHelper {
  /// Helper for testing BLoC states with custom matchers
  static void testBlocStates<B extends BlocBase<S>, S>({
    required String description,
    required B Function() build,
    required void Function(B bloc) act,
    required List<S> expect,
    Duration? wait,
    void Function()? setUp,
    void Function()? tearDown,
    bool skip = false,
  }) {
    blocTest<B, S>(
      description,
      build: build,
      setUp: setUp,
      act: act,
      expect: () => expect,
      wait: wait,
      tearDown: tearDown,
      skip: skip,
    );
  }

  /// Helper for testing BLoC events
  static void testBlocEvents<B extends Bloc<E, S>, E, S>({
    required String description,
    required B Function() build,
    required List<E> events,
    required List<S> expectedStates,
    void Function()? setUp,
    void Function()? tearDown,
  }) {
    blocTest<B, S>(
      description,
      build: build,
      setUp: setUp,
      act: (bloc) {
        for (final event in events) {
          bloc.add(event);
        }
      },
      expect: () => expectedStates,
      tearDown: tearDown,
    );
  }

  /// Helper for testing error states
  static void testBlocErrors<B extends BlocBase<S>, S>({
    required String description,
    required B Function() build,
    required void Function(B bloc) act,
    required List<S> expectedStates,
    required List<String> expectedErrors,
    void Function()? setUp,
    void Function()? tearDown,
  }) {
    blocTest<B, S>(
      description,
      build: build,
      setUp: setUp,
      act: act,
      expect: () => expectedStates,
      errors: () => expectedErrors,
      tearDown: tearDown,
    );
  }
}
```

#### Golden Test Helper
```dart
// test/helpers/golden_test_helper.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

class GoldenTestHelper {
  /// Initialize golden test environment
  static Future<void> initializeGoldenTests() async {
    await loadAppFonts();
  }

  /// Test widget with multiple device configurations
  static Future<void> testGoldenMultiDevice({
    required String description,
    required Widget widget,
    List<Device>? devices,
    ThemeData? theme,
  }) async {
    await testGoldens(
      description,
      (tester) async {
        await tester.pumpDeviceBuilder(
          DeviceBuilder()
            ..overrideDevicesForAllScenarios(
              devices: devices ?? [Device.phone, Device.tablet],
            )
            ..addScenario(
              widget: widget,
              name: 'default',
            ),
          wrapper: materialAppWrapper(theme: theme),
        );
      },
    );
  }

  /// Test widget states (loading, success, error)
  static Future<void> testGoldenStates({
    required String description,
    required List<WidgetState> states,
    Device? device,
    ThemeData? theme,
  }) async {
    await testGoldens(
      description,
      (tester) async {
        final builder = DeviceBuilder();
        
        if (device != null) {
          builder.overrideDevicesForAllScenarios(devices: [device]);
        }

        for (final state in states) {
          builder.addScenario(
            widget: state.widget,
            name: state.name,
          );
        }

        await tester.pumpDeviceBuilder(
          builder,
          wrapper: materialAppWrapper(theme: theme),
        );
      },
    );
  }

  /// Test dark and light themes
  static Future<void> testGoldenThemes({
    required String description,
    required Widget widget,
    Device? device,
  }) async {
    await testGoldens(
      description,
      (tester) async {
        await tester.pumpDeviceBuilder(
          DeviceBuilder()
            ..overrideDevicesForAllScenarios(
              devices: [device ?? Device.phone],
            )
            ..addScenario(
              widget: widget,
              name: 'light_theme',
            )
            ..addScenario(
              widget: widget,
              name: 'dark_theme',
            ),
          wrapper: (child) => materialAppWrapper(
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
          )(child),
        );
      },
    );
  }
}

class WidgetState {
  const WidgetState({
    required this.widget,
    required this.name,
  });

  final Widget widget;
  final String name;
}
```

#### Mock Dependencies
```dart
// test/mocks/mock_dependencies.dart
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';

// Repository Mocks
class MockAuthRepository extends Mock implements AuthRepository {}
class MockImageRepository extends Mock implements ImageRepository {}

// Firebase Mocks
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}
class MockVertexAI extends Mock implements FirebaseVertexAI {}
class MockGenerativeModel extends Mock implements GenerativeModel {}

// Service Mocks
class MockAnalyticsService extends Mock implements AnalyticsService {}
class MockStorageService extends Mock implements StorageService {}
class MockCrashReportingService extends Mock implements CrashReportingService {}
class MockNetworkInfo extends Mock implements NetworkInfo {}

// Use Case Mocks
class MockSignInUseCase extends Mock implements SignInUseCase {}
class MockSignUpUseCase extends Mock implements SignUpUseCase {}
class MockSignOutUseCase extends Mock implements SignOutUseCase {}
class MockPickImageUseCase extends Mock implements PickImageUseCase {}
class MockProcessImageUseCase extends Mock implements ProcessImageUseCase {}

// Data Source Mocks
class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}
class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}
class MockImageLocalDataSource extends Mock implements ImageLocalDataSource {}
class MockImageRemoteDataSource extends Mock implements ImageRemoteDataSource {}
```

### 3. Integration Test Setup

#### Main Integration Test
```dart
// integration_test/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:revision/main_development.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('complete app flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test app initialization
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // Test navigation
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      
      // Add more integration test steps
    });
  });
}
```

#### Authentication Flow Integration Test
```dart
// integration_test/authentication_flow_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:revision/main_development.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow', () {
    testWidgets('user can sign up and sign in', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test sign up flow
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();
      
      await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      // Verify home screen
      expect(find.text('Welcome'), findsOneWidget);
      
      // Test sign out
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();
      
      // Test sign in
      await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome'), findsOneWidget);
    });
  });
}
```

### 4. Test Configuration Files

#### Test Configuration
```yaml
# test/pubspec.yaml (if needed for test-specific dependencies)
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  
  # VGV Testing Stack
  mocktail: ^1.0.4
  bloc_test: ^9.1.7
  golden_toolkit: ^0.15.0
  
  # Additional Testing
  fake_async: ^1.3.1
  network_image_mock: ^2.1.1
  patrol: ^3.12.0
```

#### Test Runner Configuration
```json
// .vscode/launch.json - Test configurations
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Run All Tests",
      "request": "launch",
      "type": "dart",
      "program": "test/",
      "args": ["--coverage"]
    },
    {
      "name": "Run Integration Tests",
      "request": "launch",
      "type": "dart",
      "program": "integration_test/",
      "args": ["--device-id=chrome"]
    },
    {
      "name": "Update Golden Tests",
      "request": "launch",
      "type": "dart",
      "program": "test/",
      "args": ["--update-goldens"]
    }
  ]
}
```

## Acceptance Criteria (Must All Pass)
1. ✅ Test directory mirrors lib/ structure exactly
2. ✅ All VGV testing patterns are implemented correctly
3. ✅ Comprehensive test helpers reduce boilerplate
4. ✅ BLoC testing infrastructure supports all patterns
5. ✅ Golden test setup works for UI consistency
6. ✅ Mock dependencies cover all external services
7. ✅ Integration tests validate complete workflows
8. ✅ Test coverage tooling is properly configured
9. ✅ CI/CD integration supports automated testing
10. ✅ Documentation enables team testing practices

**Implementation Priority:** Core test infrastructure first, then feature-specific tests

**Quality Gate:** All test helpers work correctly, 95%+ structure completeness

**Coverage Target:** Framework supports achieving 95%+ test coverage

---

**Usage Instructions:**
1. Run this prompt to create the complete test folder structure
2. Each test file will have proper VGV patterns and imports
3. Use the helpers to write consistent, maintainable tests
4. Golden tests will ensure UI consistency across updates
5. Integration tests will validate complete user workflows

This structure provides a solid foundation for test-first development following VGV standards.

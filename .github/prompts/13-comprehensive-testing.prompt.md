# Phase 6: Comprehensive Testing Implementation

## Context & Requirements
Implement comprehensive testing strategy for the AI photo editor app including unit tests, integration tests, widget tests, and end-to-end tests. This testing framework must ensure 95%+ code coverage, performance validation, and robust error handling verification.

**Critical Technical Requirements:**
- Unit test coverage: 95%+ for all business logic
- Widget test coverage: 90%+ for all UI components
- Integration test coverage: 85%+ for feature workflows
- Golden test coverage for critical UI components
- Performance testing for AI processing and image handling
- Accessibility testing compliance
- Error scenario testing with comprehensive failure modes

## Exact Implementation Specifications

### 1. Testing Infrastructure Setup

#### Test Configuration
```yaml
# test/testing_config.yaml
test_configuration:
  coverage_threshold: 95
  performance_benchmarks:
    app_startup_ms: 3000
    image_load_ms: 1000
    ai_processing_timeout_ms: 60000
    gallery_scroll_fps: 60
  
  test_environments:
    - unit
    - widget
    - integration
    - golden
    - performance
    - accessibility

# pubspec.yaml additions for testing
dev_dependencies:
  # Testing Core
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  
  # Testing Utilities
  mocktail: ^1.0.4
  bloc_test: ^9.1.7
  golden_toolkit: ^0.15.0
  patrol: ^3.10.0
  
  # Performance Testing
  flutter_driver:
    sdk: flutter
  test_cov_console: ^0.2.2
  
  # Accessibility Testing
  flutter_accessibility_service: ^0.2.0
  semantics_tester: ^1.1.0
  
  # Test Data Generation
  faker: ^2.1.0
  mockito: ^5.4.4
  build_runner: ^2.4.13
```

#### Test Helpers & Utilities
```dart
// test/helpers/test_helpers.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:patrol/patrol.dart';

import 'package:ai_photo_editor/core/di/injection_container.dart' as di;
import 'pump_app.dart';

class TestHelpers {
  static Future<void> initializeTestDependencies() async {
    // Initialize dependency injection for tests
    await di.init();
    
    // Register fallback values for mocktail
    registerFallbackValue(const Duration(seconds: 1));
    registerFallbackValue(DateTime.now());
    registerFallbackValue(Uri.parse('https://example.com'));
  }

  static Future<void> cleanupTestDependencies() async {
    // Reset dependency injection
    await di.sl.reset();
  }

  static Widget makeTestableWidget({
    required Widget child,
    ThemeData? theme,
    Locale? locale,
  }) {
    return MaterialApp(
      theme: theme ?? ThemeData.light(),
      locale: locale ?? const Locale('en', 'US'),
      home: child,
    );
  }

  static Future<void> pumpAndSettleWithTimeout(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final stopwatch = Stopwatch()..start();
    
    while (stopwatch.elapsed < timeout) {
      await tester.pump();
      if (tester.binding.hasScheduledFrame == false) {
        return;
      }
    }
    
    throw TimeoutException(
      'pumpAndSettle timed out after ${timeout.inMilliseconds}ms',
      timeout,
    );
  }
}

// test/helpers/mock_factories.dart
import 'package:mocktail/mocktail.dart';
import 'package:faker/faker.dart';

import 'package:ai_photo_editor/features/image_editor/domain/entities/edited_image.dart';
import 'package:ai_photo_editor/features/results/domain/entities/processed_result.dart';

class MockDataFactory {
  static final _faker = Faker();

  static EditedImage createMockEditedImage({
    String? id,
    String? imagePath,
    ProcessingStatus? status,
  }) {
    return EditedImage(
      id: id ?? _faker.guid.guid(),
      imagePath: imagePath ?? '/test/path/image.jpg',
      originalSize: const Size(1920, 1080),
      currentSize: const Size(1920, 1080),
      markers: [],
      transformMatrix: Matrix4.identity(),
      status: status ?? ProcessingStatus.idle,
      createdAt: DateTime.now(),
    );
  }

  static ProcessedResult createMockProcessedResult({
    String? id,
    bool isFavorite = false,
    List<String>? tags,
  }) {
    return ProcessedResult(
      id: id ?? _faker.guid.guid(),
      originalImagePath: '/test/original.jpg',
      processedImagePath: '/test/processed.jpg',
      thumbnailPath: '/test/thumb.jpg',
      processingMetadata: ProcessingMetadata(
        processingTimeMs: _faker.randomGenerator.integer(10000, min: 1000),
        modelUsed: 'gemini-pro-vision',
        qualityScore: _faker.randomGenerator.decimal(scale: 0.9, min: 0.1),
      ),
      aiPrompt: _faker.lorem.sentence(),
      createdAt: DateTime.now(),
      tags: tags ?? _faker.lorem.words(3),
      isFavorite: isFavorite,
      shareCount: _faker.randomGenerator.integer(100),
    );
  }

  static List<ProcessedResult> createMockResultsList(int count) {
    return List.generate(count, (index) => createMockProcessedResult());
  }
}

// test/helpers/golden_test_helpers.dart
import 'package:flutter/material.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

class GoldenTestHelpers {
  static Future<void> testGoldenVariants(
    WidgetTester tester,
    String description,
    Widget widget, {
    List<Device>? devices,
    bool skip = false,
  }) async {
    final variants = devices ?? [
      Device.phone,
      Device.tablet,
      Device.iphone11,
    ];

    await testGoldens(
      description,
      (tester) async {
        await tester.pumpWidget(widget);
        await screenMatchesGolden(tester, description);
      },
      skip: skip,
    );
  }

  static Future<void> testResponsiveGoldens(
    WidgetTester tester,
    String description,
    Widget Function(Size size) widgetBuilder, {
    bool skip = false,
  }) async {
    const sizes = [
      Size(320, 568), // iPhone SE
      Size(375, 812), // iPhone X
      Size(768, 1024), // iPad
      Size(1920, 1080), // Desktop
    ];

    for (final size in sizes) {
      await testGoldens(
        '${description}_${size.width}x${size.height}',
        (tester) async {
          tester.binding.window.physicalSizeTestValue = size;
          tester.binding.window.devicePixelRatioTestValue = 1.0;
          
          await tester.pumpWidget(widgetBuilder(size));
          await screenMatchesGolden(
            tester,
            '${description}_${size.width}x${size.height}',
          );
        },
        skip: skip,
      );
    }
  }
}
```

### 2. Feature Testing Suites

#### Authentication Feature Tests
```dart
// test/features/authentication/auth_integration_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:patrol/patrol.dart';

import 'package:ai_photo_editor/main.dart' as app;
import '../helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Integration Tests', () {
    late PatrolTester $;

    setUp(() async {
      await TestHelpers.initializeTestDependencies();
    });

    tearDown(() async {
      await TestHelpers.cleanupTestDependencies();
    });

    patrolTest('complete authentication flow', ($) async {
      // Start app
      app.main();
      await $.pumpAndSettle();

      // Should show auth screen initially
      await $.waitUntilVisible(find.text('Sign In'));
      
      // Test email sign in
      await $.enterText(find.byKey('email_field'), 'test@example.com');
      await $.enterText(find.byKey('password_field'), 'password123');
      await $.tap(find.byKey('sign_in_button'));
      
      // Wait for navigation to home
      await $.waitUntilVisible(find.text('AI Photo Editor'));
      
      // Verify authenticated state
      expect(find.byKey('home_screen'), findsOneWidget);
      expect(find.byKey('user_menu'), findsOneWidget);
    });

    patrolTest('handles authentication errors', ($) async {
      app.main();
      await $.pumpAndSettle();

      // Enter invalid credentials
      await $.enterText(find.byKey('email_field'), 'invalid@email');
      await $.enterText(find.byKey('password_field'), 'wrong');
      await $.tap(find.byKey('sign_in_button'));
      
      // Should show error message
      await $.waitUntilVisible(find.text('Invalid email format'));
      
      // Error should be dismissible
      await $.tap(find.byKey('dismiss_error'));
      expect(find.text('Invalid email format'), findsNothing);
    });

    patrolTest('remembers authentication state', ($) async {
      // First login
      app.main();
      await $.pumpAndSettle();
      
      await $.enterText(find.byKey('email_field'), 'test@example.com');
      await $.enterText(find.byKey('password_field'), 'password123');
      await $.tap(find.byKey('sign_in_button'));
      
      await $.waitUntilVisible(find.text('AI Photo Editor'));
      
      // Restart app
      await $.restart();
      
      // Should remain authenticated
      await $.waitUntilVisible(find.text('AI Photo Editor'));
      expect(find.text('Sign In'), findsNothing);
    });
  });
}

// test/features/authentication/presentation/cubit/auth_cubit_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ai_photo_editor/features/authentication/domain/usecases/sign_in_with_email.dart';
import 'package:ai_photo_editor/features/authentication/presentation/cubit/auth_cubit.dart';

class MockSignInWithEmail extends Mock implements SignInWithEmail {}

void main() {
  late AuthCubit authCubit;
  late MockSignInWithEmail mockSignInWithEmail;

  setUp(() {
    mockSignInWithEmail = MockSignInWithEmail();
    authCubit = AuthCubit(
      signInWithEmail: mockSignInWithEmail,
    );
  });

  tearDown(() {
    authCubit.close();
  });

  group('AuthCubit', () {
    test('initial state is AuthInitial', () {
      expect(authCubit.state, equals(const AuthInitial()));
    });

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when sign in succeeds',
      build: () {
        when(() => mockSignInWithEmail(any()))
            .thenAnswer((_) async => const Right(null));
        return authCubit;
      },
      act: (cubit) => cubit.signInWithEmail(
        'test@example.com',
        'password123',
      ),
      expect: () => [
        const AuthLoading(),
        const AuthAuthenticated(),
      ],
      verify: (_) {
        verify(() => mockSignInWithEmail(any())).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthError] when sign in fails',
      build: () {
        when(() => mockSignInWithEmail(any()))
            .thenAnswer((_) async => const Left(
              AuthenticationFailure('Invalid credentials'),
            ));
        return authCubit;
      },
      act: (cubit) => cubit.signInWithEmail(
        'test@example.com',
        'wrongpassword',
      ),
      expect: () => [
        const AuthLoading(),
        const AuthError('Invalid credentials'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'handles multiple rapid sign in attempts correctly',
      build: () {
        when(() => mockSignInWithEmail(any()))
            .thenAnswer((_) async => const Right(null));
        return authCubit;
      },
      act: (cubit) async {
        cubit.signInWithEmail('test1@example.com', 'password');
        cubit.signInWithEmail('test2@example.com', 'password');
        cubit.signInWithEmail('test3@example.com', 'password');
      },
      expect: () => [
        const AuthLoading(),
        const AuthAuthenticated(),
      ],
      verify: (_) {
        // Should only process the first request
        verify(() => mockSignInWithEmail(any())).called(1);
      },
    );
  });
}
```

#### Image Processing Performance Tests
```dart
// test/performance/image_processing_performance_test.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:ai_photo_editor/features/image_editor/data/services/image_processing_service.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Image Processing Performance Tests', () {
    late ImageProcessingService service;
    late Uint8List testImageData;

    setUpAll(() async {
      await TestHelpers.initializeTestDependencies();
      service = ImageProcessingService();
      
      // Create test image data
      final image = img.Image(width: 1920, height: 1080);
      img.fill(image, color: img.ColorRgb8(255, 0, 0));
      testImageData = Uint8List.fromList(img.encodePng(image));
    });

    test('image loading performance benchmark', () async {
      final stopwatch = Stopwatch()..start();
      
      await service.loadImage(testImageData);
      
      stopwatch.stop();
      
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(1000), // Should load within 1 second
        reason: 'Image loading took ${stopwatch.elapsedMilliseconds}ms',
      );
    });

    test('thumbnail generation performance', () async {
      const thumbnailSize = Size(200, 200);
      final stopwatch = Stopwatch()..start();
      
      await service.generateThumbnail(testImageData, thumbnailSize);
      
      stopwatch.stop();
      
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(500), // Should generate within 500ms
        reason: 'Thumbnail generation took ${stopwatch.elapsedMilliseconds}ms',
      );
    });

    test('memory usage during image processing', () async {
      final initialMemory = ProcessInfo.currentRss;
      
      // Process multiple images
      for (int i = 0; i < 10; i++) {
        await service.loadImage(testImageData);
        await service.generateThumbnail(testImageData, const Size(200, 200));
      }
      
      final finalMemory = ProcessInfo.currentRss;
      final memoryIncrease = (finalMemory - initialMemory) / 1024 / 1024; // MB
      
      expect(
        memoryIncrease,
        lessThan(200), // Should not increase by more than 200MB
        reason: 'Memory usage increased by ${memoryIncrease.toStringAsFixed(1)}MB',
      );
    });

    test('concurrent image processing stress test', () async {
      const concurrentOperations = 5;
      final stopwatch = Stopwatch()..start();
      
      final futures = List.generate(
        concurrentOperations,
        (index) => service.loadImage(testImageData),
      );
      
      await Future.wait(futures);
      
      stopwatch.stop();
      
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(3000), // Should complete within 3 seconds
        reason: 'Concurrent processing took ${stopwatch.elapsedMilliseconds}ms',
      );
    });
  });
}
```

#### End-to-End Workflow Tests
```dart
// test/e2e/complete_workflow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:patrol/patrol.dart';

import 'package:ai_photo_editor/main.dart' as app;
import '../helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Complete AI Photo Editor Workflow', () {
    patrolTest('full editing workflow from start to finish', ($) async {
      // 1. Start app and authenticate
      app.main();
      await $.pumpAndSettle();
      
      await $.enterText(find.byKey('email_field'), 'test@example.com');
      await $.enterText(find.byKey('password_field'), 'password123');
      await $.tap(find.byKey('sign_in_button'));
      await $.waitUntilVisible(find.text('AI Photo Editor'));
      
      // 2. Navigate to image selection
      await $.tap(find.byKey('start_editing_button'));
      await $.waitUntilVisible(find.text('Select Image'));
      
      // 3. Select image from gallery
      await $.tap(find.byKey('gallery_button'));
      await $.waitUntilVisible(find.byKey('image_grid'));
      await $.tap(find.byKey('test_image_1'));
      
      // 4. Navigate to editor
      await $.waitUntilVisible(find.byKey('image_editor_screen'));
      
      // 5. Add markers to image
      await $.tap(find.byKey('add_marker_button'));
      await $.dragFrom(
        find.byKey('image_canvas'),
        const Offset(100, 100),
      );
      
      // Verify marker is added
      expect(find.byKey('marker_overlay'), findsOneWidget);
      
      // 6. Start AI processing
      await $.tap(find.byKey('process_button'));
      await $.waitUntilVisible(find.text('Processing...'));
      
      // 7. Wait for processing to complete
      await $.waitUntilVisible(
        find.text('Processing Complete'),
        timeout: const Duration(minutes: 2),
      );
      
      // 8. View results
      await $.tap(find.byKey('view_result_button'));
      await $.waitUntilVisible(find.byKey('result_screen'));
      
      // 9. Save to gallery
      await $.tap(find.byKey('save_button'));
      await $.waitUntilVisible(find.text('Saved to Gallery'));
      
      // 10. Share result
      await $.tap(find.byKey('share_button'));
      await $.waitUntilVisible(find.text('Share'));
      
      // 11. Navigate to gallery
      await $.tap(find.byKey('gallery_tab'));
      await $.waitUntilVisible(find.byKey('gallery_screen'));
      
      // Verify result appears in gallery
      expect(find.byKey('gallery_item_0'), findsOneWidget);
    });

    patrolTest('error handling throughout workflow', ($) async {
      app.main();
      await $.pumpAndSettle();
      
      // Test network error during authentication
      await $.enterText(find.byKey('email_field'), 'test@example.com');
      await $.enterText(find.byKey('password_field'), 'password123');
      
      // Simulate network failure
      await $.native.disableWifi();
      await $.tap(find.byKey('sign_in_button'));
      
      await $.waitUntilVisible(find.text('Network error'));
      
      // Re-enable network and retry
      await $.native.enableWifi();
      await $.tap(find.byKey('retry_button'));
      
      await $.waitUntilVisible(find.text('AI Photo Editor'));
    });

    patrolTest('app state persistence across restarts', ($) async {
      // Start editing session
      app.main();
      await $.pumpAndSettle();
      
      await $.enterText(find.byKey('email_field'), 'test@example.com');
      await $.enterText(find.byKey('password_field'), 'password123');
      await $.tap(find.byKey('sign_in_button'));
      await $.waitUntilVisible(find.text('AI Photo Editor'));
      
      // Start editing an image
      await $.tap(find.byKey('start_editing_button'));
      await $.tap(find.byKey('gallery_button'));
      await $.tap(find.byKey('test_image_1'));
      
      // Add some markers
      await $.tap(find.byKey('add_marker_button'));
      await $.dragFrom(find.byKey('image_canvas'), const Offset(100, 100));
      
      // Restart app
      await $.restart();
      
      // Should maintain session and return to editor
      await $.waitUntilVisible(find.byKey('image_editor_screen'));
      expect(find.byKey('marker_overlay'), findsOneWidget);
    });
  });
}
```

### 3. Golden Tests for UI Components
```dart
// test/golden/ui_components_golden_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:ai_photo_editor/core/widgets/custom_button.dart';
import 'package:ai_photo_editor/features/authentication/presentation/widgets/auth_form.dart';
import '../helpers/golden_test_helpers.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('UI Components Golden Tests', () {
    setUpAll(() async {
      await loadAppFonts();
    });

    testGoldens('CustomButton variations', (tester) async {
      const buttons = [
        CustomButton(
          text: 'Primary Button',
          onPressed: null,
          type: ButtonType.primary,
        ),
        CustomButton(
          text: 'Secondary Button',
          onPressed: null,
          type: ButtonType.secondary,
        ),
        CustomButton(
          text: 'Disabled Button',
          onPressed: null,
          type: ButtonType.primary,
          isEnabled: false,
        ),
        CustomButton(
          text: 'Loading Button',
          onPressed: null,
          type: ButtonType.primary,
          isLoading: true,
        ),
      ];

      await tester.pumpWidget(
        TestHelpers.makeTestableWidget(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: buttons
                .map((button) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: button,
                    ))
                .toList(),
          ),
        ),
      );

      await screenMatchesGolden(tester, 'custom_button_variations');
    });

    testGoldens('AuthForm states', (tester) async {
      const forms = [
        AuthForm(
          key: Key('normal_form'),
          isLoading: false,
          errorMessage: null,
        ),
        AuthForm(
          key: Key('loading_form'),
          isLoading: true,
          errorMessage: null,
        ),
        AuthForm(
          key: Key('error_form'),
          isLoading: false,
          errorMessage: 'Invalid credentials',
        ),
      ];

      for (int i = 0; i < forms.length; i++) {
        await tester.pumpWidget(
          TestHelpers.makeTestableWidget(child: forms[i]),
        );

        await screenMatchesGolden(
          tester,
          'auth_form_state_$i',
        );
      }
    });

    group('Responsive Design Golden Tests', () {
      testGoldens('responsive auth form', (tester) async {
        await GoldenTestHelpers.testResponsiveGoldens(
          tester,
          'auth_form_responsive',
          (size) => TestHelpers.makeTestableWidget(
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: const AuthForm(),
            ),
          ),
        );
      });
    });

    group('Dark Mode Golden Tests', () {
      testGoldens('dark mode components', (tester) async {
        const components = [
          CustomButton(
            text: 'Dark Mode Button',
            onPressed: null,
            type: ButtonType.primary,
          ),
          AuthForm(),
        ];

        for (int i = 0; i < components.length; i++) {
          await tester.pumpWidget(
            TestHelpers.makeTestableWidget(
              child: components[i],
              theme: ThemeData.dark(),
            ),
          );

          await screenMatchesGolden(
            tester,
            'dark_mode_component_$i',
          );
        }
      });
    });
  });
}
```

### 4. Accessibility Testing
```dart
// test/accessibility/accessibility_test.dart
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_photo_editor/features/authentication/presentation/pages/auth_page.dart';
import 'package:ai_photo_editor/features/image_editor/presentation/pages/image_editor_page.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Accessibility Tests', () {
    testWidgets('auth page accessibility compliance', (tester) async {
      await tester.pumpWidget(
        TestHelpers.makeTestableWidget(
          child: const AuthPage(),
        ),
      );

      // Test semantic labels
      expect(
        find.bySemanticsLabel('Email address'),
        findsOneWidget,
      );
      
      expect(
        find.bySemanticsLabel('Password'),
        findsOneWidget,
      );
      
      expect(
        find.bySemanticsLabel('Sign in button'),
        findsOneWidget,
      );

      // Test focus traversal
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(
        tester.binding.focusManager.primaryFocus?.context?.widget,
        isA<TextField>(),
      );

      // Test screen reader announcements
      final SemanticsHandle handle = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.byType(AuthPage)),
        matchesSemantics(
          children: [
            matchesSemantics(
              label: 'Sign in to your account',
              isHeader: true,
            ),
            matchesSemantics(
              label: 'Email address',
              isTextField: true,
            ),
            matchesSemantics(
              label: 'Password',
              isTextField: true,
              isObscured: true,
            ),
            matchesSemantics(
              label: 'Sign in button',
              isButton: true,
            ),
          ],
        ),
      );
      handle.dispose();
    });

    testWidgets('image editor accessibility features', (tester) async {
      await tester.pumpWidget(
        TestHelpers.makeTestableWidget(
          child: const ImageEditorPage(),
        ),
      );

      // Test gesture descriptions for screen readers
      expect(
        find.bySemanticsLabel('Double tap to add marker'),
        findsOneWidget,
      );
      
      expect(
        find.bySemanticsLabel('Pinch to zoom image'),
        findsOneWidget,
      );

      // Test contrast ratios (simulated)
      final colorScheme = Theme.of(tester.element(find.byType(ImageEditorPage)))
          .colorScheme;
      
      expect(
        _calculateContrastRatio(
          colorScheme.primary,
          colorScheme.onPrimary,
        ),
        greaterThan(4.5), // WCAG AA compliance
      );
    });

    testWidgets('keyboard navigation support', (tester) async {
      await tester.pumpWidget(
        TestHelpers.makeTestableWidget(
          child: const AuthPage(),
        ),
      );

      // Test tab navigation
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      
      // Should be on sign in button
      expect(
        tester.binding.focusManager.primaryFocus?.context?.widget
            ?.runtimeType
            ?.toString(),
        contains('Button'),
      );

      // Test enter key activation
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      
      // Should trigger sign in action
      await tester.pumpAndSettle();
    });

    testWidgets('large text support', (tester) async {
      await tester.pumpWidget(
        TestHelpers.makeTestableWidget(
          child: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2.0), // 200% text size
            ),
            child: const AuthPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify layout doesn't break with large text
      expect(find.byType(Overflow), findsNothing);
      
      // Verify text is actually scaled
      final textWidget = tester.widget<Text>(find.text('Sign In').first);
      expect(textWidget.textScaler, const TextScaler.linear(2.0));
    });
  });
}

double _calculateContrastRatio(Color color1, Color color2) {
  final luminance1 = color1.computeLuminance();
  final luminance2 = color2.computeLuminance();
  final lighter = math.max(luminance1, luminance2);
  final darker = math.min(luminance1, luminance2);
  return (lighter + 0.05) / (darker + 0.05);
}
```

### 5. Test Automation & CI Integration
```yaml
# .github/workflows/test.yml
name: Comprehensive Testing

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  unit_tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Run unit tests with coverage
        run: |
          flutter test --coverage
          genhtml coverage/lcov.info -o coverage/html
      
      - name: Check coverage threshold
        run: |
          COVERAGE=$(lcov --summary coverage/lcov.info | grep -o 'lines......: [0-9]*\.[0-9]*%' | grep -o '[0-9]*\.[0-9]*')
          echo "Coverage: $COVERAGE%"
          if (( $(echo "$COVERAGE < 95" | bc -l) )); then
            echo "Coverage $COVERAGE% is below threshold 95%"
            exit 1
          fi
      
      - name: Upload coverage reports
        uses: codecov/codecov-action@v3
        with:
          file: coverage/lcov.info

  widget_tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Run widget tests
        run: flutter test test/widgets/
      
      - name: Generate golden test baselines
        run: flutter test --update-goldens test/golden/

  integration_tests:
    runs-on: macos-latest
    strategy:
      matrix:
        device: [ "iPhone 15", "iPad Pro (12.9-inch)" ]
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      
      - name: Start iOS Simulator
        run: |
          xcrun simctl boot "${{ matrix.device }}" || true
          xcrun simctl list devices
      
      - name: Run integration tests
        run: |
          flutter drive \
            --driver=test_driver/integration_test.dart \
            --target=integration_test/app_test.dart \
            -d "iPhone 15"

  performance_tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      
      - name: Run performance tests
        run: flutter test test/performance/
      
      - name: Generate performance report
        run: |
          echo "## Performance Test Results" >> $GITHUB_STEP_SUMMARY
          echo "| Test | Result | Threshold | Status |" >> $GITHUB_STEP_SUMMARY
          echo "|------|--------|-----------|---------|" >> $GITHUB_STEP_SUMMARY
          # Add actual results here

  accessibility_tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      
      - name: Run accessibility tests
        run: flutter test test/accessibility/
      
      - name: Accessibility audit
        run: |
          flutter analyze --suggestions
          dart run accessibility_tools:main
```

## Acceptance Criteria (Must All Pass)
1. ✅ Unit test coverage exceeds 95% for all business logic
2. ✅ Widget tests cover all UI components with state variations
3. ✅ Integration tests validate complete user workflows
4. ✅ Golden tests ensure UI consistency across devices
5. ✅ Performance tests validate speed and memory requirements
6. ✅ Accessibility tests ensure WCAG compliance
7. ✅ Error scenarios are comprehensively tested
8. ✅ CI pipeline runs all test suites automatically
9. ✅ Test reports provide actionable insights
10. ✅ Flaky tests are identified and resolved

**Implementation Priority:** Core functionality tests first, then edge cases and performance

**Quality Gate:** All tests pass, coverage thresholds met, performance benchmarks achieved

**Performance Target:** Test suite completion < 10 minutes, reliable CI pipeline

---

**Next Step:** After completion, proceed to Final Assembly & Deployment (Phase 7)

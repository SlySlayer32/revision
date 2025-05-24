---
applyTo: "**/*_test.dart"
---
# Testing Guidelines

This document provides guidelines for writing various types of tests in the Flutter AI Photo Editor project. Consistent and comprehensive testing is crucial for maintaining code quality and stability.

Refer also to:
- [BLoC & Cubit Implementation Guidelines](./bloc-guidelines.instructions.md) for testing BLoC/Cubit logic.
- [BLoC/Cubit Widget Structure Guidelines](./bloc_widget_structure.instructions.md) for how UI components are structured and tested.

## General Testing Principles

- Write tests for all business logic
- Follow the AAA pattern: Arrange, Act, Assert
- Use meaningful test names that describe the behavior being tested
- Keep tests independent from each other
- Aim for high test coverage, particularly in the domain, data, and BLoC/Cubit layers
- Mock external dependencies and services

## Unit Testing

- Use the `test` package for unit tests.
- Test individual functions, methods, and classes in isolation.
- Test edge cases and error handling.
- Mock dependencies using `mocktail`. Avoid `mockito` unless `mocktail` is insufficient for a specific scenario due to its reliance on code generation.
- Group related tests with `group` function.
- Use setup and teardown for common test preparation.

```dart
// Example unit test for a UseCase or Repository method
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

class YourEntity {
  final String id;
  YourEntity({required this.id});
}

class YourFailure {}

abstract class YourRepository {
  Future<(YourEntity?, YourFailure?)> getEntity(String id);
}

class GetYourEntity {
  final YourRepository repository;
  GetYourEntity(this.repository);

  Future<(YourEntity?, YourFailure?)> call(String params) async {
    return repository.getEntity(params);
  }
}

class MockImageRepository extends Mock implements YourRepository {}

void main() {
  late MockImageRepository mockRepository;

  setUp(() {
    mockRepository = MockImageRepository();
  });

  group('GetYourEntity UseCase', () {
    test('should return entity when repository call is successful', () async {
      // Arrange
      final tYourEntity = YourEntity(id: '1');
      when(() => mockRepository.getEntity(any())).thenAnswer((_) async => (tYourEntity, null));
      
      // Act
      final result = await GetYourEntity(mockRepository).call('1');
      
      // Assert
      expect(result.$1, tYourEntity);
      expect(result.$2, isNull);
      verify(() => mockRepository.getEntity('1'));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return failure when repository call fails', () async {
      // Arrange
      when(() => mockRepository.getEntity(any())).thenAnswer((_) async => (null, YourFailure()));
      
      // Act
      final result = await GetYourEntity(mockRepository).call('non_existent_id');
      
      // Assert
      expect(result.$1, isNull);
      expect(result.$2, isA<YourFailure>());
      verify(() => mockRepository.getEntity('non_existent_id'));
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
```

## Widget Testing

- Use the `flutter_test` package for widget tests.
- Test widget rendering, user interactions (tapping, scrolling, entering text), and callbacks.
- Use `WidgetTester` to interact with widgets.
- Verify that widgets respond correctly to different states.
- Use `pump` and `pumpAndSettle` appropriately.
- Use the provided `pumpApp` helper (located in `test/helpers/pump_app.dart`) to set up a consistent widget testing environment. This helper should wrap the widget under test with `MaterialApp` and any necessary global providers (like `Localization` or `Theme`).
- When testing widgets that depend on a BLoC/Cubit, provide a mock BLoC/Cubit using `BlocProvider.value`.
- Ensure `MaterialApp` or `Scaffold` is an ancestor if the widget relies on `MediaQuery` or theme data.

```dart
// Example widget test
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

class ImageEditorState {}
class ImageEditorLoaded extends ImageEditorState {}

class ImageEditorCubit extends Cubit<ImageEditorState> {
  ImageEditorCubit() : super(ImageEditorState());
  void addMarker(dynamic point) {}
}

class ImageMarker extends StatelessWidget {
  const ImageMarker({super.key});
  @override
  Widget build(BuildContext context) {
    return CustomPaint();
  }
}

class MockImageEditorCubit extends Mock implements ImageEditorCubit {}
class FakeImageEditorState extends Fake implements ImageEditorState {}

Future<void> pumpApp(WidgetTester tester, Widget widget, {ImageEditorCubit? imageEditorCubit}) {
  return tester.pumpWidget(
    MaterialApp(
      home: imageEditorCubit != null
          ? BlocProvider<ImageEditorCubit>.value(
              value: imageEditorCubit,
              child: Scaffold(body: widget),
            )
          : Scaffold(body: widget),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeImageEditorState());
  });

  group('ImageMarker', () {
    late MockImageEditorCubit mockImageEditorCubit;

    setUp(() {
      mockImageEditorCubit = MockImageEditorCubit();
    });

    testWidgets('displays marker at the correct position when state is ImageEditorLoaded', (WidgetTester tester) async {
      // Arrange
      final state = ImageEditorLoaded();
      when(() => mockImageEditorCubit.state).thenReturn(state);

      // Act
      await pumpApp(
        tester,
        const ImageMarker(),
        imageEditorCubit: mockImageEditorCubit,
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('calls addMarker on tap', (WidgetTester tester) async {
      // Arrange
      when(() => mockImageEditorCubit.addMarker(any())).thenAnswer((_) async {});

      await pumpApp(
        tester,
        GestureDetector(
          onTap: () => mockImageEditorCubit.addMarker(const Offset(50, 50)),
          child: const ImageMarker(),
        ),
        imageEditorCubit: mockImageEditorCubit,
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byType(ImageMarker));
      await tester.pumpAndSettle();

      // Assert
      verify(() => mockImageEditorCubit.addMarker(const Offset(50, 50))).called(1);
    });
  });
}
```

## BLoC/Cubit Testing

- Use the `bloc_test` package for testing BLoCs and Cubits.
- Test all event-to-state transitions.
- Verify initial state.
- Mock repository and use case dependencies using `mocktail`.
- Ensure all possible states and events are covered.

```dart
// Example BLoC test
import 'package:bloc_test/bloc_test.dart';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

class YourRepository {
  Future<(String?, String?)> processImage(String path) async => ('processed_image.jpg', null);
}

class ImageEditorState {}
class ImageEditorInitial extends ImageEditorState {}
class ImageEditorLoading extends ImageEditorState {}
class ImageEditorLoaded extends ImageEditorState {}
class ImageEditorError extends ImageEditorState {
  final String message;
  ImageEditorError(this.message);
}

class ImageEditorEvent {}
class ImageSelected extends ImageEditorEvent {}

class ImageEditorBloc extends Bloc<ImageEditorEvent, ImageEditorState> {
  final YourRepository repository;
  ImageEditorBloc({required this.repository}) : super(ImageEditorInitial()) {
    on<ImageSelected>((event, emit) async {
      emit(ImageEditorLoading());
      final (processedPath, error) = await repository.processImage("some/path");
      if (error != null) {
        emit(ImageEditorError(error));
      } else {
        emit(ImageEditorLoaded());
      }
    });
  }
}

class MockImageRepository extends Mock implements YourRepository {}

void main() {
  late MockImageRepository mockImageRepository;
  late ImageEditorBloc imageEditorBloc;

  setUp(() {
    mockImageRepository = MockImageRepository();
    imageEditorBloc = ImageEditorBloc(repository: mockImageRepository);
  });

  tearDown(() {
    imageEditorBloc.close();
  });

  test('initial state is ImageEditorInitial', () {
    expect(imageEditorBloc.state, isA<ImageEditorInitial>());
  });

  group('ImageSelected Event', () {
    blocTest<ImageEditorBloc, ImageEditorState>(
      'emits [ImageEditorLoading, ImageEditorLoaded] when ImageSelected is added and repository call is successful',
      setUp: () {
        when(() => mockImageRepository.processImage(any()))
            .thenAnswer((_) async => ('processed_image.jpg', null));
      },
      build: () => imageEditorBloc,
      act: (bloc) => bloc.add(ImageSelected()),
      expect: () => [
        isA<ImageEditorLoading>(),
        isA<ImageEditorLoaded>(),
      ],
      verify: (_) {
        verify(() => mockImageRepository.processImage(any())).called(1);
      },
    );

    blocTest<ImageEditorBloc, ImageEditorState>(
      'emits [ImageEditorLoading, ImageEditorError] when ImageSelected is added and repository call fails',
      setUp: () {
        when(() => mockImageRepository.processImage(any()))
            .thenAnswer((_) async => (null, 'Error processing image'));
      },
      build: () => imageEditorBloc,
      act: (bloc) => bloc.add(ImageSelected()),
      expect: () => [
        isA<ImageEditorLoading>(),
        isA<ImageEditorError>(),
      ],
    );
  });
}
```

## Integration Testing

- Use the `integration_test` package for end-to-end (E2E) tests.
- Ensure `IntegrationTestWidgetsFlutterBinding.ensureInitialized();` is called at the beginning of your test file.
- Structure tests within a `group`.
- Launch the main application using `app.main()` (or `app.mainDevelopment()` / `app.mainProduction()` as appropriate) and use `tester.pumpAndSettle()` to wait for the UI to stabilize.
- Use `find.byKey(const Key('yourWidgetKey'))`, `find.text('Your Text')`, `find.byType(YourWidgetType)` etc., to locate widgets.
- Interact with widgets using `tester.tap()`, `tester.enterText()`, `tester.drag()`, etc.
- Always `await tester.pumpAndSettle()` after actions that trigger UI changes or animations.
- For Firebase dependent flows (like Auth), consider if these need to be E2E tested or if mocking at a lower level is sufficient. If E2E testing Firebase, ensure your test environment is configured correctly (e.g., using the Firebase Local Emulator Suite).

```dart
// Example integration test
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:your_app/main_development.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-end App Flow', () {
    testWidgets('Login, select image, mark tree, process, and view result', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Log in
      await tester.tap(find.byKey(const Key('loginButton')));
      await tester.pumpAndSettle();

      // Navigate to image selection
      await tester.tap(find.byKey(const Key('selectImageButton')));
      await tester.pumpAndSettle();

      // Add a marker
      await tester.tap(find.byType(ImageDisplay));
      await tester.pumpAndSettle();

      // Process image
      await tester.tap(find.byKey(const Key('processImageButton')));
      await tester.pumpAndSettle();

      // Verify result screen is shown
      expect(find.byType(ResultPage), findsOneWidget);
    });
  });
}
```

## Test Data Management

- Use fixture files (e.g., JSON for API responses, sample images) for test data.
- Create factory methods or classes (e.g., using `Faker` package) for generating realistic test model instances.
- Store test resources (images, JSON files) in a designated `test/fixtures` or `test/resources` directory.
- Use helper functions to load test data.

## Golden Tests (Optional)

- For UI components that are critical to visual correctness, consider adding golden tests using the `golden_toolkit` package.
- Golden tests capture a widget's appearance as an image and compare it against a master image.
- These are particularly useful for preventing unintentional UI regressions.
- Store golden files in a `test/goldens` directory, typically organized by feature or widget.

```dart
// Example Golden Test
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  group('YourCustomWidget Golden Tests', () {
    testGoldens('renders correctly with default properties', (WidgetTester tester) async {
      final builder = DeviceBuilder()
        ..addScenario(
          widget: YourCustomWidget(title: 'Test Title'),
          name: 'default_state',
        );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'your_custom_widget_default');
    });

    testGoldens('renders correctly with alternative properties', (WidgetTester tester) async {
      final builder = DeviceBuilder()
        ..addScenario(
          widget: YourCustomWidget(title: 'Another Title', isActive: true),
          name: 'active_state',
        );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'your_custom_widget_active');
    });
  });
}
```

Ensure all tests are runnable via `flutter test`.
For integration tests, run using `flutter test integration_test`.

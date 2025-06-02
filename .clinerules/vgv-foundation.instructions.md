---
applyTo: "**/*.dart"
---
# VGV Foundation - Architecture & Standards

## VGV 100% Compliant Project Structure

Follow Very Good Ventures boilerplate patterns exactly:

```
lib/
├── app/
│   ├── app.dart                 # VGV App widget
│   └── view/
│       └── app.dart
├── bootstrap.dart               # VGV bootstrap
├── l10n/                       # VGV localization
├── features/                   # Feature-based modules
│   ├── authentication/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── bloc/
│   │       ├── pages/
│   │       └── widgets/
│   ├── image_editor/
│   └── ai_processing/
└── main_development.dart        # VGV environment setup
```

## 3-Layer Architecture (VGV Clean Architecture)

### **Layer 1: Presentation** (`presentation/`)
- **Pages**: Route-level widgets with BlocProvider
- **Views**: Main UI components consuming BLoC state
- **Widgets**: Specialized UI components
- **BLoCs/Cubits**: UI state management

```dart
// VGV Page Pattern
class ImageEditorPage extends StatelessWidget {
  const ImageEditorPage({super.key});

  static Route<void> route() {
    return PageRouteBuilder<void>(
      builder: (_) => const ImageEditorPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => context.read<ImageEditorBloc>(),
      child: const ImageEditorView(),
    );
  }
}
```

### **Layer 2: Domain** (`domain/`)
- **Entities**: Pure business objects
- **Repository Interfaces**: Abstract contracts
- **Use Cases**: Business logic operations

```dart
// VGV Entity Pattern
class ProcessedImage extends Equatable {
  const ProcessedImage({
    required this.originalPath,
    required this.editedPath,
    required this.markers,
  });

  final String originalPath;
  final String editedPath;
  final List<ImageMarker> markers;

  @override
  List<Object> get props => [originalPath, editedPath, markers];
}
```

### **Layer 3: Data** (`data/`)
- **Models**: Data transfer objects
- **Repository Implementations**: Concrete data operations
- **Data Sources**: API clients, local storage

```dart
// VGV Repository Implementation Pattern
class ImageRepositoryImpl implements ImageRepository {
  const ImageRepositoryImpl({
    required ImageLocalDataSource localDataSource,
    required ImageRemoteDataSource remoteDataSource,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource;

  final ImageLocalDataSource _localDataSource;
  final ImageRemoteDataSource _remoteDataSource;

  @override
  Future<ProcessedImage> processImage(String imagePath) async {
    // Implementation
  }
}
```

## VGV Coding Standards

### Dart Language Features (VGV Style)
- Use `const` constructors everywhere possible
- Prefer `final` for local variables
- Use cascade notation (`..`) for multiple operations
- Implement `Equatable` for all entities and states
- Use sealed classes for state management

### File Naming (VGV Convention)
- `snake_case` for files: `image_editor_bloc.dart`
- `PascalCase` for classes: `ImageEditorBloc`
- `camelCase` for variables: `selectedImage`

### Error Handling (VGV Pattern)
```dart
// VGV Custom Exception Pattern
class ImageProcessingException implements Exception {
  const ImageProcessingException(this.message);
  final String message;
}

// VGV Result Pattern
abstract class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

class Failure<T> extends Result<T> {
  const Failure(this.exception);
  final Exception exception;
}
```

## VGV State Management Patterns

### BLoC Event-State Pattern
```dart
// VGV Event Pattern
sealed class ImageEditorEvent extends Equatable {
  const ImageEditorEvent();
}

final class ImageSelected extends ImageEditorEvent {
  const ImageSelected(this.imagePath);
  final String imagePath;
  
  @override
  List<Object> get props => [imagePath];
}

// VGV State Pattern
sealed class ImageEditorState extends Equatable {
  const ImageEditorState();
}

final class ImageEditorInitial extends ImageEditorState {
  const ImageEditorInitial();
  
  @override
  List<Object> get props => [];
}
```

## VGV Dependency Injection

Use `get_it` exactly as VGV pattern:

```dart
// bootstrap.dart (VGV Pattern)
Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      
      // VGV Dependency Setup
      await _setupDependencies();
      
      runApp(await builder());
    },
    (error, stackTrace) => log(error.toString(), stackTrace: stackTrace),
  );
}

// VGV Service Locator Pattern
Future<void> _setupDependencies() async {
  // Core
  getIt.registerLazySingleton<ImagePicker>(() => ImagePicker());
  
  // Data Sources
  getIt.registerLazySingleton<VertexAIDataSource>(
    () => VertexAIDataSourceImpl(),
  );
  
  // Repositories
  getIt.registerLazySingleton<ImageRepository>(
    () => ImageRepositoryImpl(
      localDataSource: getIt<ImageLocalDataSource>(),
      remoteDataSource: getIt<VertexAIDataSource>(),
    ),
  );
  
  // Use Cases
  getIt.registerLazySingleton<ProcessImageUseCase>(
    () => ProcessImageUseCase(getIt<ImageRepository>()),
  );
  
  // BLoCs
  getIt.registerFactory<ImageEditorBloc>(
    () => ImageEditorBloc(processImage: getIt<ProcessImageUseCase>()),
  );
}
```

## VGV Performance Standards

- Use `const` constructors for widgets
- Implement `Equatable` for efficient state comparisons
- Use `flutter_bloc` with proper state equality
- Optimize image handling with proper memory management
- Use VGV's environment-based configuration

**Always follow VGV boilerplate patterns exactly - no deviations from established conventions.**

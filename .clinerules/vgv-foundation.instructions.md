---
applyTo: "**/*.dart"
---

# VGV Foundation - Production-Ready Architecture & Standards Protocol

**Objective:** This protocol provides directives for implementing foundational VGV patterns with a focus on production readiness, robust error handling, realistic testing, and maintainability, aligning with professional Flutter development practices.

---

## Phase 1: Core Architectural Setup & Mandates

### Step 1: Establish VGV Compliant Project Structure

**Directive for AI:**
```
ENSURE all project scaffolding and new feature modules strictly adhere to the VGV standard 3-layer clean architecture and feature-based directory structure. This structure is critical for maintainability, testability, and mapping to real-world problem domains.

**REFERENCE PROJECT STRUCTURE:**
lib/
├── app/
│   ├── app.dart                 # Main App widget wrapper
│   └── view/
│       └── app.dart             # Core App widget
├── bootstrap.dart               # Application entry & DI setup
├── core/                        # Shared utilities, constants, base classes
│   ├── constants/
│   │   └── app_config.dart      # Environment-specific config (see docs/FOLLOW.md)
│   ├── error/
│   │   └── failures.dart        # Comprehensive Failure types (see docs/FOLLOW.md)
│   ├── utils/
│   │   ├── logger.dart          # AppLogger for debugging (see docs/FOLLOW.md)
│   │   └── error_message_mapper.dart # User-friendly error messages
│   └── usecases/
│       └── usecase.dart         # Base UseCase interface
├── features/                   # Feature-based modules
│   └── [feature_name]/
│       ├── data/
│       ├── domain/
│       └── presentation/
├── l10n/                       # Localization
└── main_development.dart        # Environment-specific entry point
```
**MANDATE:** No deviations from this core structure without explicit justification.

### Step 2: Implement Robust Application Bootstrap

**Directive for AI:**
```
CONFIGURE `bootstrap.dart` to establish a resilient application entry point.

**PROTOCOL: BOOTSTRAP IMPLEMENTATION:**
1.  **Global Error Handling:**
    *   Implement `FlutterError.onError` to catch Flutter framework errors.
    *   Implement `PlatformDispatcher.instance.onError` for platform channel errors.
    *   Wrap `runApp` in `runZonedGuarded` to catch asynchronous errors.
    *   Log all caught errors using `AppLogger.error`.
2.  **Firebase Initialization:**
    *   Initialize Firebase using `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`.
    *   Conditionally configure Firebase Emulators for development environments (Auth, Firestore, etc.) based on `AppConfig.useFirebaseEmulator` (refer to `docs/FOLLOW.md` for `AppConfig` and emulator setup). Log emulator connection status.
3.  **Dependency Injection (DI) Setup:**
    *   Invoke `_setupDependencies()` (or `setupServiceLocator()`) to register all application services using `get_it`.
4.  **Run Application:**
    *   Execute `runApp(await builder())`.

**REFERENCE (`bootstrap.dart` from `docs/FOLLOW.md`):**
Ensure your `bootstrap.dart` aligns with the comprehensive error handling and emulator setup demonstrated in the `docs/FOLLOW.md` examples.
```

---

## Phase 2: Layer-Specific Implementation Protocols

### Step 3: Domain Layer - Core Business Logic Protocol

**Directive for AI:**
```
CONSTRUCT the Domain Layer as the pure, testable core of your business logic.

**PROTOCOL: DOMAIN LAYER IMPLEMENTATION:**
1.  **Entities:**
    *   Define as pure Dart classes, extending `Equatable` for value comparison.
    *   Represent core business concepts.
    *   Example:
        ```dart
        // VGV Entity Pattern (Adapted for clarity)
        class ProcessedImage extends Equatable {
          const ProcessedImage({
            required this.id, // Ensure entities have identifiers
            required this.originalPath,
            required this.editedPath,
            required this.markers,
          });

          final String id;
          final String originalPath;
          final String editedPath;
          final List<ImageMarker> markers; // ImageMarker should also be an Equatable entity

          @override
          List<Object> get props => [id, originalPath, editedPath, markers];
        }
        ```
2.  **Repository Interfaces (Abstract Contracts):**
    *   Define clear contracts for data operations. These interfaces are what UseCases will depend on.
3.  **UseCases:**
    *   Encapsulate single business operations.
    *   MUST return `Future<Either<Failure, SuccessType>>` to handle outcomes explicitly.
    *   Depend on Repository Interfaces, not concrete implementations.
    *   **Testing Mandate:** Achieve 100% unit test coverage. Tests MUST cover:
        *   Successful execution path.
        *   All defined `Failure` paths (e.g., `InvalidInputFailure`, `ResourceNotFoundFailure`, `NetworkFailure`).
        *   Utilize realistic test data and mock repository responses that reflect potential real-world outcomes (both success and various failures). Avoid over-mocking; focus on testing the UseCase's logic. (Refer to "Unit Test Template - Focus on Edge Cases" in `docs/FOLLOW.md`).
```

### Step 4: Data Layer - Data Management & Source Interaction Protocol

**Directive for AI:**
```
IMPLEMENT the Data Layer to manage data persistence, retrieval, and external service interactions, fulfilling Domain Layer contracts.

**PROTOCOL: DATA LAYER IMPLEMENTATION:**
1.  **Models (DTOs):**
    *   Represent data structures for external sources (API, DB).
    *   Include `fromJson`/`toJson` for serialization. Extend `Equatable`.
    *   Map to/from Domain Entities within Repository Implementations.
2.  **Data Sources (API Clients, Local Storage Adapters):**
    *   Encapsulate direct interaction with external services (e.g., `FirebaseAuth`, `FirebaseFirestore`, HTTP APIs).
    *   Handle low-level exceptions (e.g., `FirebaseAuthException`, `SocketException`, `DioException`).
3.  **Repository Implementations:**
    *   Implement Domain Layer Repository Interfaces.
    *   Coordinate Data Sources to perform operations.
    *   **Critical Error Handling:** Catch exceptions from Data Sources and map them to specific, meaningful Domain `Failure` types (e.g., `UserNotFoundFailure`, `NetworkFailure`, `UnknownFailure`). Refer to `FirebaseAuthenticationRepository._mapFirebaseAuthException` in `docs/FOLLOW.md` as a prime example.
    *   Return `Either<Failure, SuccessType>`.
    *   **Testing Mandate:** Achieve 95%+ unit test coverage. Tests MUST:
        *   Verify correct interaction with (mocked) Data Sources.
        *   Ensure accurate mapping of Data Source exceptions to Domain `Failure` types.
        *   Test data transformation logic (Model to Entity and vice-versa).
        *   When possible and practical (e.g., with Firebase Emulators), write integration tests for repositories against emulated services to validate real interactions.
```
**REFERENCE (`FirebaseAuthenticationRepository` from `docs/FOLLOW.md`):** Model your repository implementations on this example, focusing on its comprehensive error mapping and input validation.

### Step 5: Presentation Layer - UI & State Management Protocol

**Directive for AI:**
```
DEVELOP the Presentation Layer to provide a responsive, user-friendly interface, driven by robust state management.

**PROTOCOL: PRESENTATION LAYER IMPLEMENTATION:**
1.  **BLoCs/Cubits (State Management):**
    *   Manage UI state and interact with Domain UseCases.
    *   Events and States MUST extend `Equatable`. Use sealed classes for clarity.
    *   Handle `Loading` states explicitly during asynchronous operations.
    *   On UseCase failure, emit a `FailureState` containing the specific `Failure` object.
    *   **Logging:** Incorporate `AppLogger` calls to trace BLoC events, state transitions, and interactions with UseCases, especially error paths (see `AuthenticationBloc` example in `docs/FOLLOW.md`).
    *   **Testing Mandate:** Achieve 90%+ test coverage using `bloc_test`. Tests MUST:
        *   Verify correct state emissions for all events/method calls.
        *   Cover loading states and all failure states, ensuring the `Failure` object is correctly propagated.
        *   Mock UseCase responses to return both `Right(SuccessType)` and `Left(FailureType)` to test all paths.
2.  **Pages/Views/Widgets:**
    *   **VGV Page Pattern:**
        ```dart
        // VGV Page Pattern (Emphasizing BlocProvider and context.read for initial bloc access)
        class FeaturePage extends StatelessWidget {
          const FeaturePage({super.key});

          static Route<void> route() { // Or use a routing package like GoRouter
            return MaterialPageRoute<void>(builder: (_) => const FeaturePage());
          }

          @override
          Widget build(BuildContext context) {
            return BlocProvider(
              // Prefer creating BLoC here if it's scoped to this page/feature
              // Ensure dependencies for the BLoC are resolved via context.read<Dependency>() or getIt<Dependency>()
              create: (context) => getIt<FeatureBloc>()..add(FeatureStartedEvent()), // Example: Initial event
              child: const FeatureView(),
            );
          }
        }
        ```
    *   Consume BLoC states using `BlocBuilder` or `BlocListener`.
    *   Display user-friendly error messages using `ErrorMessageMapper.mapFailureToMessage(state.failure)` when a failure state is emitted (e.g., in a `SnackBar` or dedicated error widget).
    *   Show loading indicators based on loading states.
    *   **Testing Mandate:** Write widget tests for:
        *   Correct rendering based on different BLoC states (initial, loading, success, error).
        *   User interactions triggering BLoC events.
        *   Display of user-friendly error messages.
        *   Use `pumpApp` helper for providing necessary context (MaterialApp, BLoC providers).
        *   Implement Golden Tests for critical UI components to ensure visual consistency (see `docs/FOLLOW.md` for Golden Test setup).
```
**REFERENCE (`SignInForm` and `ErrorMessageMapper` from `docs/FOLLOW.md`):** Use these as examples for displaying loading states and user-friendly error messages.

---

## Phase 3: Foundational Standards & Practices

### Step 6: Adhere to VGV Coding & Naming Conventions

**Directive for AI:**
```
MAINTAIN strict adherence to VGV coding standards and naming conventions for consistency and readability.

**MANDATES:**
*   **File Naming:** `snake_case.dart` (e.g., `sign_in_usecase.dart`).
*   **Class/Enum/Typedef Naming:** `PascalCase` (e.g., `SignInUseCase`, `AuthenticationState`).
*   **Variable/Method/Parameter Naming:** `camelCase` (e.g., `signInWithEmail`, `currentUser`).
*   **Constants:** `SCREAMING_SNAKE_CASE` (e.g., `MAX_LOGIN_ATTEMPTS`).
*   **Dart Language Features:**
    *   Utilize `const` constructors wherever possible for performance.
    *   Prefer `final` for local variables and fields that are not reassigned.
    *   Use cascade notation (`..`) for fluent configuration of objects.
    *   Implement `Equatable` for all entities, models, BLoC/Cubit states, and events to ensure correct value comparisons.
    *   Employ sealed classes for BLoC/Cubit states and events to leverage exhaustive pattern matching.
```

### Step 7: Implement Professional Error Handling System

**Directive for AI:**
```
ESTABLISH a comprehensive and user-centric error handling system across all layers.

**PROTOCOL: ERROR HANDLING SYSTEM:**
1.  **Define Comprehensive `Failure` Types:**
    *   Create a hierarchy of `Failure` classes in `lib/core/error/failures.dart`, extending a base `Failure` class (which extends `Equatable`).
    *   Include specific failures for different error categories (e.g., `NetworkFailure`, `InvalidInputFailure`, `AuthenticationFailure`, `UserNotFoundFailure`, `PermissionDeniedFailure`, `UnknownFailure`).
    *   Refer to `docs/FOLLOW.md` for examples of robust `Failure` type definitions.
2.  **Utilize `Either<Failure, SuccessType>`:**
    *   All operations that can fail (especially UseCases and Repository methods) MUST return `Future<Either<Failure, SuccessType>>`.
3.  **Map Exceptions to Failures in Data Layer:**
    *   Repositories are responsible for catching low-level exceptions (e.g., `FirebaseAuthException`, `SocketException`, `HttpException`) and mapping them to the appropriate domain `Failure` type.
4.  **Propagate Failures to Presentation Layer:**
    *   BLoCs/Cubits receive `Failure` objects from UseCases and emit corresponding failure states.
5.  **Display User-Friendly Error Messages:**
    *   The UI MUST use a utility like `ErrorMessageMapper` (see `docs/FOLLOW.md`) to convert `Failure` objects into human-readable messages for the user. Avoid showing raw exception messages or stack traces.
```

### Step 8: Configure Robust Dependency Injection

**Directive for AI:**
```
IMPLEMENT Dependency Injection (DI) using `get_it` following VGV patterns to manage dependencies effectively.

**PROTOCOL: DEPENDENCY INJECTION SETUP (`lib/core/di/service_locator.dart` & `bootstrap.dart`):**
1.  **Service Locator Instance:**
    *   `final getIt = GetIt.instance;`
2.  **Registration Logic (`_setupDependencies` or `setupServiceLocator`):**
    *   **Data Sources:** Register as lazy singletons.
        ```dart
        getIt.registerLazySingleton<FirebaseAuthDataSource>(
          () => FirebaseAuthDataSourceImpl(firebaseAuth: getIt()), // Assuming FirebaseAuth itself is registered or passed
        );
        ```
    *   **Repositories:** Register implementations as lazy singletons, injecting their DataSource dependencies.
        ```dart
        getIt.registerLazySingleton<AuthenticationRepository>(
          () => FirebaseAuthenticationRepository(dataSource: getIt<FirebaseAuthDataSource>()),
        );
        ```
    *   **UseCases:** Register as lazy singletons, injecting Repository interface dependencies.
        ```dart
        getIt.registerLazySingleton<SignInUseCase>(
          () => SignInUseCase(repository: getIt<AuthenticationRepository>()),
        );
        ```
    *   **BLoCs/Cubits:** Register as factories, injecting UseCase dependencies.
        ```dart
        getIt.registerFactory<AuthenticationBloc>(
          () => AuthenticationBloc(signInUseCase: getIt<SignInUseCase>()),
        );
        ```
    *   **External Services/SDKs:** Register instances of external services like `FirebaseAuth.instance` or `ImagePicker()`.
        ```dart
        getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
        getIt.registerLazySingleton<ImagePicker>(() => ImagePicker());
        ```
3.  **Invocation in `bootstrap.dart`:**
    *   Call `await _setupDependencies();` (or `await setupServiceLocator();`) within `bootstrap.dart` before `runApp`.
```

### Step 9: Uphold Performance and Production Readiness Standards

**Directive for AI:**
```
ENSURE all development practices contribute to a performant and production-ready application.

**DIRECTIVES:**
*   **`const` Constructors:** Aggressively use `const` for widgets and other objects where possible to aid Flutter's rendering optimizations.
*   **`Equatable`:** Consistently use `Equatable` for BLoC/Cubit states and other objects involved in comparisons to prevent unnecessary rebuilds.
*   **Image Optimization:** Implement strategies for efficient image handling (e.g., appropriate sizing, compression, caching if necessary) if the application deals with images.
*   **Environment Configuration (`AppConfig`):** Utilize `AppConfig` (as shown in `docs/FOLLOW.md`) for managing environment-specific settings (API endpoints, feature flags, emulator configurations).
*   **Logging:** Employ `AppLogger` for structured logging. Ensure debug logs are conditional (e.g., `if (kDebugMode)` or `if (AppConfig.isDevelopment)`), while error logs are always active.
*   **Code Review Checklist:** Before committing code, mentally (or actually) go through a checklist similar to the "Code Review Checklist" in `docs/FOLLOW.md`, focusing on whether authentication (or the feature in question) works with emulators, error handling is complete, tests are realistic, and code quality is high.
*   **No Debug Artifacts in Production:** Ensure no `print()` statements, `debugPrint()`, or hardcoded test data/configurations are present in release builds.
```

**FINAL MANDATE: Prioritize building a working, robust, and testable application that solves real user problems. While VGV patterns provide a strong foundation, adapt and apply them pragmatically to achieve production-quality software, as guided by the principles in `docs/FOLLOW.md`.**

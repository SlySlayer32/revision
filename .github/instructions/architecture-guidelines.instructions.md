---
applyTo: "**/*.dart"
---
# Clean Architecture Guidelines

## Project Structure

Organize the project into feature-based modules with the following layers:

```
lib/
  ├── app/                  # App configuration and bootstrapping
  ├── core/                 # Core utilities, constants, and shared functionality
  │   ├── error/            # Error handling
  │   ├── network/          # Network utilities
  │   ├── util/             # General utilities
  │   └── common_widgets/   # Shared widgets that are generic and not tied to any specific feature (e.g., custom buttons, generic loading indicators).
  │
  ├── features/             # Feature modules
  │   ├── auth/             # Authentication feature
  │   │   ├── data/         # Data layer
  │   │   │   ├── datasources/
  │   │   │   ├── models/
  │   │   │   └── repositories/
  │   │   ├── domain/       # Domain layer
  │   │   │   ├── entities/
  │   │   │   ├── repositories/  # Abstract repository interfaces
  │   │   │   └── usecases/
  │   │   └── presentation/  # Presentation layer
  │   │       ├── blocs/
  │   │       ├── pages/
  │   │       └── widgets/
  │   │
  │   ├── image_editor/     # Image editing feature
  │   │   ├── data/
  │   │   ├── domain/
  │   │   └── presentation/
  │   │
  │   └── ... other features
  │
  ├── l10n/                 # Localization
  └── main.dart             # Entry point
```

## Architecture Principles

### 1. Dependency Rule

- Dependencies always point inward
- Outer layers can depend on inner layers, but inner layers cannot depend on outer layers
- Domain layer has no dependencies on other layers
- Data and presentation layers depend on domain layer

### 2. Separation of Concerns

- **Domain Layer**: Contains business logic and rules
  - Entities: Business objects
  - Repositories: Abstract interfaces defining data operations
  - Usecases: Business logic operations

- **Data Layer**: Implements data access and storage
  - Models: Data objects that map to/from entities
  - Repositories: Concrete implementations of domain repositories
  - Datasources: API clients, database helpers, etc.

- **Presentation Layer**: Handles UI and user interaction
  - Blocs/Cubits: Manage UI state
  - Pages: Full screens
  - Widgets: UI components

### 3. Dependency Injection

- Use `get_it` as a service locator for dependency injection
- Register dependencies in a central location
- Inject dependencies via constructors
- Use factories for per-request instances and singletons for shared instances

```dart
// Example dependency registration
final getIt = GetIt.instance;

void setupDependencies() {
  // Core
  getIt.registerLazySingleton<NetworkClient>(() => NetworkClientImpl());
  
  // Feature: Auth
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
    getIt<NetworkClient>(),
  ));
  
  getIt.registerFactory<AuthBloc>(() => AuthBloc(
    getIt<AuthRepository>(),
  ));
}
```

### 4. Error Handling

- Define domain-specific exceptions in the domain layer
- Handle and transform exceptions in the data layer
- Present user-friendly error messages in the presentation layer
- Use Result pattern or sealed classes for representing success/failure

### 5. Testing Strategy

- **Domain Layer**: Unit tests with mocked dependencies
- **Data Layer**: Unit tests with mocked datasources
- **Presentation Layer**: Widget tests and bloc tests
- Use test doubles (mocks, fakes, stubs) for dependencies

## Implementation Guidelines

### Data Flow

1. User interacts with UI (Presentation Layer)
2. UI events are sent to BLoC/Cubit (Presentation Layer)
3. BLoC/Cubit calls appropriate usecase (Domain Layer)
4. Usecase executes business logic using repository interfaces (Domain Layer)
5. Repository implementation retrieves/saves data from/to datasources (Data Layer)
6. Data flows back through the layers, transformed as needed
7. UI updates based on new state from BLoC/Cubit

### Feature Development Workflow

1. Define entities and repository interfaces in domain layer
2. Implement usecases in domain layer
3. Create data models and repository implementations in data layer
4. Implement BLoCs/Cubits in presentation layer
5. Build UI components in presentation layer

---
applyTo: "**/*.dart"
---
<!-- Last reviewed: 2025-05-23 -->
# General Coding Guidelines for Flutter

## Code Structure & Organization

- Organize code into feature-based modules as defined in [Architecture Guidelines](./architecture-guidelines.instructions.md).
- Follow clean architecture principles with clear separation of concerns:
  - **Presentation Layer**: UI (pages, widgets, BLoCs/Cubits that manage UI state).
  - **Domain Layer**: Business logic (entities, use cases, repository interfaces).
  - **Data Layer**: Data implementation (repositories, data sources, models that map to/from entities).
- Use descriptive file and directory names that reflect their purpose (e.g., `user_repository.dart`, `auth_bloc.dart`).
- Keep files focused on a single responsibility

## Naming Conventions

- Use `camelCase` for variables, parameters, and method names
- Use `PascalCase` for classes, enums, extensions, and type parameters
- Use `snake_case` for file names
- Prefix private members with underscore (`_`)
- Name blocs/cubits with their feature name + state management type (e.g., `AuthBloc`, `ImagePickerCubit`)

## Code Style

- Follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use clear, self-descriptive variable names
- Add concise comments for complex logic
- Maximum line length: 80 characters
- Use proper indentation (2 spaces)
- Organize class members in a logical order:
  1. Static properties
  2. Instance properties
  3. Constructors (factory constructors first, then generative constructors)
  4. Public methods
  5. Private helper methods
  6. Build method (for widgets)

## Error Handling

- Handle all exceptions properly, avoid catching generic `Exception`
- Create domain-specific exception classes when appropriate
- Use Future's `catchError` or try-catch blocks for async code
- Provide meaningful error messages for logging and debugging

## State Management

- Use BLoC pattern consistently throughout the app for managing UI state. Refer to [BLoC & Cubit Implementation Guidelines](./bloc-guidelines.instructions.md).
- When implementing BLoC in the UI, follow the `Page > View > Specialized Widget` pattern detailed in `bloc_widget_structure.instructions.md` (ensure this file exists and is correctly named).
- Define clear events, states, and transitions
- Avoid business logic in UI components
- Separate UI rendering from state management

## Testing

- Write unit tests for all business logic
- Write widget tests for complex UI components
- Mock dependencies and external services
- Aim for high test coverage in domain and data layers

## Performance Considerations

- Minimize unnecessary rebuilds
- Use const constructors when possible
- Implement memory-efficient image handling
- Avoid heavy computations on the UI thread
- Consider using background isolates for intensive tasks

## Flutter-Specific Guidelines

- Prefer composition over inheritance
- Use StatelessWidget when widget doesn't need internal state
- Extract reusable widgets into their own classes
- Use flutter_lints and adhere to recommended lint rules
- Implement proper resource disposal (e.g., close streams, controllers, BLoCs/Cubits in `dispose` or `close` methods)

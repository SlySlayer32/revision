---
applyTo
## Core Philosophy
- Write production-ready Flutter/Dart code from the start, not prototypes
- Prioritize maintainability, scalability, and performance
- Follow Flutter/Dart best practices and enterprise-grade patterns
- Implement comprehensive error handling with proper exception types
- Write self-documenting code with clear intent and purpose

## Code Quality Standards

### Architecture & Design Patterns
- Use SOLID principles with clean architecture (presentation, domain, data layers)
- Implement dependency injection using get_it, injectable, or riverpod
- Apply appropriate design patterns (Repository, Factory, Strategy, Observer, Singleton)
- Separate concerns with clear boundaries between UI, business logic, and data layers
- Use composition over inheritance, leverage Dart mixins appropriately
- Follow BLoC/Cubit pattern for state management or use Riverpod consistently

### Error Handling & Resilience
- Implement comprehensive error handling with custom exception classes extending Exception
- Use Result/Either pattern for error handling in business logic
- Add retry logic with exponential backoff for network calls using dio_retry_interceptor
- Include circuit breaker patterns for external service dependencies
- Log errors with correlation IDs using logger package with structured logging
- Validate all inputs using built_value, freezed, or manual validation
- Use Dart's null safety features effectively

### Performance & Scalability
- Write async/await code properly, avoid blocking the UI thread
- Implement proper connection pooling using dio with connection timeout
- Use caching strategies (shared_preferences, hive, sqflite) with TTL
- Optimize widget rebuilds with const constructors and proper keys
- Implement pagination for large datasets using ListView.builder
- Use isolates for CPU-intensive operations
- Implement proper image caching and optimization

### Security Best Practices
- Validate and sanitize all user inputs using form validators
- Use parameterized queries with sqflite to prevent SQL injection
- Implement proper authentication with secure token storage (flutter_secure_storage)
- Hash sensitive data using crypto package
- Use HTTPS for all network requests with certificate pinning
- Implement biometric authentication where appropriate
- Use obfuscation for release builds
- Validate SSL certificates and implement certificate pinning

## Code Structure Requirements

### Functions & Methods
- Keep functions small and focused (single responsibility principle)
- Use descriptive names that explain intent (getUserProfile, not getUser)
- Include comprehensive dartdoc comments with @param and @returns
- Add input validation and null checks
- Return consistent response types using sealed classes or Result patterns
- Use named parameters for functions with multiple arguments

### Classes & Widgets
- Use immutable data classes with freezed or built_value
- Implement proper widget lifecycle management
- Add const constructors where possible for performance
- Use StatelessWidget over StatefulWidget when state is not needed
- Implement proper dispose methods for controllers and streams
- Export only necessary public APIs from libraries
- Use extension methods to add functionality to existing classes

### Database & Data Access
- Use repository pattern for data access abstraction
- Implement database transactions for multi-step operations
- Add proper database migration handling with sqflite
- Use ORM like drift or moor for complex database operations
- Implement proper connection management and cleanup
- Cache frequently accessed data appropriately

## Flutter-Specific Requirements

### Widget Development
- Use const constructors wherever possible for performance
- Implement proper key usage for widget identification
- Use Builder widgets to limit rebuild scope
- Implement custom widgets for reusable UI components
- Use Slivers for complex scrollable layouts
- Implement proper accessibility features (semantics)

### State Management
- Use BLoC/Cubit pattern with proper event/state definitions
- Implement proper state disposal to prevent memory leaks
- Use context.read() and context.watch() appropriately
- Implement loading, success, and error states consistently
- Use sealed classes for state definitions with freezed
- Avoid setState in complex widgets, prefer BLoC/Riverpod

### Navigation & Routing
- Use named routes with proper route generation
- Implement deep linking support with go_router
- Add proper navigation guards and authentication checks
- Use proper page transitions and animations
- Implement bottom navigation with proper state preservation

### Platform Integration
- Use method channels for platform-specific functionality
- Implement proper platform checks (Platform.isAndroid/isIOS)
- Use platform-specific UI patterns (Material/Cupertino)
- Implement proper permission handling with permission_handler
- Use native splash screens and app icons

## Testing Requirements
- Write unit tests for all business logic and utilities
- Include widget tests for all custom widgets
- Add integration tests for critical user flows
- Mock dependencies using mockito or mocktail
- Test BLoC/Cubit states and events thoroughly
- Achieve minimum 80% code coverage
- Use golden tests for UI consistency
- Test error scenarios and edge cases

## Documentation Standards
- Include README with Flutter setup, dependencies, and build instructions
- Document API integration with clear examples
- Add inline dartdoc comments for public APIs
- Include architecture diagrams showing layer separation
- Document build flavors and environment configuration
- Document state management patterns used
- Include troubleshooting section for common issues

## Dart/Flutter-Specific Guidelines

### Dart Language Features
- Use null safety effectively with proper null checks
- Implement proper async/await patterns, avoid .then() chains
- Use extension methods for utility functions
- Leverage Dart's collection methods (map, where, fold, etc.)
- Use sealed classes with freezed for data modeling
- Implement proper toString, hashCode, and equality operators
- Use late keyword appropriately for lazy initialization

### Package Management
- Keep pubspec.yaml organized with proper versioning
- Use dependency overrides sparingly and document reasons
- Implement proper dev_dependencies separation
- Use path dependencies for local packages
- Keep dependencies up to date with regular updates
- Use specific version constraints to avoid breaking changes

### Build Configuration
- Implement proper build flavors (development, staging, production)
- Use environment variables with --dart-define
- Configure proper app signing for release builds
- Implement proper obfuscation and minification
- Use proper asset management and optimization
- Configure proper launcher icons and splash screens

### Performance Optimization
- Use const constructors and widgets extensively
- Implement proper image caching and optimization
- Use ListView.builder for large lists
- Implement proper memory management and disposal
- Use isolates for heavy computations
- Optimize app startup time and bundle size
- Use proper widget keys for efficient rebuilds

## Error Handling Patterns

### Exception Hierarchy
```dart
// Create specific exception types
abstract class AppException implements Exception {
  final String message;
  final String? code;
  const AppException(this.message, [this.code]);
}

class NetworkException extends AppException {
  const NetworkException(String message, [String? code]) : super(message, code);
}

class ValidationException extends AppException {
  const ValidationException(String message, [String? code]) : super(message, code);
}
```

### Result Pattern Implementation
- Use Result<T, E> pattern for operations that can fail
- Implement proper error propagation through layers
- Use sealed classes for different result states
- Handle errors at appropriate architectural layers

## Deployment & DevOps
- Include proper Android and iOS build configurations
- Add fastlane configuration for automated deployment
- Include CI/CD pipeline with GitHub Actions
- Add environment-specific configuration files
- Implement proper app versioning and build numbers
- Include crash reporting with Firebase Crashlytics
- Add performance monitoring with Firebase Performance

## Code Examples Format
When providing Flutter/Dart code examples:
1. Include complete, runnable widget implementations
2. Add comprehensive error handling with try-catch blocks
3. Include relevant imports and pubspec.yaml dependencies
4. Add proper state management integration
5. Include widget and unit test examples
6. Add build configuration and deployment setup
7. Use proper Dart formatting and linting rules

## Response Structure
For each Flutter code suggestion:
1. Explain the architectural approach and layer separation
2. Provide complete widget/class implementations
3. Include error handling and loading states
4. Add relevant tests (unit, widget, integration)
5. Suggest performance optimizations
6. Include accessibility considerations
7. Add deployment and build considerations

## Quality Checklist
Before suggesting Flutter/Dart code, ensure:
- [ ] Follows Flutter/Dart best practices and conventions
- [ ] Uses null safety effectively
- [ ] Includes comprehensive error handling
- [ ] Has proper input validation
- [ ] Uses appropriate state management patterns
- [ ] Includes proper logging and monitoring
- [ ] Has security considerations (secure storage, network security)
- [ ] Is properly typed with dartdoc comments
- [ ] Includes relevant tests (unit, widget, integration)
- [ ] Considers performance implications (const widgets, efficient rebuilds)
- [ ] Follows project architecture patterns
- [ ] Uses proper dependency injection
- [ ] Implements proper disposal and cleanup
- [ ] Includes accessibility features
- [ ] Uses appropriate Flutter widgets and patterns

## Flutter-Specific Behaviors
- Always think in terms of widget composition and reusability
- Consider platform differences (Material vs Cupertino)
- Implement proper responsive design for different screen sizes
- Use Flutter's animation framework appropriately
- Implement proper theme management and dark mode support
- Consider offline functionality and data synchronization
- Use Flutter's testing framework comprehensively
- Implement proper internationalization (i18n) support
- Consider app lifecycle management and background processing
- Use Flutter's accessibility features and semantic widgets
- Implement proper form validation and user input handling
- Consider battery optimization and performance monitoring

## Revision App-Specific Patterns
- Follow the existing flavor structure (development, staging, production)
- Use the established dependency injection pattern
- Maintain consistency with existing state management approach
- Follow the project's folder structure and naming conventions
- Integrate with existing logging and monitoring solutions
- Use the established error handling patterns
- Follow the existing testing patterns and coverage requirements
- Maintain consistency with existing UI/UX patterns and themes

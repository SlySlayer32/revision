# Flutter Development Instructions for GitHub Copilot

## Primary Focus Areas
- **Error Fixing**: Identify and resolve common Flutter errors and exceptions
- **Error Handling**: Implement robust error handling patterns throughout the application
- **Code Security**: Apply security best practices and secure coding patterns
- **Production Readiness**: Ensure code meets production-grade standards

## Error Fixing Guidelines

### Common Flutter Errors to Address
- **RenderFlex overflow errors**: Use `Expanded`, `Flexible`, or `SingleChildScrollView`
- **Null safety violations**: Implement proper null checks and null-aware operators
- **State management errors**: Fix improper state updates and widget rebuilds
- **Navigation errors**: Resolve route and context-related issues
- **Async operation errors**: Handle Future and Stream errors properly
- **Widget lifecycle errors**: Fix `setState` called on disposed widgets

### Error Detection Patterns
```dart
// Always wrap risky operations in try-catch blocks
try {
  // Risky operation
} on SpecificException catch (e) {
  // Handle specific exception
} catch (e, stackTrace) {
  // Handle general exceptions with stack trace
  logger.error('Unexpected error: $e', stackTrace: stackTrace);
}
```

## Error Handling Best Practices

### 1. Centralized Error Handling
- Implement global error handlers using `FlutterError.onError`
- Use error boundary widgets for UI error containment
- Create custom error widgets for graceful degradation

### 2. Network Error Handling
```dart
// Implement retry mechanisms and timeout handling
Future<T> withRetry<T>(Future<T> Function() operation, {int maxRetries = 3}) async {
  for (int attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await operation().timeout(Duration(seconds: 30));
    } catch (e) {
      if (attempt == maxRetries) rethrow;
      await Future.delayed(Duration(seconds: attempt * 2));
    }
  }
  throw StateError('Should not reach here');
}
```

### 3. Form Validation and Input Sanitization
- Validate all user inputs before processing
- Sanitize data to prevent injection attacks
- Use proper input formatters and validators

### 4. State Management Error Handling
- Handle state update failures gracefully
- Implement optimistic updates with rollback capabilities
- Use proper error states in UI components

## Security Best Practices

### 1. Data Protection
- **Encrypt sensitive data**: Use `flutter_secure_storage` for storing secrets
- **Validate inputs**: Always validate and sanitize user inputs
- **Secure network communication**: Use HTTPS and certificate pinning
- **Obfuscate code**: Enable code obfuscation for release builds

### 2. Authentication & Authorization
```dart
// Implement secure token storage and refresh
class AuthService {
  Future<void> storeTokenSecurely(String token) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'auth_token', value: token);
  }
  
  Future<bool> validateToken(String token) async {
    // Implement proper token validation
    return token.isNotEmpty && !_isTokenExpired(token);
  }
}
```

### 3. API Security
- Implement proper API key management
- Use environment variables for sensitive configuration
- Implement rate limiting and request validation
- Never expose sensitive information in logs

### 4. Platform Security
- Configure proper Android/iOS security settings
- Implement biometric authentication where appropriate
- Use secure storage for sensitive data
- Implement proper app signing and verification

## Production Readiness Standards

### 1. Performance Optimization
- **Lazy loading**: Implement lazy loading for large lists and images
- **Memory management**: Dispose controllers and streams properly
- **Build optimization**: Use `const` constructors and widgets where possible
- **Image optimization**: Implement proper image caching and compression

### 2. Monitoring and Logging
```dart
// Implement comprehensive logging
class Logger {
  static void info(String message, {Map<String, dynamic>? metadata}) {
    // Send to analytics/monitoring service
  }
  
  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    // Send error reports to crash reporting service
  }
}
```

### 3. Testing Requirements
- **Unit tests**: Cover all business logic and utilities
- **Widget tests**: Test UI components and interactions
- **Integration tests**: Test complete user workflows
- **Error scenario testing**: Test error handling paths

### 4. Code Quality Standards
- Follow Dart/Flutter linting rules
- Implement proper code documentation
- Use meaningful variable and function names
- Maintain consistent code formatting
- Implement proper dependency injection

### 5. Deployment Readiness
- Configure proper build variants (debug/release)
- Implement feature flags for gradual rollouts
- Set up proper CI/CD pipelines
- Configure crash reporting and analytics
- Implement proper versioning and release notes

## Architecture Patterns

### 1. Clean Architecture
- Separate business logic from UI
- Implement proper dependency inversion
- Use repository pattern for data access
- Implement use cases for business operations

### 2. State Management
```dart
// Use proper state management solutions
// BLoC pattern example with error handling
class DataBloc extends Bloc<DataEvent, DataState> {
  DataBloc() : super(DataInitial()) {
    on<LoadData>((event, emit) async {
      emit(DataLoading());
      try {
        final data = await repository.fetchData();
        emit(DataLoaded(data));
      } catch (e) {
        emit(DataError(e.toString()));
      }
    });
  }
}
```

### 3. Dependency Management
- Use proper dependency injection
- Implement service locators
- Manage object lifecycles properly
- Use interfaces for testability

## Code Review Checklist
- [ ] All error cases are handled appropriately
- [ ] Sensitive data is properly secured
- [ ] Performance considerations are addressed
- [ ] Code follows security best practices
- [ ] Tests cover error scenarios
- [ ] Documentation is comprehensive
- [ ] Memory leaks are prevented
- [ ] Network calls have proper timeout and retry logic

## Emergency Response
When critical errors occur:
1. Implement immediate fallback mechanisms
2. Log detailed error information
3. Notify monitoring systems
4. Provide user-friendly error messages
5. Implement graceful degradation
6. Plan for quick hotfix deployment

Remember: Always prioritize user experience while maintaining security and stability.

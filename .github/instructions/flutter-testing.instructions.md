---
applyTo: "**/*.dart"
---
# Flutter Testing and Development Best Practices

This document provides comprehensive guidelines for testing and development best practices in Flutter projects.

## Test File Organization Strategy

### Should You Create Dedicated Test Files for All Features From the Start?

Creating dedicated test files for all features from the beginning offers several advantages, but there are also practical considerations to weigh.

#### Benefits of Creating Dedicated Test Files Early

- **Comprehensive Coverage:** Starting with dedicated test files helps ensure that every feature is covered, reducing the risk of undetected bugs and regressions.
- **Maintainability:** Well-organized test files make it easier to update, refactor, and maintain both your tests and your codebase as the project grows.
- **Efficient Debugging:** When each feature has its own test file, it's easier to pinpoint where issues arise, speeding up troubleshooting and bug fixes.
- **Supports Shift-Left Testing:** Writing tests early in development aligns with modern "shift-left" testing practices, which catch issues sooner and improve code quality.

#### Practical Considerations

- **Resource Management:** Creating and maintaining tests for every feature can increase initial development time and resource usage, especially for features likely to change frequently or that are not business-critical.
- **Test Suite Performance:** Large numbers of tests can slow down your test suite, so it's important to balance coverage with efficiency. Focus comprehensive tests on critical workflows and core features, and consider lighter coverage for less critical or rarely used features.
- **Test Organization:** Whether you keep test files alongside source files or in a separate directory, consistency and clarity in your project structure are key for long-term maintainability.

#### Best Practice Approach

- **Start With Tests for Core and Critical Features:** Prioritize writing dedicated test files for features that are business-critical or central to your app's functionality.
- **Expand Coverage Iteratively:** As your app stabilizes and grows, incrementally add test files for additional features, especially as they become more stable or important.
- **Avoid Testing "Just for Coverage":** Each test should add real value. Avoid writing tests for trivial or unstable features that are likely to change soon, unless they are critical.

**In summary:**  
It's generally best to create dedicated test files for all important features from the start, especially for core and stable parts of your app. This improves maintainability, debugging, and code quality. For less critical or rapidly changing features, you can defer or limit test file creation until those features stabilize or become more important, ensuring your test suite remains efficient and valuable.

## Testing Types in Flutter

### 1. Unit Tests
- **Purpose:** Test individual functions, methods, and classes in isolation
- **Location:** `test/` directory
- **Best Practices:**
  - Test business logic and pure functions
  - Mock external dependencies
  - Follow the AAA pattern (Arrange, Act, Assert)
  - Use descriptive test names that explain the expected behavior

### 2. Widget Tests
- **Purpose:** Test UI components and their interactions
- **Location:** `test/` directory
- **Best Practices:**
  - Test widget rendering and user interactions
  - Use `testWidgets()` function
  - Pump widgets with necessary dependencies
  - Test accessibility features

### 3. Integration Tests
- **Purpose:** Test complete user flows and app behavior
- **Location:** `integration_test/` directory
- **Best Practices:**
  - Test critical user journeys
  - Use real device or simulator
  - Test performance and memory usage
  - Include network and database interactions

## Development Best Practices

### Project Structure
```
lib/
├── app/                    # App-level configuration
├── features/              # Feature-based organization
│   ├── authentication/
│   ├── profile/
│   └── settings/
├── shared/               # Shared components
│   ├── widgets/
│   ├── utils/
│   └── constants/
└── main.dart

test/
├── app/
├── features/
│   ├── authentication/
│   ├── profile/
│   └── settings/
├── shared/
└── helpers/
```

### Code Quality Guidelines

#### 1. State Management
- Use consistent state management patterns (BLoC, Provider, Riverpod)
- Separate business logic from UI components
- Implement proper error handling and loading states

#### 2. Dependency Injection
- Use dependency injection for better testability
- Mock dependencies in tests
- Follow SOLID principles

#### 3. Error Handling
- Implement comprehensive error handling
- Use custom exception classes
- Provide meaningful error messages to users

#### 4. Performance Optimization
- Use `const` constructors where possible
- Implement lazy loading for large lists
- Optimize image loading and caching
- Monitor memory usage and performance

### Testing Guidelines

#### Test Naming Conventions
```dart
// Good
test('should return user data when login is successful', () {});
test('should throw AuthException when credentials are invalid', () {});

// Bad
test('login test', () {});
test('test user', () {});
```

#### Test Structure
```dart
group('AuthService', () {
  late AuthService authService;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    authService = AuthService(mockApiClient);
  });

  group('login', () {
    test('should return user when credentials are valid', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'password123';
      final expectedUser = User(id: '1', email: email);
      
      when(() => mockApiClient.login(email, password))
          .thenAnswer((_) async => expectedUser);

      // Act
      final result = await authService.login(email, password);

      // Assert
      expect(result, equals(expectedUser));
      verify(() => mockApiClient.login(email, password)).called(1);
    });
  });
});
```

#### Widget Testing Best Practices
```dart
testWidgets('should display error message when login fails', (tester) async {
  // Arrange
  final mockAuthBloc = MockAuthBloc();
  when(() => mockAuthBloc.state).thenReturn(
    const AuthState.error('Invalid credentials'),
  );

  // Act
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const LoginScreen(),
      ),
    ),
  );

  // Assert
  expect(find.text('Invalid credentials'), findsOneWidget);
});
```

### Continuous Integration and Testing

#### Test Automation
- Run tests on every pull request
- Implement code coverage reporting
- Use GitHub Actions or similar CI/CD tools
- Set minimum coverage thresholds

#### Code Quality Checks
- Use `flutter analyze` for static analysis
- Implement code formatting with `dart format`
- Use custom lint rules for project-specific requirements
- Regular dependency updates and security checks

### Testing Tools and Libraries

#### Essential Testing Dependencies
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  mocktail: ^1.0.0
  bloc_test: ^9.1.0
  golden_toolkit: ^0.15.0
```

#### Useful Testing Utilities
- **mocktail:** For creating mocks and stubs
- **bloc_test:** For testing BLoC state management
- **golden_toolkit:** For golden file testing
- **patrol:** For advanced integration testing

### Debugging and Monitoring

#### Development Tools
- Use Flutter Inspector for widget debugging
- Implement logging with different levels
- Use performance profiling tools
- Monitor memory usage and frame rates

#### Production Monitoring
- Implement crash reporting (Crashlytics, Sentry)
- Add analytics for user behavior tracking
- Monitor app performance metrics
- Set up alerts for critical issues

### Security Best Practices

#### Data Protection
- Use secure storage for sensitive data
- Implement certificate pinning for network requests
- Validate all user inputs
- Follow OWASP mobile security guidelines

#### Authentication and Authorization
- Implement proper token management
- Use secure authentication flows
- Implement proper session management
- Add biometric authentication where appropriate

### Documentation Standards

#### Code Documentation
- Write clear and concise comments
- Document public APIs with dartdoc
- Maintain up-to-date README files
- Document architectural decisions

#### Test Documentation
- Document test scenarios and expected outcomes
- Maintain test plans for major features
- Document known issues and workarounds
- Keep testing guidelines updated

---

## Conclusion

Following these best practices ensures:
- **High Code Quality:** Consistent patterns and comprehensive testing
- **Maintainability:** Well-organized code that's easy to modify and extend
- **Reliability:** Robust error handling and thorough testing coverage
- **Performance:** Optimized code that provides smooth user experience
- **Security:** Protected user data and secure application behavior
- **Scalability:** Scalable architecture that can handle future growth
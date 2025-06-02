// VGV-compliant integration test utilities
// Following Very Good Ventures patterns for end-to-end testing

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:patrol/patrol.dart';

/// Utilities for integration testing following VGV patterns
class IntegrationTestHelper {
  static late IntegrationTestWidgetsFlutterBinding binding;
  static late PatrolIntegrationTester patrol;

  /// Initialize integration test environment
  static void initialize() {
    binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    patrol = PatrolIntegrationTester(binding: binding);
  }

  /// Standard setup for integration tests
  static Future<void> setUp() async {
    // Clear any existing app state
    await _clearAppState();
  }

  /// Standard teardown for integration tests
  static Future<void> tearDown() async {
    // Clean up after test
    await _clearAppState();
  }

  /// Private helper methods
  static Future<void> _clearAppState() async {
    // Reset any global state, clear storage, etc.
    await patrol.pump(const Duration(milliseconds: 100));
  }

  /// Screenshots for debugging
  static Future<void> takeScreenshot(String name) async {
    await binding.takeScreenshot(name);
  }

  /// Performance testing helpers
  static Future<void> measurePerformance(
    String testName,
    Future<void> Function() testFunction,
  ) async {
    final stopwatch = Stopwatch()..start();
    await testFunction();
    stopwatch.stop();

    print('$testName took ${stopwatch.elapsedMilliseconds}ms');
  }
}

/// Authentication flow helpers
class AuthFlow {
  /// Performs login flow
  static Future<void> login({
    required String email,
    required String password,
  }) async {
    // Navigate to login if not already there
    if (IntegrationTestHelper.patrol.tester.any(find.text('Sign In'))) {
      await IntegrationTestHelper.patrol.tap(find.text('Sign In'));
      await IntegrationTestHelper.patrol.pumpAndSettle();
    }

    // Fill email field
    await IntegrationTestHelper.patrol
        .enterText(find.byType(TextField).at(0), email);
    await IntegrationTestHelper.patrol.pumpAndSettle();

    // Fill password field
    await IntegrationTestHelper.patrol
        .enterText(find.byType(TextField).at(1), password);
    await IntegrationTestHelper.patrol.pumpAndSettle();

    // Tap login button
    await IntegrationTestHelper.patrol.tap(find.text('Login'));
    await IntegrationTestHelper.patrol.pumpAndSettle();

    // Wait for navigation to complete
    await IntegrationTestHelper.patrol.pump(const Duration(seconds: 2));
  }

  /// Performs logout flow
  static Future<void> logout() async {
    // Find and tap profile menu
    await IntegrationTestHelper.patrol.tap(find.byType(PopupMenuButton));
    await IntegrationTestHelper.patrol.pumpAndSettle();

    // Tap logout
    await IntegrationTestHelper.patrol.tap(find.text('Logout'));
    await IntegrationTestHelper.patrol.pumpAndSettle();

    // Wait for navigation to complete
    await IntegrationTestHelper.patrol.pump(const Duration(seconds: 2));
  }

  /// Performs signup flow
  static Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    // Navigate to signup
    await IntegrationTestHelper.patrol.tap(find.text('Sign Up'));
    await IntegrationTestHelper.patrol.pumpAndSettle();

    // Fill display name if provided
    if (displayName != null) {
      await IntegrationTestHelper.patrol
          .enterText(find.byType(TextField).at(0), displayName);
      await IntegrationTestHelper.patrol.pumpAndSettle();
    }

    // Fill email field
    await IntegrationTestHelper.patrol
        .enterText(find.byType(TextField).at(1), email);
    await IntegrationTestHelper.patrol.pumpAndSettle();

    // Fill password field
    await IntegrationTestHelper.patrol
        .enterText(find.byType(TextField).at(2), password);
    await IntegrationTestHelper.patrol.pumpAndSettle();

    // Tap signup button
    await IntegrationTestHelper.patrol.tap(find.text('Create Account'));
    await IntegrationTestHelper.patrol.pumpAndSettle();

    // Wait for navigation to complete
    await IntegrationTestHelper.patrol.pump(const Duration(seconds: 2));
  }

  /// Performs Google sign in flow
  static Future<void> signInWithGoogle() async {
    await IntegrationTestHelper.patrol.tap(find.text('Continue with Google'));
    await IntegrationTestHelper.patrol.pumpAndSettle();

    // Handle Google sign in flow (mock in test environment)
    await IntegrationTestHelper.patrol.pump(const Duration(seconds: 3));
  }
}

/// Navigation helpers
class NavigationHelper {
  /// Navigates to a specific page by tapping navigation elements
  static Future<void> navigateTo(String pageName) async {
    await IntegrationTestHelper.patrol.tap(find.text(pageName));
    await IntegrationTestHelper.patrol.pumpAndSettle();
  }

  /// Goes back using system back button
  static Future<void> goBack() async {
    await IntegrationTestHelper.patrol.native.pressBack();
    await IntegrationTestHelper.patrol.pumpAndSettle();
  }

  /// Verifies current page
  static void verifyCurrentPage(String expectedPageTitle) {
    expect(find.text(expectedPageTitle), findsOneWidget);
  }
}

/// Form helpers
class FormActions {
  /// Fills a form field by label
  static Future<void> fillField(String label, String value) async {
    final field = find.widgetWithText(TextField, label);
    await IntegrationTestHelper.patrol.enterText(field, value);
    await IntegrationTestHelper.patrol.pumpAndSettle();
  }

  /// Taps a button by text
  static Future<void> tapButton(String buttonText) async {
    await IntegrationTestHelper.patrol.tap(find.text(buttonText));
    await IntegrationTestHelper.patrol.pumpAndSettle();
  }

  /// Validates form field error
  static void expectFieldError(String errorMessage) {
    expect(find.text(errorMessage), findsOneWidget);
  }

  /// Validates form submission success
  static void expectFormSuccess() {
    expect(find.text('Success'), findsOneWidget);
  }
}

/// Wait helpers
class Waits {
  /// Waits for a widget to appear
  static Future<void> waitForWidget(
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await IntegrationTestHelper.patrol.waitFor(finder, timeout: timeout);
  }

  /// Waits for text to appear
  static Future<void> waitForText(
    String text, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await waitForWidget(find.text(text), timeout: timeout);
  }

  /// Waits for loading to complete
  static Future<void> waitForLoadingToComplete() async {
    await IntegrationTestHelper.patrol.waitFor(
      find.byType(CircularProgressIndicator),
      timeout: const Duration(seconds: 30),
    );
    // Wait for loading indicator to disappear
    await IntegrationTestHelper.patrol.pump(const Duration(milliseconds: 500));
  }

  /// Waits for network request to complete
  static Future<void> waitForNetworkRequest() async {
    await IntegrationTestHelper.patrol.pump(const Duration(seconds: 2));
  }
}

/// Verification helpers
class Verifications {
  /// Verifies text is present
  static void expectText(String text) {
    expect(find.text(text), findsOneWidget);
  }

  /// Verifies widget is present
  static void expectWidget(Finder finder) {
    expect(finder, findsOneWidget);
  }

  /// Verifies text is not present
  static void expectTextNotFound(String text) {
    expect(find.text(text), findsNothing);
  }

  /// Verifies widget is not present
  static void expectWidgetNotFound(Finder finder) {
    expect(finder, findsNothing);
  }

  /// Verifies snackbar message
  static void expectSnackbar(String message) {
    expect(find.text(message), findsOneWidget);
  }

  /// Verifies dialog
  static void expectDialog(String title) {
    expect(find.text(title), findsOneWidget);
  }
}

/// Mock data helpers
class MockTestData {
  static const String testEmail = 'test@example.com';
  static const String testPassword = 'testPassword123';
  static const String testDisplayName = 'Test User';

  /// Gets test user credentials
  static Map<String, String> getTestCredentials() {
    return {
      'email': testEmail,
      'password': testPassword,
      'displayName': testDisplayName,
    };
  }
}

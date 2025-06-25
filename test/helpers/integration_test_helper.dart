// VGV-compliant integration test utilities
// Following Very Good Ventures patterns for end-to-end testing

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// TODO: Enable when integration_test package is added to dependencies
// import 'package:integration_test/integration_test.dart';

/// Utilities for integration testing following VGV patterns
class IntegrationTestHelper {
  // TODO: Enable when integration_test package is added to dependencies
  // static late IntegrationTestWidgetsFlutterBinding _binding;

  /// Initialize integration test environment
  static void initialize() {
    // TODO: Enable when integration_test package is added to dependencies
    // Use the standard integration_test package binding
    // _binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  }

  /// Helper method to pump a widget for integration testing
  static Future<void> pumpApp(
    WidgetTester tester,
    Widget app, {
    Duration? timeout,
  }) async {
    await tester.pumpWidget(app);
    if (timeout != null) {
      await tester.pumpAndSettle(timeout);
    } else {
      await tester.pumpAndSettle();
    }
  }

  /// Helper method to take screenshots during integration tests
  static Future<void> takeScreenshot(
    WidgetTester tester,
    String name,
  ) async {
    // TODO: Enable when integration_test package is added to dependencies
    // await _binding.takeScreenshot(name);
  }

  /// Helper method to tap on a finder and wait for the UI to settle
  static Future<void> tapAndSettle(
    WidgetTester tester,
    Finder finder, {
    Duration? timeout,
  }) async {
    await tester.tap(finder);
    if (timeout != null) {
      await tester.pumpAndSettle(timeout);
    } else {
      await tester.pumpAndSettle();
    }
  }

  /// Helper method to enter text and wait for the UI to settle
  static Future<void> enterTextAndSettle(
    WidgetTester tester,
    Finder finder,
    String text, {
    Duration? timeout,
  }) async {
    await tester.enterText(finder, text);
    if (timeout != null) {
      await tester.pumpAndSettle(timeout);
    } else {
      await tester.pumpAndSettle();
    }
  }
}

/// Authentication flow helpers
class AuthFlow {
  /// Performs login flow
  static Future<void> login({
    required WidgetTester tester,
    required String email,
    required String password,
  }) async {
    // Navigate to login if not already there
    if (tester.any(find.text('Sign In'))) {
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();
    }

    // Fill email field
    await tester.enterText(find.byType(TextField).at(0), email);
    await tester.pumpAndSettle();

    // Fill password field
    await tester.enterText(find.byType(TextField).at(1), password);
    await tester.pumpAndSettle();

    // Tap login button
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    // Wait for navigation to complete
    await tester.pump(const Duration(seconds: 2));
  }

  /// Performs logout flow
  static Future<void> logout({required WidgetTester tester}) async {
    // Find and tap profile menu
    await tester.tap(find.byType(PopupMenuButton));
    await tester.pumpAndSettle();

    // Tap logout
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    // Wait for navigation to complete
    await tester.pump(const Duration(seconds: 2));
  }

  /// Performs signup flow
  static Future<void> signUp({
    required WidgetTester tester,
    required String email,
    required String password,
    String? displayName,
  }) async {
    // Navigate to signup
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    // Fill display name if provided
    if (displayName != null) {
      await tester.enterText(find.byType(TextField).at(0), displayName);
      await tester.pumpAndSettle();
    }

    // Fill email field
    await tester.enterText(find.byType(TextField).at(1), email);
    await tester.pumpAndSettle();

    // Fill password field
    await tester.enterText(find.byType(TextField).at(2), password);
    await tester.pumpAndSettle();

    // Tap signup button
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    // Wait for navigation to complete
    await tester.pump(const Duration(seconds: 2));
  }

  /// Performs Google sign in flow
  static Future<void> signInWithGoogle({
    required WidgetTester tester,
  }) async {
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    // Handle Google sign in flow (mock in test environment)
    await tester.pump(const Duration(seconds: 3));
  }
}

/// Navigation helpers
class NavigationHelper {
  /// Navigates to a specific page by tapping navigation elements
  static Future<void> navigateTo({
    required WidgetTester tester,
    required String pageName,
  }) async {
    await tester.tap(find.text(pageName));
    await tester.pumpAndSettle();
  }

  /// Goes back using system back button
  static Future<void> goBack({required WidgetTester tester}) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  /// Verifies current page
  static void verifyCurrentPage(String expectedPageTitle) {
    expect(find.text(expectedPageTitle), findsOneWidget);
  }
}

/// Form helpers
class FormActions {
  /// Fills a form field by label
  static Future<void> fillField({
    required WidgetTester tester,
    required String label,
    required String value,
  }) async {
    final field = find.widgetWithText(TextField, label);
    await tester.enterText(field, value);
    await tester.pumpAndSettle();
  }

  /// Taps a button by text
  static Future<void> tapButton({
    required WidgetTester tester,
    required String buttonText,
  }) async {
    await tester.tap(find.text(buttonText));
    await tester.pumpAndSettle();
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
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final end = tester.binding.clock.now().add(timeout);
    var found = false;
    while (tester.binding.clock.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100)); // Pump frequently
      if (tester.any(finder)) {
        found = true;
        break;
      }
    }
    if (!found) {
      // Try one last pumpAndSettle before failing
      await tester.pumpAndSettle();
      if (!tester.any(finder)) {
        throw Exception('Widget $finder not found within $timeout');
      }
    }
    await tester.pumpAndSettle(); // Ensure UI is stable if found
  }

  /// Waits for text to appear
  static Future<void> waitForText(
    WidgetTester tester,
    String text, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await waitForWidget(tester, find.text(text), timeout: timeout);
  }

  /// Waits for loading to complete
  static Future<void> waitForLoadingToComplete({
    required WidgetTester tester,
    Duration appearTimeout = const Duration(seconds: 5),
    Duration disappearTimeout = const Duration(seconds: 30),
  }) async {
    var appeared = false;
    final appearEnd = tester.binding.clock.now().add(appearTimeout);
    // 1. Wait for it to exist
    do {
      if (tester.binding.clock.now().isAfter(appearEnd)) {
        // It's okay if it doesn't appear, maybe loading was too fast
        break;
      }
      await tester.pump(const Duration(milliseconds: 100));
      if (tester.any(find.byType(CircularProgressIndicator))) {
        appeared = true;
        break;
      }
    } while (true);

    if (appeared) {
      // 2. Wait for it to disappear
      final disappearEnd = tester.binding.clock.now().add(disappearTimeout);
      do {
        if (tester.binding.clock.now().isAfter(disappearEnd)) {
          throw Exception(
            'CircularProgressIndicator did not disappear within $disappearTimeout',
          );
        }
        await tester.pump(const Duration(milliseconds: 100));
      } while (tester.any(find.byType(CircularProgressIndicator)) == true);
    }
    await tester.pumpAndSettle(); // Final settle
  }

  /// Waits for network request to complete
  static Future<void> waitForNetworkRequest({
    required WidgetTester tester,
  }) async {
    await tester.pump(const Duration(seconds: 2));
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

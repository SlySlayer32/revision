import 'package:flutter_test/flutter_test.dart';

import 'firebase_emulator_helper.dart';

/// Test script to demonstrate creating and using Firebase Auth emulator credentials
/// Run this with: flutter test test/helpers/test_credentials_demo.dart
void main() {
  group('Firebase Emulator Credentials Demo', () {
    setUpAll(() async {
      // Setup the complete testing environment
      await FirebaseEmulatorHelper.setupTestEnvironment();
    });

    tearDownAll(() async {
      // Clean up after tests
      await FirebaseEmulatorHelper.teardownTestEnvironment();
    });

    test('should create and use test credentials', () async {
      // Get the predefined test credentials
      final credentials = FirebaseEmulatorHelper.getTestCredentials();

      // Test signing in with the first set of credentials
      final testEmail = credentials.first['email']!;
      final testPassword = credentials.first['password']!;

      final user = await FirebaseEmulatorHelper.signInTestUser(
        email: testEmail,
        password: testPassword,
      );

      expect(user, isNotNull);
      expect(user!.email, equals(testEmail));
    });

    test('should create a new custom test user', () async {
      const customEmail = 'custom@test.com';
      const customPassword = 'custom123';
      const customName = 'Custom Test User';

      final user = await FirebaseEmulatorHelper.createTestUser(
        email: customEmail,
        password: customPassword,
        displayName: customName,
      );

      expect(user, isNotNull);
      expect(user!.email, equals(customEmail));
      expect(user.displayName, equals(customName));
    });

    test('should handle invalid credentials gracefully', () async {
      final user = await FirebaseEmulatorHelper.signInTestUser(
        email: 'invalid@test.com',
        password: 'wrongpassword',
      );

      expect(user, isNull);
    });
  });
}

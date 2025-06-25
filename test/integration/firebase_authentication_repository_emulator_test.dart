// Firebase Authentication Repository Integration Tests
// Tests with Firebase Emulator - requires Firebase emulator to be running

import 'dart:developer';

import 'package:flutter_test/flutter_test.dart';
import 'package:revision/features/authentication/data/repositories/firebase_authentication_repository.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';

import '../helpers/firebase_emulator_helper.dart';
import '../helpers/firebase_test_helper.dart';
import '../helpers/helpers.dart';

void main() {
  group('FirebaseAuthenticationRepository - Integration Tests', () {
    late FirebaseAuthenticationRepository repository;

    setUpAll(() async {
      try {
        await FirebaseTestHelper.setupFirebaseForTesting();
        await FirebaseEmulatorHelper.initializeForTesting();
        log('✅ Firebase emulator initialized for integration tests');
      } catch (e) {
        log('⚠️ Firebase emulator setup failed: $e');
        log('Continuing with tests - they may fail if emulator is not running');
      }
    });

    setUp(() {
      repository = FirebaseAuthenticationRepository();
    });

    group('signUpWithEmailAndPassword - Integration Tests', () {
      const testEmail = 'integration.test@example.com';
      const testPassword = 'password123';

      test('should successfully sign up user', () async {
        // Act
        final result = await repository.signUpWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected success, got failure: $failure'),
          (user) {
            expect(user.email, equals(testEmail));
            expect(user.id, isNotEmpty);
            log('✅ Created user: ${user.email}');
          },
        );

        // Cleanup
        await repository.signOut();
      });

      test('should fail with invalid email', () async {
        // Act
        final result = await repository.signUpWithEmailAndPassword(
          email: 'invalid-email',
          password: testPassword,
        );

        // Assert
        expect(result.isLeft(), isTrue);
      });
    });

    group('signInWithEmailAndPassword - Integration Tests', () {
      const testEmail = 'signin.integration@example.com';
      const testPassword = 'password123';

      test('should successfully sign in existing user', () async {
        // Arrange - Create user first
        await repository.signUpWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        );
        await repository.signOut();

        // Act - Sign in
        final result = await repository.signInWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected success, got failure: $failure'),
          (user) {
            expect(user.email, equals(testEmail));
            expect(user.id, isNotEmpty);
            log('✅ Signed in user: ${user.email}');
          },
        );

        // Cleanup
        await repository.signOut();
      });

      test('should fail with invalid credentials', () async {
        // Act
        final result = await repository.signInWithEmailAndPassword(
          email: testEmail,
          password: 'wrongpassword',
        );

        // Assert
        expect(result.isLeft(), isTrue);
      });
    });

    group('getCurrentUser - Integration Tests', () {
      const testEmail = 'currentuser.integration@example.com';
      const testPassword = 'password123';

      test('should return current user when signed in', () async {
        // Arrange - Create and sign in user
        await repository.signUpWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        );

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected success, got failure: $failure'),
          (user) {
            expect(user?.email, equals(testEmail));
            log('✅ Got current user: ${user?.email}');
          },
        );

        // Cleanup
        await repository.signOut();
      });

      test('should return null when no user signed in', () async {
        // Arrange
        await repository.signOut();

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected success, got failure: $failure'),
          (user) => expect(user, isNull),
        );
      });
    });

    group('signOut - Integration Tests', () {
      const testEmail = 'signout.integration@example.com';
      const testPassword = 'password123';

      test('should successfully sign out user', () async {
        // Arrange - Create and sign in user
        await repository.signUpWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        );

        // Act
        final result = await repository.signOut();

        // Assert
        expect(result.isRight(), isTrue);

        // Verify user is signed out
        final currentUserResult = await repository.getCurrentUser();
        currentUserResult.fold(
          (failure) => fail('Expected success checking current user'),
          (user) => expect(user, isNull),
        );
      });
    });

    group('sendPasswordResetEmail - Integration Tests', () {
      const testEmail = 'reset.integration@example.com';
      const testPassword = 'password123';

      test('should successfully send password reset email', () async {
        // Arrange - Create user first
        await repository.signUpWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        );
        await repository.signOut();

        // Act
        final result = await repository.sendPasswordResetEmail(
          email: testEmail,
        );

        // Assert
        expect(result.isRight(), isTrue);
        log('✅ Password reset email sent to: $testEmail');
      });

      test('should handle non-existent user gracefully', () async {
        // Act
        final result = await repository.sendPasswordResetEmail(
          email: 'nonexistent@example.com',
        );

        // Assert - Firebase typically succeeds even for non-existent emails
        expect(result.isRight(), isTrue);
      });
    });

    group('authStateChanges - Integration Tests', () {
      const testEmail = 'authstate.integration@example.com';
      const testPassword = 'password123';

      test('should emit auth state changes', () async {
        // Arrange
        final authStream = repository.authStateChanges;
        final states = <User?>[];

        // Listen to auth state changes
        final subscription = authStream.listen(states.add);

        // Act - Sign up user
        await repository.signUpWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        );

        // Wait for state change
        await Future<void>.delayed(const Duration(milliseconds: 500));

        // Act - Sign out
        await repository.signOut();

        // Wait for state change
        await Future<void>.delayed(const Duration(milliseconds: 500));

        // Cleanup
        await subscription.cancel();

        // Assert
        expect(states.length, greaterThanOrEqualTo(2));
        log('✅ Auth state changes detected: ${states.length} states');
      });
    });
  });
}

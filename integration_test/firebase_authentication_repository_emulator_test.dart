// Firebase Authentication Repository Emulator Integration Tests
// VGV-compliant integration tests running on real device/emulator
// Tests Firebase Auth functionality against the emulator

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:revision/core/error/failures.dart';
import 'package:revision/features/authentication/data/datasources/firebase_auth_data_source.dart';
import 'package:revision/features/authentication/data/repositories/firebase_authentication_repository.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';

import '../test/helpers/firebase_emulator_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('FirebaseAuthenticationRepository - Emulator Integration Tests', () {
    late FirebaseAuthenticationRepository repository;
    late FirebaseAuthDataSource dataSource;

    setUpAll(() async {
      print('🔥 Initializing Firebase emulator for integration tests...');
      try {
        await FirebaseEmulatorHelper.initializeForTesting();
        print('✅ Firebase emulator initialized successfully');
      } catch (e) {
        print('❌ Firebase emulator initialization failed: $e');
        print('💡 Make sure Firebase emulators are running:');
        print('   firebase emulators:start --only auth');
        print('   Or run the VS Code task: "Start Firebase Emulators"');
        rethrow;
      }
    });

    setUp(() async {
      // Create real data source (will connect to emulator)
      dataSource = FirebaseAuthDataSourceImpl();
      repository = FirebaseAuthenticationRepository(
        firebaseAuthDataSource: dataSource,
      );

      // Clear any existing auth state
      await FirebaseEmulatorHelper.clearAuthData();
      print('🧹 Cleared auth data for test');
    });

    tearDown(() async {
      // Clean up after each test
      await FirebaseEmulatorHelper.clearAuthData();
    });

    group('signUpWithEmailAndPassword - Real Emulator Tests', () {
      const testEmail = 'integration.test@example.com';
      const testPassword = 'password123';

      test('should successfully create new user in emulator', () async {
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
            print('✅ Created user: ${user.email} with ID: ${user.id}');
          },
        );
      });

      test('should fail when email already exists', () async {
        // Arrange - Create user first
        await repository.signUpWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        );

        // Act - Try to create same user again
        final result = await repository.signUpWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<AuthenticationFailure>()),
          (_) => fail('Expected failure for duplicate email'),
        );
      });
    });

    group('signInWithEmailAndPassword - Real Emulator Tests', () {
      const testEmail = 'signin.test@example.com';
      const testPassword = 'password123';

      test('should successfully sign in existing user', () async {
        // Arrange - Create user first
        await repository.signUpWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        );

        // Sign out first
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
            print('✅ Signed in user: ${user.email}');
          },
        );
      });

      test('should fail with invalid credentials', () async {
        // Act
        final result = await repository.signInWithEmailAndPassword(
          email: 'nonexistent@example.com',
          password: 'wrongpassword',
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<AuthenticationFailure>()),
          (_) => fail('Expected failure for invalid credentials'),
        );
      });
    });

    group('getCurrentUser - Real Emulator Tests', () {
      const testEmail = 'currentuser.test@example.com';
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
            expect(user, isNotNull);
            expect(user!.email, equals(testEmail));
            print('✅ Current user: ${user.email}');
          },
        );
      });

      test('should return null when no user signed in', () async {
        // Arrange - Ensure no user is signed in
        await repository.signOut();

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected success, got failure: $failure'),
          (user) {
            expect(user, isNull);
            print('✅ No current user (as expected)');
          },
        );
      });
    });

    group('signOut - Real Emulator Tests', () {
      const testEmail = 'signout.test@example.com';
      const testPassword = 'password123';

      test('should successfully sign out user', () async {
        // Arrange - Create and sign in user
        await repository.signUpWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        );

        // Verify user is signed in
        final userBefore = await repository.getCurrentUser();
        expect(userBefore.isRight(), isTrue);

        // Act
        final result = await repository.signOut();

        // Assert
        expect(result.isRight(), isTrue);

        // Verify user is signed out
        final userAfter = await repository.getCurrentUser();
        userAfter.fold(
          (failure) => fail('Expected success, got failure: $failure'),
          (user) {
            expect(user, isNull);
            print('✅ User successfully signed out');
          },
        );
      });
    });

    group('sendPasswordResetEmail - Real Emulator Tests', () {
      const testEmail = 'reset.test@example.com';
      const testPassword = 'password123';

      test('should successfully send password reset email', () async {
        // Arrange - Create user first
        await repository.signUpWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        );

        // Act
        final result = await repository.sendPasswordResetEmail(
          email: testEmail,
        );

        // Assert
        expect(result.isRight(), isTrue);
        print('✅ Password reset email sent to: $testEmail');
      });

      test('should handle non-existent user gracefully', () async {
        // Act
        final result = await repository.sendPasswordResetEmail(
          email: 'nonexistent@example.com',
        );

        // Assert - Firebase Auth typically succeeds even for non-existent emails
        // for security reasons (to not reveal which emails are registered)
        expect(result.isRight(), isTrue);
        print('✅ Password reset handled for non-existent user');
      });
    });

    group('authStateChanges - Real Emulator Tests', () {
      const testEmail = 'authstate.test@example.com';
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

        // Act - Sign out user
        await repository.signOut();

        // Wait for state change
        await Future<void>.delayed(const Duration(milliseconds: 500));

        // Clean up
        await subscription.cancel();

        // Assert
        expect(states.length, greaterThanOrEqualTo(2));
        expect(states.any((user) => user?.email == testEmail), isTrue);
        expect(states.any((user) => user == null), isTrue);
        print('✅ Auth state changes detected: ${states.length} states');
      });
    });
  });
}

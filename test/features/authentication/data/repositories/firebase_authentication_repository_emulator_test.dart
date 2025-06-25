// Firebase Authentication Repository Emulator Integration Tests
// Tests against Firebase Auth Emulator for real authentication flow validation

import 'package:flutter_test/flutter_test.dart';
import 'package:revision/features/authentication/data/datasources/firebase_auth_data_source.dart';
import 'package:revision/features/authentication/data/repositories/firebase_authentication_repository.dart';

import '../../../../helpers/helpers.dart';

void main() {
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
      const testEmail = 'newuser@example.com';
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
          (failure) => fail('Should not return failure: $failure'),
          (user) {
            expect(user.email, equals(testEmail));
            expect(user.id, isNotEmpty);
            expect(user.isEmailVerified, isFalse);
            print('✅ Created user: ${user.email} with ID: ${user.id}');
          },
        );
      });

      test('should return failure when email already exists', () async {
        // Arrange - Create a user first
        await FirebaseEmulatorHelper.createTestUser(
          email: testEmail,
          password: testPassword,
        );

        // Act - Try to create the same user again
        final result = await repository.signUpWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure.message, contains('already'));
            print('✅ Correctly detected duplicate email: ${failure.message}');
          },
          (_) => fail('Should return failure for duplicate email'),
        );
      });

      test('should return failure for invalid email format', () async {
        // Act
        final result = await repository.signUpWithEmailAndPassword(
          email: 'invalid-email',
          password: testPassword,
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure.message.toLowerCase(), contains('email'));
            print('✅ Correctly rejected invalid email: ${failure.message}');
          },
          (_) => fail('Should return failure for invalid email'),
        );
      });

      test('should return failure for weak password', () async {
        // Act
        final result = await repository.signUpWithEmailAndPassword(
          email: testEmail,
          password: '123', // Too weak
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure.message.toLowerCase(), contains('password'));
            print('✅ Correctly rejected weak password: ${failure.message}');
          },
          (_) => fail('Should return failure for weak password'),
        );
      });
    });

    group('signInWithEmailAndPassword - Real Emulator Tests', () {
      const testEmail = 'signin@example.com';
      const testPassword = 'password123';

      test('should successfully sign in with valid credentials', () async {
        // Arrange - Create a test user first
        final userCreated = await FirebaseEmulatorHelper.createTestUser(
          email: testEmail,
          password: testPassword,
          displayName: 'Test User',
        );
        expect(userCreated, isTrue, reason: 'Failed to create test user');

        // Act - Sign in with the created user
        final result = await repository.signInWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Should not return failure: $failure'),
          (user) {
            expect(user.email, equals(testEmail));
            expect(user.id, isNotEmpty);
            print('✅ Successfully signed in: ${user.email}');
          },
        );
      });

      test('should return failure for non-existent user', () async {
        // Act - Try to sign in with non-existent user
        final result = await repository.signInWithEmailAndPassword(
          email: 'nonexistent@example.com',
          password: 'wrongpassword',
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            print('✅ Correctly rejected non-existent user: ${failure.message}');
          },
          (_) => fail('Should return failure for non-existent user'),
        );
      });

      test('should return failure for wrong password', () async {
        // Arrange - Create a test user
        await FirebaseEmulatorHelper.createTestUser(
          email: testEmail,
          password: testPassword,
        );

        // Act - Try to sign in with wrong password
        final result = await repository.signInWithEmailAndPassword(
          email: testEmail,
          password: 'wrongpassword',
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            print('✅ Correctly rejected wrong password: ${failure.message}');
          },
          (_) => fail('Should return failure for wrong password'),
        );
      });
    });

    group('Emulator Health Check', () {
      test('should verify emulator is properly configured', () async {
        // This test verifies the emulator is working correctly
        // by performing a complete authentication flow

        const testEmail = 'health@example.com';
        const testPassword = 'password123';

        print('🏥 Running emulator health check...');

        // 1. Create user
        final signUpResult = await repository.signUpWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        );
        expect(
          signUpResult.isRight(),
          isTrue,
          reason: 'Should be able to create user',
        );

        // 2. Sign out
        await repository.signOut();

        // 3. Sign in
        final signInResult = await repository.signInWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        );
        expect(
          signInResult.isRight(),
          isTrue,
          reason: 'Should be able to sign in',
        );

        // 4. Get current user
        final getCurrentResult = await repository.getCurrentUser();
        expect(
          getCurrentResult.isRight(),
          isTrue,
          reason: 'Should be able to get current user',
        );

        // 5. Sign out again
        final signOutResult = await repository.signOut();
        expect(
          signOutResult.isRight(),
          isTrue,
          reason: 'Should be able to sign out',
        );

        print('✅ Emulator health check passed - all operations working');
      });
    });
  });
}

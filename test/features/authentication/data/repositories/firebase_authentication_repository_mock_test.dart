import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/core/error/failures.dart';
import 'package:revision/features/authentication/data/datasources/firebase_auth_data_source.dart';
import 'package:revision/features/authentication/data/repositories/firebase_authentication_repository.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/exceptions/auth_exception.dart';

// Mock class
class MockFirebaseAuthDataSource extends Mock
    implements FirebaseAuthDataSource {}

// Test data
class TestData {
  static const testEmail = 'test@example.com';
  static const testPassword = 'password123';
  static const testUser = User(
    id: 'test-user-id',
    email: testEmail,
    displayName: 'Test User',
    photoUrl: null,
    isEmailVerified: false,
    createdAt: '2024-01-01T00:00:00Z',
    customClaims: {},
  );
}

void main() {
  group('FirebaseAuthenticationRepository - Mock Tests', () {
    late FirebaseAuthenticationRepository repository;
    late MockFirebaseAuthDataSource mockDataSource;

    setUp(() {
      mockDataSource = MockFirebaseAuthDataSource();
      repository = FirebaseAuthenticationRepository(
        firebaseAuthDataSource: mockDataSource,
      );
    });

    tearDown(() {
      reset(mockDataSource);
    });

    group('signUpWithEmailAndPassword', () {
      test('should return success when sign up succeeds', () async {
        // Arrange
        when(
          () => mockDataSource.signUp(
            email: TestData.testEmail,
            password: TestData.testPassword,
          ),
        ).thenAnswer((_) async => TestData.testUser);

        // Act
        final result = await repository.signUpWithEmailAndPassword(
          email: TestData.testEmail,
          password: TestData.testPassword,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected success, got failure: $failure'),
          (user) {
            expect(user.email, equals(TestData.testEmail));
            expect(user.id, equals('test-user-id'));
          },
        );
        verify(
          () => mockDataSource.signUp(
            email: TestData.testEmail,
            password: TestData.testPassword,
          ),
        ).called(1);
      });

      test('should return failure when email already in use', () async {
        // Arrange
        when(
          () => mockDataSource.signUp(
            email: TestData.testEmail,
            password: TestData.testPassword,
          ),
        ).thenThrow(const EmailAlreadyInUseException());

        // Act
        final result = await repository.signUpWithEmailAndPassword(
          email: TestData.testEmail,
          password: TestData.testPassword,
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<AuthenticationFailure>()),
          (_) => fail('Expected failure'),
        );
      });

      test('should return failure when password is weak', () async {
        // Arrange
        when(
          () => mockDataSource.signUp(
            email: TestData.testEmail,
            password: 'weak',
          ),
        ).thenThrow(const WeakPasswordException());

        // Act
        final result = await repository.signUpWithEmailAndPassword(
          email: TestData.testEmail,
          password: 'weak',
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<AuthenticationFailure>()),
          (_) => fail('Expected failure'),
        );
      });
    });

    group('signInWithEmailAndPassword', () {
      test('should return success when sign in succeeds', () async {
        // Arrange
        when(
          () => mockDataSource.signIn(
            email: TestData.testEmail,
            password: TestData.testPassword,
          ),
        ).thenAnswer((_) async => TestData.testUser);

        // Act
        final result = await repository.signInWithEmailAndPassword(
          email: TestData.testEmail,
          password: TestData.testPassword,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected success, got failure: $failure'),
          (user) => expect(user.email, equals(TestData.testEmail)),
        );
      });

      test('should return failure when credentials are invalid', () async {
        // Arrange
        when(
          () => mockDataSource.signIn(
            email: TestData.testEmail,
            password: 'wrong-password',
          ),
        ).thenThrow(const InvalidCredentialsException());

        // Act
        final result = await repository.signInWithEmailAndPassword(
          email: TestData.testEmail,
          password: 'wrong-password',
        );

        // Assert
        expect(result.isLeft(), isTrue);
      });
    });

    group('signInWithGoogle', () {
      test('should return success when Google sign in succeeds', () async {
        // Arrange
        when(() => mockDataSource.signInWithGoogle())
            .thenAnswer((_) async => TestData.testUser);

        // Act
        final result = await repository.signInWithGoogle();

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockDataSource.signInWithGoogle()).called(1);
      });

      test('should return failure when Google sign in fails', () async {
        // Arrange
        when(() => mockDataSource.signInWithGoogle())
            .thenThrow(const UnexpectedAuthException('Google sign in failed'));

        // Act
        final result = await repository.signInWithGoogle();

        // Assert
        expect(result.isLeft(), isTrue);
      });
    });

    group('signOut', () {
      test('should return success when sign out succeeds', () async {
        // Arrange
        when(() => mockDataSource.signOut()).thenAnswer((_) async {});

        // Act
        final result = await repository.signOut();

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockDataSource.signOut()).called(1);
      });

      test('should return failure when sign out fails', () async {
        // Arrange
        when(() => mockDataSource.signOut())
            .thenThrow(const UnexpectedAuthException('Sign out failed'));

        // Act
        final result = await repository.signOut();

        // Assert
        expect(result.isLeft(), isTrue);
      });
    });

    group('sendPasswordResetEmail', () {
      test('should return success when password reset email is sent', () async {
        // Arrange
        when(() => mockDataSource.sendPasswordResetEmail(TestData.testEmail))
            .thenAnswer((_) async {});

        // Act
        final result =
            await repository.sendPasswordResetEmail(email: TestData.testEmail);

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockDataSource.sendPasswordResetEmail(TestData.testEmail))
            .called(1);
      });

      test('should return failure when user not found', () async {
        // Arrange
        when(() => mockDataSource.sendPasswordResetEmail('unknown@example.com'))
            .thenThrow(const UserNotFoundException());

        // Act
        final result = await repository.sendPasswordResetEmail(
            email: 'unknown@example.com');

        // Assert
        expect(result.isLeft(), isTrue);
      });
    });

    group('getCurrentUser', () {
      test('should return current user when user is signed in', () async {
        // Arrange
        when(() => mockDataSource.currentUser).thenReturn(TestData.testUser);

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected success, got failure: $failure'),
          (user) => expect(user?.email, equals(TestData.testEmail)),
        );
      });

      test('should return null when no user is signed in', () async {
        // Arrange
        when(() => mockDataSource.currentUser).thenReturn(null);

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

    group('authStateChanges', () {
      test('should return auth state changes stream', () async {
        // Arrange
        final userStream = Stream<User?>.fromIterable([
          null,
          TestData.testUser,
          null,
        ]);
        when(() => mockDataSource.authStateChanges)
            .thenAnswer((_) => userStream);

        // Act
        final stream = repository.authStateChanges;
        final states = await stream.take(3).toList();

        // Assert
        expect(states.length, equals(3));
        expect(states[0], isNull);
        expect(states[1]?.email, equals(TestData.testEmail));
        expect(states[2], isNull);
        verify(() => mockDataSource.authStateChanges).called(1);
      });

      test('should emit user changes', () async {
        // Arrange
        final controller = StreamController<User?>();
        when(() => mockDataSource.authStateChanges)
            .thenAnswer((_) => controller.stream);

        // Act
        final stream = repository.authStateChanges;

        // Assert
        expectLater(
          stream,
          emitsInOrder([
            null,
            TestData.testUser,
            emitsDone,
          ]),
        );

        controller.add(null);
        controller.add(TestData.testUser);
        await controller.close();
      });
    });

    group('Error Recovery', () {
      test('should handle network timeouts', () async {
        // Arrange
        when(
          () => mockDataSource.signIn(
            email: TestData.testEmail,
            password: TestData.testPassword,
          ),
        ).thenThrow(
          TimeoutException('Network timeout', const Duration(seconds: 30)),
        );

        // Act
        final result = await repository.signInWithEmailAndPassword(
          email: TestData.testEmail,
          password: TestData.testPassword,
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<AuthenticationFailure>()),
          (_) => fail('Expected failure'),
        );
      });

      test('should handle concurrent requests', () async {
        // Arrange
        when(
          () => mockDataSource.signIn(
            email: TestData.testEmail,
            password: TestData.testPassword,
          ),
        ).thenAnswer((_) async => TestData.testUser);

        // Act
        final futures = List.generate(
          3,
          (_) => repository.signInWithEmailAndPassword(
            email: TestData.testEmail,
            password: TestData.testPassword,
          ),
        );
        final results = await Future.wait(futures);

        // Assert
        for (final result in results) {
          expect(result.isRight(), isTrue);
        }
        verify(
          () => mockDataSource.signIn(
            email: TestData.testEmail,
            password: TestData.testPassword,
          ),
        ).called(3);
      });
    });

    group('Edge Cases', () {
      test('should handle empty credentials', () async {
        // Arrange
        when(
          () => mockDataSource.signIn(email: '', password: ''),
        ).thenThrow(const InvalidEmailException());

        // Act
        final result = await repository.signInWithEmailAndPassword(
          email: '',
          password: '',
        );

        // Assert
        expect(result.isLeft(), isTrue);
      });

      test('should handle special characters in credentials', () async {
        // Arrange
        const specialEmail = 'test+special@example.com';
        const specialPassword = r'Pass@#$%^&*()123!';
        const specialUser = User(
          id: 'special-user-id',
          email: specialEmail,
          displayName: 'Special User',
          photoUrl: null,
          isEmailVerified: true,
          createdAt: '2024-01-01T00:00:00Z',
          customClaims: {},
        );

        when(
          () => mockDataSource.signIn(
            email: specialEmail,
            password: specialPassword,
          ),
        ).thenAnswer((_) async => specialUser);

        // Act
        final result = await repository.signInWithEmailAndPassword(
          email: specialEmail,
          password: specialPassword,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected success, got failure: $failure'),
          (user) => expect(user.email, equals(specialEmail)),
        );
      });
    });
  });
}

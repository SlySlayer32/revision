import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/core/error/failures.dart';
import 'package:revision/features/authentication/data/datasources/firebase_auth_data_source.dart';
import 'package:revision/features/authentication/data/repositories/firebase_authentication_repository.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/exceptions/auth_exception.dart';
import '../../../../helpers/helpers.dart'; // Import the helper

class MockFirebaseAuthDataSource extends Mock
    implements FirebaseAuthDataSource {}

void main() {
  // Ensure Firebase is initialized before tests run
  setUpAll(() async {
    await setupFirebaseAuthMocks();
  });

  group('FirebaseAuthenticationRepository', () {
    late FirebaseAuthenticationRepository repository;
    late MockFirebaseAuthDataSource mockDataSource;
    late StreamController<User?> authStateController;

    setUp(() {
      mockDataSource = MockFirebaseAuthDataSource();
      repository = FirebaseAuthenticationRepository(
        firebaseAuthDataSource: mockDataSource,
      );
      authStateController = StreamController<User?>();
    });

    tearDown(() {
      authStateController.close();
    });

    const email = 'test@example.com';
    const password = 'password123';
    const user = User(
      id: '1',
      email: email,
      displayName: 'Test User',
      photoUrl: null,
      isEmailVerified: false,
      createdAt: '2023-01-01T12:00:00Z',
      customClaims: {},
    );

    group('signIn', () {
      test('should return success when sign in succeeds', () async {
        // Arrange
        when(
          () => mockDataSource.signIn(
            email: email,
            password: password,
          ),
        ).thenAnswer((_) async => user);

        // Act
        final result = await repository.signIn(
          email: email,
          password: password,
        );

        // Assert
        expect(result, equals(Success(user)));
        verify(
          () => mockDataSource.signIn(
            email: email,
            password: password,
          ),
        ).called(1);
      });

      test('should return failure when invalid credentials exception occurs',
          () async {
        // Arrange
        const exception = InvalidCredentialsException();
        when(
          () => mockDataSource.signIn(
            email: email,
            password: password,
          ),
        ).thenThrow(exception);

        // Act
        final result = await repository.signIn(
          email: email,
          password: password,
        );

        // Assert
        expect(result, equals(const Failure<User>(exception)));
      });

      test('should return failure when unexpected error occurs', () async {
        // Arrange
        when(
          () => mockDataSource.signIn(
            email: email,
            password: password,
          ),
        ).thenThrow(Exception('Unexpected error'));

        // Act
        final result = await repository.signIn(
          email: email,
          password: password,
        ); // Assert
        expect(result, isA<Failure<User>>());
        expect(
          result.fold<Exception>(
            success: (user) => throw Exception('Expected failure'),
            failure: (exception) => exception,
          ),
          isA<UnexpectedAuthException>(),
        );
      });
    });

    group('signInWithGoogle', () {
      test('should return success when Google sign in succeeds', () async {
        // Arrange
        when(() => mockDataSource.signInWithGoogle())
            .thenAnswer((_) async => user);

        // Act
        final result = await repository.signInWithGoogle();

        // Assert
        expect(result, equals(Success(user)));
        verify(() => mockDataSource.signInWithGoogle()).called(1);
      });

      test('should return failure when Google sign in fails', () async {
        // Arrange
        const exception = UnexpectedAuthException('Google sign in failed');
        when(() => mockDataSource.signInWithGoogle()).thenThrow(exception);

        // Act
        final result = await repository.signInWithGoogle();

        // Assert
        expect(result, equals(const Failure<User>(exception)));
      });
    });

    group('signUp', () {
      test('should return success when sign up succeeds', () async {
        // Arrange
        when(
          () => mockDataSource.signUp(
            email: email,
            password: password,
          ),
        ).thenAnswer((_) async => user);

        // Act
        final result = await repository.signUp(
          email: email,
          password: password,
        );

        // Assert
        expect(result, equals(Success(user)));
        verify(
          () => mockDataSource.signUp(
            email: email,
            password: password,
          ),
        ).called(1);
      });

      test('should return failure when email already in use', () async {
        // Arrange
        const exception = EmailAlreadyInUseException();
        when(
          () => mockDataSource.signUp(
            email: email,
            password: password,
          ),
        ).thenThrow(exception);

        // Act
        final result = await repository.signUp(
          email: email,
          password: password,
        ); // Assert
        expect(result, equals(const Failure<User>(exception)));
      });

      test('should return failure when password is weak', () async {
        // Arrange
        const exception = WeakPasswordException();
        when(
          () => mockDataSource.signUp(
            email: email,
            password: password,
          ),
        ).thenThrow(exception);

        // Act
        final result = await repository.signUp(
          email: email,
          password: password,
        ); // Assert
        expect(result, equals(const Failure<User>(exception)));
      });
    });

    group('signOut', () {
      test('should return success when sign out succeeds', () async {
        // Arrange
        when(() => mockDataSource.signOut()).thenAnswer((_) async {});

        // Act
        final result = await repository.signOut();

        // Assert
        expect(result, equals(const Success(null)));
        verify(() => mockDataSource.signOut()).called(1);
      });

      test('should return failure when sign out fails', () async {
        // Arrange
        const exception = UnexpectedAuthException('Sign out failed');
        when(() => mockDataSource.signOut()).thenThrow(exception); // Act
        final result = await repository.signOut();

        // Assert
        expect(result, equals(const Failure<void>(exception)));
      });
    });

    group('sendPasswordResetEmail', () {
      test('should return success when password reset email is sent', () async {
        // Arrange
        when(() => mockDataSource.sendPasswordResetEmail(email))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.sendPasswordResetEmail(email);

        // Assert
        expect(result, equals(const Success(null)));
        verify(() => mockDataSource.sendPasswordResetEmail(email)).called(1);
      });

      test('should return failure when user not found', () async {
        // Arrange
        const exception = UserNotFoundException();
        when(() => mockDataSource.sendPasswordResetEmail(email))
            .thenThrow(exception); // Act
        final result = await repository.sendPasswordResetEmail(email);

        // Assert
        expect(result, equals(const Failure<void>(exception)));
      });
    });

    group('currentUser', () {
      test('should return current user from data source', () {
        // Arrange
        when(() => mockDataSource.currentUser).thenReturn(user);

        // Act
        final result = repository.currentUser;

        // Assert
        expect(result, equals(user));
        verify(() => mockDataSource.currentUser).called(1);
      });

      test('should return null when no current user', () {
        // Arrange
        when(() => mockDataSource.currentUser).thenReturn(null);

        // Act
        final result = repository.currentUser;

        // Assert
        expect(result, isNull);
        verify(() => mockDataSource.currentUser).called(1);
      });
    });

    group('authStateChanges', () {
      test('should return auth state changes stream from data source', () {
        // Arrange
        when(() => mockDataSource.authStateChanges)
            .thenAnswer((_) => authStateController.stream);

        // Act
        final stream = repository.authStateChanges;

        // Assert
        expect(stream, equals(authStateController.stream));
        verify(() => mockDataSource.authStateChanges).called(1);
      });

      test('should emit user when user signs in', () async {
        // Arrange
        when(() => mockDataSource.authStateChanges)
            .thenAnswer((_) => authStateController.stream);

        // Act
        final stream = repository.authStateChanges;
        authStateController.add(user);

        // Assert
        await expectLater(stream, emits(user));
      });

      test('should emit null when user signs out', () async {
        // Arrange
        when(() => mockDataSource.authStateChanges)
            .thenAnswer((_) => authStateController.stream);

        // Act
        final stream = repository.authStateChanges;
        authStateController.add(null);

        // Assert
        await expectLater(stream, emits(null));
      });
    });
  });
}

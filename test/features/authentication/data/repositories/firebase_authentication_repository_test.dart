import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/core/error/failures.dart';
import 'package:revision/features/authentication/data/datasources/firebase_auth_data_source.dart';
import 'package:revision/features/authentication/data/repositories/firebase_authentication_repository.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/exceptions/auth_exception.dart';

import '../../../../helpers/helpers.dart';

class MockFirebaseAuthDataSource extends Mock
    implements FirebaseAuthDataSource {}

void main() {
  setUpAll(() async {
    try {
      await setupFirebaseAuthMocks();
    } catch (e) {
      print('Firebase mock setup failed: $e (continuing with tests)');
    }
  });

  group('FirebaseAuthenticationRepository - Unit Tests', () {
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
      customClaims: <String, dynamic>{},
    );

    group('signInWithEmailAndPassword', () {
      test('should return success when sign in succeeds', () async {
        // Arrange
        when(
          () => mockDataSource.signIn(
            email: email,
            password: password,
          ),
        ).thenAnswer((_) async => user);

        // Act
        final result = await repository.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Assert
        expect(result, equals(const Right<Failure, User>(user)));
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
        final result = await repository.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<AuthenticationFailure>()),
          (_) => fail('Should return failure'),
        );
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
        final result = await repository.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<AuthenticationFailure>()),
          (_) => fail('Should return failure'),
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
        expect(result, equals(const Right<Failure, User>(user)));
        verify(() => mockDataSource.signInWithGoogle()).called(1);
      });

      test('should return failure when Google sign in fails', () async {
        // Arrange
        const exception = UnexpectedAuthException('Google sign in failed');
        when(() => mockDataSource.signInWithGoogle()).thenThrow(exception);

        // Act
        final result = await repository.signInWithGoogle();

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<AuthenticationFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('signUpWithEmailAndPassword', () {
      test('should return success when sign up succeeds', () async {
        // Arrange
        when(
          () => mockDataSource.signUp(
            email: email,
            password: password,
          ),
        ).thenAnswer((_) async => user);

        // Act
        final result = await repository.signUpWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Assert
        expect(result, equals(const Right<Failure, User>(user)));
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
        final result = await repository.signUpWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<AuthenticationFailure>()),
          (_) => fail('Should return failure'),
        );
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
        final result = await repository.signUpWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<AuthenticationFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('signOut', () {
      test('should return success when sign out succeeds', () async {
        // Arrange
        when(() => mockDataSource.signOut()).thenAnswer((_) async {});

        // Act
        final result = await repository.signOut();

        // Assert
        expect(result, equals(const Right<Failure, void>(null)));
        verify(() => mockDataSource.signOut()).called(1);
      });

      test('should return failure when sign out fails', () async {
        // Arrange
        const exception = UnexpectedAuthException('Sign out failed');
        when(() => mockDataSource.signOut()).thenThrow(exception);

        // Act
        final result = await repository.signOut();

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<AuthenticationFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('sendPasswordResetEmail', () {
      test('should return success when password reset email is sent', () async {
        // Arrange
        when(() => mockDataSource.sendPasswordResetEmail(email))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.sendPasswordResetEmail(email: email);

        // Assert
        expect(result, equals(const Right<Failure, void>(null)));
        verify(() => mockDataSource.sendPasswordResetEmail(email)).called(1);
      });

      test('should return failure when user not found', () async {
        // Arrange
        const exception = UserNotFoundException();
        when(() => mockDataSource.sendPasswordResetEmail(email))
            .thenThrow(exception);

        // Act
        final result = await repository.sendPasswordResetEmail(email: email);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<AuthenticationFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('getCurrentUser', () {
      test('should return current user from data source', () async {
        // Arrange
        when(() => mockDataSource.currentUser).thenReturn(user);

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result, equals(const Right<Failure, User?>(user)));
        verify(() => mockDataSource.currentUser).called(1);
      });

      test('should return null when no current user', () async {
        // Arrange
        when(() => mockDataSource.currentUser).thenReturn(null);

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result, equals(const Right<Failure, User?>(null)));
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

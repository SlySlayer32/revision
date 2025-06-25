import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/features/authentication/data/datasources/firebase_auth_data_source.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/exceptions/auth_exception.dart';

import '../../../../helpers/helpers.dart'; // Import the helper

class MockFirebaseAuth extends Mock implements firebase_auth.FirebaseAuth {}

class MockFirebaseUser extends Mock implements firebase_auth.User {}

class MockUserCredential extends Mock implements firebase_auth.UserCredential {}

class MockUserMetadata extends Mock implements firebase_auth.UserMetadata {}

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class MockGoogleSignInAuthentication extends Mock
    implements GoogleSignInAuthentication {}

void main() {
  // Ensure Firebase is initialized before tests run
  setUpAll(() async {
    try {
      await setupFirebaseAuthMocks();
    } catch (e) {
      // Skip Firebase initialization errors in test environment
      print('Firebase mock setup failed: $e (continuing with tests)');
    }
  });

  group('FirebaseAuthDataSourceImpl', () {
    late FirebaseAuthDataSourceImpl dataSource;
    late MockFirebaseAuth mockFirebaseAuth;
    late MockGoogleSignIn mockGoogleSignIn;
    late MockFirebaseUser mockUser;
    late MockUserCredential mockUserCredential;
    late StreamController<firebase_auth.User?> authStateController;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockGoogleSignIn = MockGoogleSignIn();
      mockUser = MockFirebaseUser();
      mockUserCredential = MockUserCredential();
      authStateController = StreamController<firebase_auth.User?>();

      dataSource = FirebaseAuthDataSourceImpl(
        firebaseAuth: mockFirebaseAuth,
        googleSignIn: mockGoogleSignIn,
      ); // Set up common user mock
      when(() => mockUser.uid).thenReturn('test-id');
      when(() => mockUser.email).thenReturn('test@example.com');
      when(() => mockUser.displayName).thenReturn(null);
      when(() => mockUser.photoURL).thenReturn(null);
      when(() => mockUser.emailVerified).thenReturn(false);
      // Mock UserMetadata
      final mockMetadata = MockUserMetadata();
      when(() => mockMetadata.creationTime)
          .thenReturn(DateTime.parse('2023-01-01T12:00:00.000Z'));
      when(() => mockUser.metadata).thenReturn(mockMetadata);

      when(() => mockUserCredential.user).thenReturn(mockUser);
    });

    tearDown(() {
      authStateController.close();
    });

    group('signIn', () {
      const email = 'test@example.com';
      const password = 'password123';

      test('should sign in user successfully', () async {
        // Arrange
        when(
          () => mockFirebaseAuth.signInWithEmailAndPassword(
            email: email,
            password: password,
          ),
        ).thenAnswer((_) async => mockUserCredential);

        // Act
        final result = await dataSource.signIn(
          email: email,
          password: password,
        );

        // Assert
        expect(result, isA<User>());
        expect(result.email, equals(email));
        verify(
          () => mockFirebaseAuth.signInWithEmailAndPassword(
            email: email,
            password: password,
          ),
        ).called(1);
      });

      test('should throw InvalidCredentialsException for wrong password',
          () async {
        // Arrange
        when(
          () => mockFirebaseAuth.signInWithEmailAndPassword(
            email: email,
            password: password,
          ),
        ).thenThrow(
          firebase_auth.FirebaseAuthException(
            code: 'wrong-password',
            message: 'Wrong password',
          ),
        );

        // Act & Assert
        await expectLater(
          () => dataSource.signIn(email: email, password: password),
          throwsA(isA<InvalidCredentialsException>()),
        );
      });

      test('should throw InvalidCredentialsException for user not found',
          () async {
        // Arrange
        when(
          () => mockFirebaseAuth.signInWithEmailAndPassword(
            email: email,
            password: password,
          ),
        ).thenThrow(
          firebase_auth.FirebaseAuthException(
            code: 'user-not-found',
            message: 'User not found',
          ),
        );

        // Act & Assert
        await expectLater(
          () => dataSource.signIn(email: email, password: password),
          throwsA(isA<InvalidCredentialsException>()),
        );
      });

      test('should throw NetworkException for network errors', () async {
        // Arrange
        when(
          () => mockFirebaseAuth.signInWithEmailAndPassword(
            email: email,
            password: password,
          ),
        ).thenThrow(
          firebase_auth.FirebaseAuthException(
            code: 'network-request-failed',
            message: 'Network error',
          ),
        );

        // Act & Assert
        await expectLater(
          () => dataSource.signIn(email: email, password: password),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    group('signUp', () {
      const email = 'test@example.com';
      const password = 'password123';

      test('should create user successfully', () async {
        // Arrange
        when(
          () => mockFirebaseAuth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          ),
        ).thenAnswer((_) async => mockUserCredential);

        // Act
        final result = await dataSource.signUp(
          email: email,
          password: password,
        );

        // Assert
        expect(result, isA<User>());
        expect(result.email, equals(email));
        verify(
          () => mockFirebaseAuth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          ),
        ).called(1);
      });

      test('should throw EmailAlreadyInUseException for existing email',
          () async {
        // Arrange
        when(
          () => mockFirebaseAuth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          ),
        ).thenThrow(
          firebase_auth.FirebaseAuthException(
            code: 'email-already-in-use',
            message: 'Email already in use',
          ),
        );

        // Act & Assert
        await expectLater(
          () => dataSource.signUp(email: email, password: password),
          throwsA(isA<EmailAlreadyInUseException>()),
        );
      });

      test('should throw WeakPasswordException for weak password', () async {
        // Arrange
        when(
          () => mockFirebaseAuth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          ),
        ).thenThrow(
          firebase_auth.FirebaseAuthException(
            code: 'weak-password',
            message: 'Weak password',
          ),
        );

        // Act & Assert
        await expectLater(
          () => dataSource.signUp(email: email, password: password),
          throwsA(isA<WeakPasswordException>()),
        );
      });
    });

    group('signOut', () {
      test('should sign out user successfully', () async {
        // Arrange
        when(() => mockFirebaseAuth.signOut()).thenAnswer((_) async {});
        when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => null);

        // Act
        await dataSource.signOut();

        // Assert
        verify(() => mockFirebaseAuth.signOut()).called(1);
        verify(() => mockGoogleSignIn.signOut()).called(1);
      });

      test('should handle sign out errors gracefully', () async {
        // Arrange
        when(() => mockFirebaseAuth.signOut())
            .thenThrow(Exception('Sign out failed'));
        when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => null);

        // Act & Assert
        await expectLater(
          () => dataSource.signOut(),
          throwsA(isA<UnexpectedAuthException>()),
        );
      });
    });

    group('sendPasswordResetEmail', () {
      const email = 'test@example.com';

      test('should send password reset email successfully', () async {
        // Arrange
        when(() => mockFirebaseAuth.sendPasswordResetEmail(email: email))
            .thenAnswer((_) async {});

        // Act
        await dataSource.sendPasswordResetEmail(email);

        // Assert
        verify(() => mockFirebaseAuth.sendPasswordResetEmail(email: email))
            .called(1);
      });
      test('should throw InvalidCredentialsException for invalid email',
          () async {
        // Arrange
        when(() => mockFirebaseAuth.sendPasswordResetEmail(email: email))
            .thenThrow(
          firebase_auth.FirebaseAuthException(
            code: 'user-not-found',
            message: 'User not found',
          ),
        );

        // Act & Assert
        await expectLater(
          () => dataSource.sendPasswordResetEmail(email),
          throwsA(isA<InvalidCredentialsException>()),
        );
      });
    });

    group('currentUser', () {
      test('should return current user when signed in', () {
        // Arrange
        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);

        // Act
        final result = dataSource.currentUser;

        // Assert
        expect(result, isA<User>());
        expect(result?.email, equals('test@example.com'));
      });

      test('should return null when not signed in', () {
        // Arrange
        when(() => mockFirebaseAuth.currentUser).thenReturn(null);

        // Act
        final result = dataSource.currentUser;

        // Assert
        expect(result, isNull);
      });
    });

    group('authStateChanges', () {
      test('should return stream of auth state changes', () {
        // Arrange
        when(() => mockFirebaseAuth.authStateChanges())
            .thenAnswer((_) => authStateController.stream);

        // Act
        final stream = dataSource.authStateChanges;

        // Assert
        expect(stream, isA<Stream<User?>>());
      });

      test('should emit user when user signs in', () async {
        // Arrange
        when(() => mockFirebaseAuth.authStateChanges())
            .thenAnswer((_) => authStateController.stream);

        // Act
        final stream = dataSource.authStateChanges;
        authStateController.add(mockUser);

        // Assert
        await expectLater(
          stream,
          emits(predicate<User?>((user) => user?.email == 'test@example.com')),
        );
      });

      test('should emit null when user signs out', () async {
        // Arrange
        when(() => mockFirebaseAuth.authStateChanges())
            .thenAnswer((_) => authStateController.stream);

        // Act
        final stream = dataSource.authStateChanges;
        authStateController.add(null);

        // Assert
        await expectLater(stream, emits(null));
      });
    });
  });
}

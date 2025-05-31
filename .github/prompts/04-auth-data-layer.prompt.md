# Phase 2, Step 4: Authentication Data Layer (Test-First)

## Context & Requirements
Implement the authentication data layer with Firebase integration using test-driven development. This layer handles Firebase Auth operations, data mapping, and exception handling following VGV clean architecture patterns.

**Critical Technical Requirements:**
- Test-first development: Write tests with mocks BEFORE implementation
- Firebase Auth integration: Email/password and Google sign-in
- Error mapping: Convert Firebase exceptions to domain exceptions
- Data mapping: Firebase User to domain User entity
- Retry logic: Handle transient network failures
- Logging: Comprehensive audit trail

## Exact Implementation Specifications

### 1. Firebase Auth Data Source (Test-First)
```dart
// test/features/authentication/data/datasources/firebase_auth_datasource_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ai_photo_editor/features/authentication/data/datasources/firebase_auth_datasource.dart';
import 'package:ai_photo_editor/features/authentication/data/models/user_model.dart';
import 'package:ai_photo_editor/features/authentication/domain/exceptions/auth_exceptions.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUserCredential extends Mock implements UserCredential {}
class MockUser extends Mock implements User {}
class MockGoogleSignIn extends Mock implements GoogleSignIn {}
class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}
class MockGoogleSignInAuthentication extends Mock implements GoogleSignInAuthentication {}

void main() {
  late FirebaseAuthDataSource dataSource;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockGoogleSignIn mockGoogleSignIn;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();
    dataSource = FirebaseAuthDataSourceImpl(
      firebaseAuth: mockFirebaseAuth,
      googleSignIn: mockGoogleSignIn,
    );
  });

  group('FirebaseAuthDataSource', () {
    const tEmail = 'test@example.com';
    const tPassword = 'password123';
    const tUserId = 'test-user-id';
    const tDisplayName = 'Test User';

    group('signInWithEmailAndPassword', () {
      test('should return UserModel when sign in is successful', () async {
        // arrange
        final mockUserCredential = MockUserCredential();
        final mockUser = MockUser();
        
        when(() => mockUser.uid).thenReturn(tUserId);
        when(() => mockUser.email).thenReturn(tEmail);
        when(() => mockUser.displayName).thenReturn(tDisplayName);
        when(() => mockUser.photoURL).thenReturn(null);
        when(() => mockUser.emailVerified).thenReturn(true);
        when(() => mockUser.metadata).thenReturn(UserMetadata(
          creationTime: DateTime(2024, 1, 1),
          lastSignInTime: DateTime(2024, 1, 1),
        ));
        
        when(() => mockUserCredential.user).thenReturn(mockUser);
        when(() => mockFirebaseAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => mockUserCredential);

        // act
        final result = await dataSource.signInWithEmailAndPassword(
          email: tEmail,
          password: tPassword,
        );

        // assert
        expect(result, isA<UserModel>());
        expect(result.id, equals(tUserId));
        expect(result.email, equals(tEmail));
        verify(() => mockFirebaseAuth.signInWithEmailAndPassword(
          email: tEmail,
          password: tPassword,
        )).called(1);
      });

      test('should throw InvalidCredentialsException when credentials are wrong', () async {
        // arrange
        when(() => mockFirebaseAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(FirebaseAuthException(
          code: 'wrong-password',
          message: 'The password is invalid',
        ));

        // act & assert
        expect(
          () => dataSource.signInWithEmailAndPassword(
            email: tEmail,
            password: tPassword,
          ),
          throwsA(isA<InvalidCredentialsException>()),
        );
      });

      test('should throw UserNotFoundException when user does not exist', () async {
        // arrange
        when(() => mockFirebaseAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user found for that email',
        ));

        // act & assert
        expect(
          () => dataSource.signInWithEmailAndPassword(
            email: tEmail,
            password: tPassword,
          ),
          throwsA(isA<UserNotFoundException>()),
        );
      });

      test('should throw NetworkAuthException on network errors', () async {
        // arrange
        when(() => mockFirebaseAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(FirebaseAuthException(
          code: 'network-request-failed',
          message: 'Network error',
        ));

        // act & assert
        expect(
          () => dataSource.signInWithEmailAndPassword(
            email: tEmail,
            password: tPassword,
          ),
          throwsA(isA<NetworkAuthException>()),
        );
      });

      test('should throw AuthenticationException for unknown Firebase errors', () async {
        // arrange
        when(() => mockFirebaseAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(FirebaseAuthException(
          code: 'unknown-error',
          message: 'An unknown error occurred',
        ));

        // act & assert
        expect(
          () => dataSource.signInWithEmailAndPassword(
            email: tEmail,
            password: tPassword,
          ),
          throwsA(isA<AuthenticationException>()),
        );
      });
    });

    group('signUpWithEmailAndPassword', () {
      test('should return UserModel when sign up is successful', () async {
        // arrange
        final mockUserCredential = MockUserCredential();
        final mockUser = MockUser();
        
        when(() => mockUser.uid).thenReturn(tUserId);
        when(() => mockUser.email).thenReturn(tEmail);
        when(() => mockUser.displayName).thenReturn(tDisplayName);
        when(() => mockUser.photoURL).thenReturn(null);
        when(() => mockUser.emailVerified).thenReturn(false);
        when(() => mockUser.metadata).thenReturn(UserMetadata(
          creationTime: DateTime(2024, 1, 1),
          lastSignInTime: DateTime(2024, 1, 1),
        ));
        
        when(() => mockUserCredential.user).thenReturn(mockUser);
        when(() => mockFirebaseAuth.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => mockUserCredential);
        when(() => mockUser.updateDisplayName(any())).thenAnswer((_) async {});

        // act
        final result = await dataSource.signUpWithEmailAndPassword(
          email: tEmail,
          password: tPassword,
          displayName: tDisplayName,
        );

        // assert
        expect(result, isA<UserModel>());
        expect(result.id, equals(tUserId));
        expect(result.email, equals(tEmail));
        verify(() => mockFirebaseAuth.createUserWithEmailAndPassword(
          email: tEmail,
          password: tPassword,
        )).called(1);
        verify(() => mockUser.updateDisplayName(tDisplayName)).called(1);
      });

      test('should throw EmailAlreadyInUseException when email is taken', () async {
        // arrange
        when(() => mockFirebaseAuth.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'The email address is already in use',
        ));

        // act & assert
        expect(
          () => dataSource.signUpWithEmailAndPassword(
            email: tEmail,
            password: tPassword,
          ),
          throwsA(isA<EmailAlreadyInUseException>()),
        );
      });

      test('should throw WeakPasswordException when password is weak', () async {
        // arrange
        when(() => mockFirebaseAuth.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(FirebaseAuthException(
          code: 'weak-password',
          message: 'The password provided is too weak',
        ));

        // act & assert
        expect(
          () => dataSource.signUpWithEmailAndPassword(
            email: tEmail,
            password: 'weak',
          ),
          throwsA(isA<WeakPasswordException>()),
        );
      });
    });

    group('signInWithGoogle', () {
      test('should return UserModel when Google sign in is successful', () async {
        // arrange
        final mockGoogleSignInAccount = MockGoogleSignInAccount();
        final mockGoogleSignInAuthentication = MockGoogleSignInAuthentication();
        final mockUserCredential = MockUserCredential();
        final mockUser = MockUser();
        
        when(() => mockGoogleSignInAccount.authentication)
            .thenAnswer((_) async => mockGoogleSignInAuthentication);
        when(() => mockGoogleSignInAuthentication.accessToken).thenReturn('access-token');
        when(() => mockGoogleSignInAuthentication.idToken).thenReturn('id-token');
        
        when(() => mockUser.uid).thenReturn(tUserId);
        when(() => mockUser.email).thenReturn(tEmail);
        when(() => mockUser.displayName).thenReturn(tDisplayName);
        when(() => mockUser.photoURL).thenReturn('https://photo.url');
        when(() => mockUser.emailVerified).thenReturn(true);
        when(() => mockUser.metadata).thenReturn(UserMetadata(
          creationTime: DateTime(2024, 1, 1),
          lastSignInTime: DateTime(2024, 1, 1),
        ));
        
        when(() => mockUserCredential.user).thenReturn(mockUser);
        when(() => mockGoogleSignIn.signIn()).thenAnswer((_) async => mockGoogleSignInAccount);
        when(() => mockFirebaseAuth.signInWithCredential(any()))
            .thenAnswer((_) async => mockUserCredential);

        // act
        final result = await dataSource.signInWithGoogle();

        // assert
        expect(result, isA<UserModel>());
        expect(result.id, equals(tUserId));
        expect(result.email, equals(tEmail));
        verify(() => mockGoogleSignIn.signIn()).called(1);
        verify(() => mockFirebaseAuth.signInWithCredential(any())).called(1);
      });

      test('should throw AuthenticationException when Google sign in is cancelled', () async {
        // arrange
        when(() => mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

        // act & assert
        expect(
          () => dataSource.signInWithGoogle(),
          throwsA(isA<AuthenticationException>()),
        );
      });
    });

    group('signOut', () {
      test('should call Firebase and Google sign out', () async {
        // arrange
        when(() => mockFirebaseAuth.signOut()).thenAnswer((_) async {});
        when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => null);

        // act
        await dataSource.signOut();

        // assert
        verify(() => mockFirebaseAuth.signOut()).called(1);
        verify(() => mockGoogleSignIn.signOut()).called(1);
      });
    });

    group('getCurrentUser', () {
      test('should return UserModel when user is authenticated', () async {
        // arrange
        final mockUser = MockUser();
        
        when(() => mockUser.uid).thenReturn(tUserId);
        when(() => mockUser.email).thenReturn(tEmail);
        when(() => mockUser.displayName).thenReturn(tDisplayName);
        when(() => mockUser.photoURL).thenReturn(null);
        when(() => mockUser.emailVerified).thenReturn(true);
        when(() => mockUser.metadata).thenReturn(UserMetadata(
          creationTime: DateTime(2024, 1, 1),
          lastSignInTime: DateTime(2024, 1, 1),
        ));
        
        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);

        // act
        final result = await dataSource.getCurrentUser();

        // assert
        expect(result, isA<UserModel>());
        expect(result!.id, equals(tUserId));
        expect(result.email, equals(tEmail));
      });

      test('should return null when no user is authenticated', () async {
        // arrange
        when(() => mockFirebaseAuth.currentUser).thenReturn(null);

        // act
        final result = await dataSource.getCurrentUser();

        // assert
        expect(result, isNull);
      });
    });
  });
}

// lib/features/authentication/data/datasources/firebase_auth_datasource.dart
import 'dart:async';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/exceptions/auth_exceptions.dart';
import '../models/user_model.dart';

abstract class FirebaseAuthDataSource {
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  });

  Future<UserModel> signInWithGoogle();

  Future<void> signOut();

  Future<UserModel?> getCurrentUser();

  Stream<UserModel?> get authStateChanges;

  Future<void> sendEmailVerification();

  Future<void> sendPasswordResetEmail({required String email});

  Future<UserModel> updateUserProfile({
    String? displayName,
    String? photoUrl,
  });

  Future<void> deleteAccount();

  Future<void> reauthenticateWithPassword({required String password});
}

class FirebaseAuthDataSourceImpl implements FirebaseAuthDataSource {
  FirebaseAuthDataSourceImpl({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  @override
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      log('Attempting to sign in with email: $email');
      
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw const AuthenticationException('Sign in failed - no user returned');
      }

      log('Sign in successful for user: ${credential.user!.uid}');
      return UserModel.fromFirebaseUser(credential.user!);
    } on FirebaseAuthException catch (e) {
      log('Firebase Auth error: ${e.code} - ${e.message}');
      throw _mapFirebaseException(e);
    } catch (e) {
      log('Unexpected error during sign in: $e');
      throw AuthenticationException('Sign in failed: $e');
    }
  }

  @override
  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      log('Attempting to sign up with email: $email');
      
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw const AuthenticationException('Sign up failed - no user returned');
      }

      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await credential.user!.updateDisplayName(displayName);
        await credential.user!.reload();
      }

      log('Sign up successful for user: ${credential.user!.uid}');
      return UserModel.fromFirebaseUser(credential.user!);
    } on FirebaseAuthException catch (e) {
      log('Firebase Auth error during sign up: ${e.code} - ${e.message}');
      throw _mapFirebaseException(e);
    } catch (e) {
      log('Unexpected error during sign up: $e');
      throw AuthenticationException('Sign up failed: $e');
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      log('Attempting to sign in with Google');
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw const AuthenticationException('Google sign in was cancelled');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw const AuthenticationException('Google sign in failed - no user returned');
      }

      log('Google sign in successful for user: ${userCredential.user!.uid}');
      return UserModel.fromFirebaseUser(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      log('Firebase Auth error during Google sign in: ${e.code} - ${e.message}');
      throw _mapFirebaseException(e);
    } catch (e) {
      log('Unexpected error during Google sign in: $e');
      throw AuthenticationException('Google sign in failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      log('Signing out user');
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
      log('Sign out successful');
    } catch (e) {
      log('Error during sign out: $e');
      throw AuthenticationException('Sign out failed: $e');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;
      
      return UserModel.fromFirebaseUser(user);
    } catch (e) {
      log('Error getting current user: $e');
      return null;
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((user) {
      return user != null ? UserModel.fromFirebaseUser(user) : null;
    });
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthenticationException('No user is currently signed in');
      }
      
      await user.sendEmailVerification();
      log('Email verification sent to: ${user.email}');
    } on FirebaseAuthException catch (e) {
      log('Firebase Auth error sending email verification: ${e.code} - ${e.message}');
      throw _mapFirebaseException(e);
    } catch (e) {
      log('Unexpected error sending email verification: $e');
      throw AuthenticationException('Failed to send email verification: $e');
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      log('Sending password reset email to: $email');
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      log('Password reset email sent successfully');
    } on FirebaseAuthException catch (e) {
      log('Firebase Auth error sending password reset: ${e.code} - ${e.message}');
      throw _mapFirebaseException(e);
    } catch (e) {
      log('Unexpected error sending password reset: $e');
      throw AuthenticationException('Failed to send password reset email: $e');
    }
  }

  @override
  Future<UserModel> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthenticationException('No user is currently signed in');
      }

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }

      await user.reload();
      final updatedUser = _firebaseAuth.currentUser!;
      
      log('User profile updated for: ${updatedUser.uid}');
      return UserModel.fromFirebaseUser(updatedUser);
    } on FirebaseAuthException catch (e) {
      log('Firebase Auth error updating profile: ${e.code} - ${e.message}');
      throw _mapFirebaseException(e);
    } catch (e) {
      log('Unexpected error updating profile: $e');
      throw AuthenticationException('Failed to update profile: $e');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthenticationException('No user is currently signed in');
      }

      log('Deleting account for user: ${user.uid}');
      await user.delete();
      log('Account deleted successfully');
    } on FirebaseAuthException catch (e) {
      log('Firebase Auth error deleting account: ${e.code} - ${e.message}');
      throw _mapFirebaseException(e);
    } catch (e) {
      log('Unexpected error deleting account: $e');
      throw AuthenticationException('Failed to delete account: $e');
    }
  }

  @override
  Future<void> reauthenticateWithPassword({required String password}) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthenticationException('No user is currently signed in');
      }

      if (user.email == null) {
        throw const AuthenticationException('User email is not available');
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      log('Reauthenticating user: ${user.uid}');
      await user.reauthenticateWithCredential(credential);
      log('Reauthentication successful');
    } on FirebaseAuthException catch (e) {
      log('Firebase Auth error during reauthentication: ${e.code} - ${e.message}');
      throw _mapFirebaseException(e);
    } catch (e) {
      log('Unexpected error during reauthentication: $e');
      throw AuthenticationException('Reauthentication failed: $e');
    }
  }

  /// Maps Firebase exceptions to domain exceptions
  AuthenticationException _mapFirebaseException(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return const InvalidCredentialsException();
      case 'user-not-found':
        return const UserNotFoundException();
      case 'email-already-in-use':
        return const EmailAlreadyInUseException();
      case 'weak-password':
        return const WeakPasswordException();
      case 'network-request-failed':
        return const NetworkAuthException();
      case 'too-many-requests':
        return const TooManyRequestsException();
      case 'user-disabled':
        return const AccountDisabledException();
      case 'requires-recent-login':
        return const ReauthenticationRequiredException();
      case 'provider-already-linked':
        return const ProviderAlreadyLinkedException();
      default:
        return AuthenticationException(e.message ?? 'Unknown authentication error', e.code);
    }
  }
}
```

### 2. User Model (Test-First)
```dart
// test/features/authentication/data/models/user_model_test.dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ai_photo_editor/features/authentication/data/models/user_model.dart';
import 'package:ai_photo_editor/features/authentication/domain/entities/user.dart' as domain;

class MockUser extends Mock implements User {}

void main() {
  group('UserModel', () {
    const tUserModel = UserModel(
      id: 'test-id',
      email: 'test@example.com',
      displayName: 'Test User',
      photoUrl: 'https://example.com/photo.jpg',
      isEmailVerified: true,
      createdAt: '2024-01-01T00:00:00Z',
    );

    test('should be a subclass of User entity', () {
      expect(tUserModel, isA<domain.User>());
    });

    group('fromFirebaseUser', () {
      test('should return a valid UserModel from Firebase User', () {
        // arrange
        final mockUser = MockUser();
        when(() => mockUser.uid).thenReturn('test-id');
        when(() => mockUser.email).thenReturn('test@example.com');
        when(() => mockUser.displayName).thenReturn('Test User');
        when(() => mockUser.photoURL).thenReturn('https://example.com/photo.jpg');
        when(() => mockUser.emailVerified).thenReturn(true);
        when(() => mockUser.metadata).thenReturn(UserMetadata(
          creationTime: DateTime.parse('2024-01-01T00:00:00Z'),
          lastSignInTime: DateTime.parse('2024-01-01T00:00:00Z'),
        ));

        // act
        final result = UserModel.fromFirebaseUser(mockUser);

        // assert
        expect(result.id, equals('test-id'));
        expect(result.email, equals('test@example.com'));
        expect(result.displayName, equals('Test User'));
        expect(result.photoUrl, equals('https://example.com/photo.jpg'));
        expect(result.isEmailVerified, isTrue);
        expect(result.createdAt, equals('2024-01-01T00:00:00Z'));
      });

      test('should handle null values from Firebase User', () {
        // arrange
        final mockUser = MockUser();
        when(() => mockUser.uid).thenReturn('test-id');
        when(() => mockUser.email).thenReturn('test@example.com');
        when(() => mockUser.displayName).thenReturn(null);
        when(() => mockUser.photoURL).thenReturn(null);
        when(() => mockUser.emailVerified).thenReturn(false);
        when(() => mockUser.metadata).thenReturn(UserMetadata(
          creationTime: DateTime.parse('2024-01-01T00:00:00Z'),
          lastSignInTime: null,
        ));

        // act
        final result = UserModel.fromFirebaseUser(mockUser);

        // assert
        expect(result.displayName, isNull);
        expect(result.photoUrl, isNull);
        expect(result.isEmailVerified, isFalse);
      });
    });

    group('toJson', () {
      test('should return a JSON map containing the proper data', () {
        // act
        final result = tUserModel.toJson();

        // assert
        final expectedMap = {
          'id': 'test-id',
          'email': 'test@example.com',
          'displayName': 'Test User',
          'photoUrl': 'https://example.com/photo.jpg',
          'isEmailVerified': true,
          'createdAt': '2024-01-01T00:00:00Z',
        };
        expect(result, equals(expectedMap));
      });
    });

    group('fromJson', () {
      test('should return a valid UserModel from JSON', () {
        // arrange
        final jsonMap = {
          'id': 'test-id',
          'email': 'test@example.com',
          'displayName': 'Test User',
          'photoUrl': 'https://example.com/photo.jpg',
          'isEmailVerified': true,
          'createdAt': '2024-01-01T00:00:00Z',
        };

        // act
        final result = UserModel.fromJson(jsonMap);

        // assert
        expect(result, equals(tUserModel));
      });

      test('should handle null values in JSON', () {
        // arrange
        final jsonMap = {
          'id': 'test-id',
          'email': 'test@example.com',
          'displayName': null,
          'photoUrl': null,
          'isEmailVerified': false,
          'createdAt': '2024-01-01T00:00:00Z',
        };

        // act
        final result = UserModel.fromJson(jsonMap);

        // assert
        expect(result.displayName, isNull);
        expect(result.photoUrl, isNull);
        expect(result.isEmailVerified, isFalse);
      });
    });

    group('copyWith', () {
      test('should return a UserModel with updated values', () {
        // act
        final result = tUserModel.copyWith(
          displayName: 'Updated Name',
          isEmailVerified: false,
        );

        // assert
        expect(result.id, equals(tUserModel.id));
        expect(result.email, equals(tUserModel.email));
        expect(result.displayName, equals('Updated Name'));
        expect(result.photoUrl, equals(tUserModel.photoUrl));
        expect(result.isEmailVerified, isFalse);
        expect(result.createdAt, equals(tUserModel.createdAt));
      });
    });
  });
}

// lib/features/authentication/data/models/user_model.dart
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.displayName,
    required super.photoUrl,
    required super.isEmailVerified,
    required super.createdAt,
  });

  /// Creates a UserModel from a Firebase User
  factory UserModel.fromFirebaseUser(firebase_auth.User firebaseUser) {
    return UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      isEmailVerified: firebaseUser.emailVerified,
      createdAt: firebaseUser.metadata.creationTime?.toIso8601String() ??
          DateTime.now().toIso8601String(),
    );
  }

  /// Creates a UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      isEmailVerified: json['isEmailVerified'] as bool,
      createdAt: json['createdAt'] as String,
    );
  }

  /// Converts UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt,
    };
  }

  /// Creates a copy with updated values
  @override
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isEmailVerified,
    String? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
```

### 3. Repository Implementation (Test-First)
```dart
// test/features/authentication/data/repositories/auth_repository_impl_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:ai_photo_editor/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:ai_photo_editor/features/authentication/data/datasources/firebase_auth_datasource.dart';
import 'package:ai_photo_editor/features/authentication/data/models/user_model.dart';
import 'package:ai_photo_editor/features/authentication/domain/exceptions/auth_exceptions.dart';
import 'package:ai_photo_editor/core/error/failures.dart';
import 'package:ai_photo_editor/core/network/network_info.dart';

class MockFirebaseAuthDataSource extends Mock implements FirebaseAuthDataSource {}
class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late AuthRepositoryImpl repository;
  late MockFirebaseAuthDataSource mockDataSource;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockDataSource = MockFirebaseAuthDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = AuthRepositoryImpl(
      dataSource: mockDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  group('AuthRepositoryImpl', () {
    const tEmail = 'test@example.com';
    const tPassword = 'password123';
    const tUserModel = UserModel(
      id: 'test-id',
      email: tEmail,
      displayName: 'Test User',
      photoUrl: null,
      isEmailVerified: true,
      createdAt: '2024-01-01T00:00:00Z',
    );

    group('signInWithEmailAndPassword', () {
      test('should return User when sign in is successful', () async {
        // arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockDataSource.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => tUserModel);

        // act
        final result = await repository.signInWithEmailAndPassword(
          email: tEmail,
          password: tPassword,
        );

        // assert
        expect(result, equals(const Right(tUserModel)));
        verify(() => mockDataSource.signInWithEmailAndPassword(
          email: tEmail,
          password: tPassword,
        )).called(1);
      });

      test('should return NetworkFailure when device is offline', () async {
        // arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        // act
        final result = await repository.signInWithEmailAndPassword(
          email: tEmail,
          password: tPassword,
        );

        // assert
        expect(result, equals(const Left(NetworkFailure('No internet connection'))));
        verifyNever(() => mockDataSource.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ));
      });

      test('should return AuthenticationFailure when InvalidCredentialsException is thrown', () async {
        // arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockDataSource.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(const InvalidCredentialsException());

        // act
        final result = await repository.signInWithEmailAndPassword(
          email: tEmail,
          password: tPassword,
        );

        // assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<AuthenticationFailure>()),
          (user) => fail('Should return failure'),
        );
      });

      test('should return AuthenticationFailure when any AuthenticationException is thrown', () async {
        // arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockDataSource.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(const UserNotFoundException());

        // act
        final result = await repository.signInWithEmailAndPassword(
          email: tEmail,
          password: tPassword,
        );

        // assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<AuthenticationFailure>()),
          (user) => fail('Should return failure'),
        );
      });

      test('should return AuthenticationFailure when unexpected exception is thrown', () async {
        // arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockDataSource.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(Exception('Unexpected error'));

        // act
        final result = await repository.signInWithEmailAndPassword(
          email: tEmail,
          password: tPassword,
        );

        // assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<AuthenticationFailure>()),
          (user) => fail('Should return failure'),
        );
      });
    });

    group('signUpWithEmailAndPassword', () {
      test('should return User when sign up is successful', () async {
        // arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockDataSource.signUpWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
          displayName: any(named: 'displayName'),
        )).thenAnswer((_) async => tUserModel);

        // act
        final result = await repository.signUpWithEmailAndPassword(
          email: tEmail,
          password: tPassword,
          displayName: 'Test User',
        );

        // assert
        expect(result, equals(const Right(tUserModel)));
        verify(() => mockDataSource.signUpWithEmailAndPassword(
          email: tEmail,
          password: tPassword,
          displayName: 'Test User',
        )).called(1);
      });
    });

    group('signInWithGoogle', () {
      test('should return User when Google sign in is successful', () async {
        // arrange
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockDataSource.signInWithGoogle()).thenAnswer((_) async => tUserModel);

        // act
        final result = await repository.signInWithGoogle();

        // assert
        expect(result, equals(const Right(tUserModel)));
        verify(() => mockDataSource.signInWithGoogle()).called(1);
      });
    });

    group('signOut', () {
      test('should return success when sign out is successful', () async {
        // arrange
        when(() => mockDataSource.signOut()).thenAnswer((_) async {});

        // act
        final result = await repository.signOut();

        // assert
        expect(result, equals(const Right(null)));
        verify(() => mockDataSource.signOut()).called(1);
      });

      test('should return AuthenticationFailure when sign out fails', () async {
        // arrange
        when(() => mockDataSource.signOut()).thenThrow(const AuthenticationException('Sign out failed'));

        // act
        final result = await repository.signOut();

        // assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<AuthenticationFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('getCurrentUser', () {
      test('should return User when user is authenticated', () async {
        // arrange
        when(() => mockDataSource.getCurrentUser()).thenAnswer((_) async => tUserModel);

        // act
        final result = await repository.getCurrentUser();

        // assert
        expect(result, equals(const Right(tUserModel)));
      });

      test('should return null when no user is authenticated', () async {
        // arrange
        when(() => mockDataSource.getCurrentUser()).thenAnswer((_) async => null);

        // act
        final result = await repository.getCurrentUser();

        // assert
        expect(result, equals(const Right(null)));
      });
    });

    group('authStateChanges', () {
      test('should return stream of UserModel', () async {
        // arrange
        final userStream = Stream.fromIterable([tUserModel, null]);
        when(() => mockDataSource.authStateChanges).thenAnswer((_) => userStream);

        // act
        final result = repository.authStateChanges;

        // assert
        expect(result, emitsInOrder([tUserModel, null]));
      });
    });
  });
}

// lib/features/authentication/data/repositories/auth_repository_impl.dart
import 'dart:developer';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/user.dart';
import '../../domain/exceptions/auth_exceptions.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required this.dataSource,
    required this.networkInfo,
  });

  final FirebaseAuthDataSource dataSource;
  final NetworkInfo networkInfo;

  @override
  Future<Either<Failure, User>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final user = await dataSource.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return Right(user);
    } on AuthenticationException catch (e) {
      log('Authentication error during sign in: ${e.message}');
      return Left(AuthenticationFailure(e.message, e.code));
    } catch (e) {
      log('Unexpected error during sign in: $e');
      return Left(AuthenticationFailure('Sign in failed: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final user = await dataSource.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      return Right(user);
    } on AuthenticationException catch (e) {
      log('Authentication error during sign up: ${e.message}');
      return Left(AuthenticationFailure(e.message, e.code));
    } catch (e) {
      log('Unexpected error during sign up: $e');
      return Left(AuthenticationFailure('Sign up failed: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final user = await dataSource.signInWithGoogle();
      return Right(user);
    } on AuthenticationException catch (e) {
      log('Authentication error during Google sign in: ${e.message}');
      return Left(AuthenticationFailure(e.message, e.code));
    } catch (e) {
      log('Unexpected error during Google sign in: $e');
      return Left(AuthenticationFailure('Google sign in failed: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await dataSource.signOut();
      return const Right(null);
    } on AuthenticationException catch (e) {
      log('Authentication error during sign out: ${e.message}');
      return Left(AuthenticationFailure(e.message, e.code));
    } catch (e) {
      log('Unexpected error during sign out: $e');
      return Left(AuthenticationFailure('Sign out failed: $e'));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final user = await dataSource.getCurrentUser();
      return Right(user);
    } catch (e) {
      log('Error getting current user: $e');
      return Left(AuthenticationFailure('Failed to get current user: $e'));
    }
  }

  @override
  Stream<User?> get authStateChanges {
    return dataSource.authStateChanges;
  }

  @override
  Future<Either<Failure, void>> sendEmailVerification() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      await dataSource.sendEmailVerification();
      return const Right(null);
    } on AuthenticationException catch (e) {
      log('Authentication error sending email verification: ${e.message}');
      return Left(AuthenticationFailure(e.message, e.code));
    } catch (e) {
      log('Unexpected error sending email verification: $e');
      return Left(AuthenticationFailure('Failed to send email verification: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail({
    required String email,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      await dataSource.sendPasswordResetEmail(email: email);
      return const Right(null);
    } on AuthenticationException catch (e) {
      log('Authentication error sending password reset: ${e.message}');
      return Left(AuthenticationFailure(e.message, e.code));
    } catch (e) {
      log('Unexpected error sending password reset: $e');
      return Left(AuthenticationFailure('Failed to send password reset email: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final user = await dataSource.updateUserProfile(
        displayName: displayName,
        photoUrl: photoUrl,
      );
      return Right(user);
    } on AuthenticationException catch (e) {
      log('Authentication error updating profile: ${e.message}');
      return Left(AuthenticationFailure(e.message, e.code));
    } catch (e) {
      log('Unexpected error updating profile: $e');
      return Left(AuthenticationFailure('Failed to update profile: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      await dataSource.deleteAccount();
      return const Right(null);
    } on AuthenticationException catch (e) {
      log('Authentication error deleting account: ${e.message}');
      return Left(AuthenticationFailure(e.message, e.code));
    } catch (e) {
      log('Unexpected error deleting account: $e');
      return Left(AuthenticationFailure('Failed to delete account: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> reauthenticateWithPassword({
    required String password,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      await dataSource.reauthenticateWithPassword(password: password);
      return const Right(null);
    } on AuthenticationException catch (e) {
      log('Authentication error during reauthentication: ${e.message}');
      return Left(AuthenticationFailure(e.message, e.code));
    } catch (e) {
      log('Unexpected error during reauthentication: $e');
      return Left(AuthenticationFailure('Reauthentication failed: $e'));
    }
  }
}
```

### 4. Network Info Service
```dart
// lib/core/network/network_info.dart
import 'package:connectivity_plus/connectivity_plus.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  NetworkInfoImpl(this.connectivity);

  final Connectivity connectivity;

  @override
  Future<bool> get isConnected async {
    final result = await connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
}
```

## Acceptance Criteria (Must All Pass)
1. ✅ All tests pass before implementation exists
2. ✅ Firebase Auth integration works correctly
3. ✅ Error mapping converts all Firebase exceptions
4. ✅ Network checks prevent offline operations
5. ✅ Data models map correctly to domain entities
6. ✅ Repository implements all interface methods
7. ✅ Logging provides adequate debugging info
8. ✅ Code follows VGV patterns exactly
9. ✅ 100% test coverage for data layer
10. ✅ Mock objects behave consistently

**Implementation Priority:** Critical for user authentication

**Quality Gate:** All tests must pass, integration tests required

**Performance Target:** Authentication operations complete in < 5 seconds

---

**Next Step:** After completion, proceed to Authentication Presentation Layer (Phase 2, Step 5)

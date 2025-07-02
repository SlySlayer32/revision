import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:revision/core/services/logging_service.dart';
import 'package:revision/core/services/performance_service.dart';
import 'package:revision/features/authentication/data/models/user_model.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/exceptions/auth_exception.dart';

/// Abstract class that defines the contract for Firebase authentication operations
abstract class FirebaseAuthDataSource {
  /// Stream of auth state changes
  Stream<User?> get authStateChanges;

  /// Sign up with email and password
  Future<User> signUp({
    required String email,
    required String password,
  });

  /// Sign in with email and password
  Future<User> signIn({
    required String email,
    required String password,
  });

  /// Sign in with Google
  Future<User> signInWithGoogle();

  /// Sign out the current user
  Future<void> signOut();

  /// Request password reset email
  Future<void> sendPasswordResetEmail(String email);

  /// Get the current user
  User? get currentUser;

  /// Get current user with custom claims from ID token
  Future<User?> getCurrentUserWithClaims();

  /// Get custom claims for the current user
  Future<Map<String, dynamic>> getCustomClaims();

  /// Send email verification to current user
  Future<void> sendEmailVerification();

  /// Update user profile information
  Future<User> updateUserProfile({
    String? displayName,
    String? photoUrl,
  });

  /// Delete the current user account
  Future<void> deleteAccount();

  /// Reauthenticate user with password
  Future<void> reauthenticateWithPassword({
    required String password,
  });

  /// Get Firebase ID token for API authentication
  Future<String> getIdToken();
}

/// Implementation of FirebaseAuthDataSource that uses Firebase Auth
class FirebaseAuthDataSourceImpl implements FirebaseAuthDataSource {
  /// Creates a new [FirebaseAuthDataSourceImpl]
  FirebaseAuthDataSourceImpl({
    firebase_auth.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  @override
  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      return firebaseUser != null
          ? UserModel.fromFirebaseUser(firebaseUser)
          : null;
    });
  }

  @override
  User? get currentUser {
    final firebaseUser = _firebaseAuth.currentUser;
    return firebaseUser != null
        ? UserModel.fromFirebaseUser(firebaseUser)
        : null;
  }

  /// Get current user with custom claims (async version)
  /// Use this when you need to access custom claims like roles
  Future<User?> get currentUserWithClaims async {
    return getCurrentUserWithClaims();
  }

  @override
  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    return await PerformanceService.instance.timeAsync(
      'auth_sign_in',
      () async {
        try {
          LoggingService.instance
              .info('User sign in attempt', data: {'email': email});

          final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );

          if (userCredential.user == null) {
            throw const UnexpectedAuthException('Sign in failed');
          }

          final user = await _createUserWithClaims(userCredential.user!);
          LoggingService.instance
              .info('User sign in successful', data: {'userId': user.id});

          return user;
        } on firebase_auth.FirebaseAuthException catch (e) {
          LoggingService.instance.warning(
            'Firebase sign in error: ${e.code}',
            error: e,
            data: {'email': email, 'errorCode': e.code},
          );
          throw _mapFirebaseAuthExceptionToDomainException(e);
        } catch (e) {
          LoggingService.instance.error(
            'Unexpected sign in error',
            error: e,
            data: {'email': email},
          );
          throw UnexpectedAuthException(e.toString());
        }
      },
    );
  }

  @override
  Future<User> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw const UnexpectedAuthException('Sign up failed');
      }

      return await _createUserWithClaims(userCredential.user!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      log('Firebase sign up error: ${e.code}', error: e);
      throw _mapFirebaseAuthExceptionToDomainException(e);
    } catch (e) {
      log('Unexpected sign up error', error: e);
      throw UnexpectedAuthException(e.toString());
    }
  }

  @override
  Future<User> signInWithGoogle() async {
    try {
      // Begin interactive sign-in process
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw const UnexpectedAuthException('Google sign in was canceled');
      }

      // Obtain the auth details from the request
      final googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      if (userCredential.user == null) {
        throw const UnexpectedAuthException(
          'Failed to sign in with Google',
        );
      }

      return await _createUserWithClaims(userCredential.user!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      log('Firebase Google sign in error: ${e.code}', error: e);
      throw _mapFirebaseAuthExceptionToDomainException(e);
    } catch (e) {
      log('Unexpected Google sign in error', error: e);
      throw UnexpectedAuthException(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      log('Sign out error', error: e);
      throw UnexpectedAuthException(e.toString());
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      log('Firebase password reset error: ${e.code}', error: e);
      throw _mapFirebaseAuthExceptionToDomainException(e);
    } catch (e) {
      log('Unexpected password reset error', error: e);
      throw UnexpectedAuthException(e.toString());
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const UnexpectedAuthException('No user is currently signed in');
      }

      await user.sendEmailVerification();
      log('Email verification sent to: ${user.email}');
    } on firebase_auth.FirebaseAuthException catch (e) {
      log('Firebase Auth error sending email verification: ${e.code} - ${e.message}');
      throw _mapFirebaseAuthExceptionToDomainException(e);
    } catch (e) {
      log('Unexpected error sending email verification: $e');
      throw UnexpectedAuthException('Failed to send email verification: $e');
    }
  }

  @override
  Future<User> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const UnexpectedAuthException('No user is currently signed in');
      }

      await user.updateDisplayName(displayName);
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }

      // Reload user to get updated information
      await user.reload();
      final updatedUser = _firebaseAuth.currentUser;

      if (updatedUser == null) {
        throw const UnexpectedAuthException('Failed to get updated user');
      }

      log('User profile updated successfully');
      return await _createUserWithClaims(updatedUser);
    } on firebase_auth.FirebaseAuthException catch (e) {
      log('Firebase Auth error updating profile: ${e.code} - ${e.message}');
      throw _mapFirebaseAuthExceptionToDomainException(e);
    } catch (e) {
      log('Unexpected error updating profile: $e');
      throw UnexpectedAuthException('Failed to update user profile: $e');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const UnexpectedAuthException('No user is currently signed in');
      }

      await user.delete();
      log('User account deleted successfully');
    } on firebase_auth.FirebaseAuthException catch (e) {
      log('Firebase Auth error deleting account: ${e.code} - ${e.message}');
      throw _mapFirebaseAuthExceptionToDomainException(e);
    } catch (e) {
      log('Unexpected error deleting account: $e');
      throw UnexpectedAuthException('Failed to delete account: $e');
    }
  }

  @override
  Future<void> reauthenticateWithPassword({
    required String password,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const UnexpectedAuthException('No user is currently signed in');
      }

      if (user.email == null) {
        throw const UnexpectedAuthException('User email is not available');
      }

      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
      log('User reauthenticated successfully');
    } on firebase_auth.FirebaseAuthException catch (e) {
      log('Firebase Auth error reauthenticating: ${e.code} - ${e.message}');
      throw _mapFirebaseAuthExceptionToDomainException(e);
    } catch (e) {
      log('Unexpected error reauthenticating: $e');
      throw UnexpectedAuthException('Failed to reauthenticate: $e');
    }
  }

  // Maps Firebase Auth exceptions to domain exceptions
  AuthException _mapFirebaseAuthExceptionToDomainException(
    firebase_auth.FirebaseAuthException exception,
  ) {
    switch (exception.code) {
      case 'email-already-in-use':
        return const EmailAlreadyInUseException();
      case 'invalid-email':
        return const InvalidEmailException();
      case 'user-disabled':
        return const UserNotFoundException('This account has been disabled');
      case 'user-not-found':
        return const InvalidCredentialsException(); // Security: don't reveal if user exists
      case 'wrong-password':
        return const InvalidCredentialsException();
      case 'weak-password':
        return const WeakPasswordException();
      case 'network-request-failed':
        return const NetworkException();
      case 'operation-not-allowed':
        return const UnexpectedAuthException(
          'This sign in method is not allowed',
        );
      case 'account-exists-with-different-credential':
        return const EmailAlreadyInUseException(
          'Account exists with different credentials',
        );
      case 'invalid-credential':
        return const InvalidCredentialsException('Invalid credentials');
      case 'too-many-requests':
        return const UnexpectedAuthException(
          'Too many attempts. Please try again later',
        );
      default:
        return UnexpectedAuthException(
          'An unexpected error occurred: ${exception.message}',
        );
    }
  }

  @override
  Future<User?> getCurrentUserWithClaims() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    try {
      final customClaims = await getCustomClaims();
      return UserModel.fromFirebaseUserWithClaims(firebaseUser, customClaims);
    } catch (e) {
      log('Error getting user with claims', error: e);
      // Fallback to user without claims
      return UserModel.fromFirebaseUser(firebaseUser);
    }
  }

  @override
  Future<Map<String, dynamic>> getCustomClaims() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return {};

    try {
      final idTokenResult = await firebaseUser.getIdTokenResult();
      return Map<String, dynamic>.from(idTokenResult.claims ?? {});
    } catch (e) {
      log('Error getting custom claims', error: e);
      return {};
    }
  }

  /// Creates a UserModel with custom claims from Firebase User
  Future<UserModel> _createUserWithClaims(
    firebase_auth.User firebaseUser,
  ) async {
    try {
      final customClaims = await getCustomClaims();
      return UserModel.fromFirebaseUserWithClaims(firebaseUser, customClaims);
    } catch (e) {
      log('Error getting custom claims for user', error: e);
      // Fallback to user without claims
      return UserModel.fromFirebaseUser(firebaseUser);
    }
  }

  @override
  Future<String> getIdToken() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      throw const UserNotFoundException('No authenticated user found');
    }

    try {
      final idToken = await firebaseUser.getIdToken();
      if (idToken == null) {
        throw const UnexpectedAuthException('Failed to retrieve ID token');
      }
      return idToken;
    } on firebase_auth.FirebaseAuthException catch (e) {
      log('Error getting ID token', error: e);
      throw _mapFirebaseAuthExceptionToDomainException(e);
    } catch (e) {
      log('Unexpected error getting ID token', error: e);
      throw UnexpectedAuthException('Failed to get ID token: ${e.toString()}');
    }
  }
}

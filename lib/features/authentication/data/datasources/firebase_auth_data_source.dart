import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
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

  @override
  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw const UnexpectedAuthException('Sign in failed');
      }

      return UserModel.fromFirebaseUser(userCredential.user!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      log('Firebase sign in error: ${e.code}', error: e);
      throw _mapFirebaseAuthExceptionToDomainException(e);
    } catch (e) {
      log('Unexpected sign in error', error: e);
      throw UnexpectedAuthException(e.toString());
    }
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

      return UserModel.fromFirebaseUser(userCredential.user!);
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

      return UserModel.fromFirebaseUser(userCredential.user!);
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
        return const UserNotFoundException();
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
}

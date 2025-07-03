import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:revision/core/error/failures.dart';
import 'package:revision/core/services/exception_handler_service.dart';
import 'package:revision/features/authentication/data/datasources/firebase_auth_data_source.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/exceptions/auth_exception.dart';
import 'package:revision/features/authentication/domain/repositories/auth_repository.dart';

/// Implementation of AuthRepository that uses Firebase Auth
class FirebaseAuthenticationRepository implements AuthRepository {
  /// Creates a new [FirebaseAuthenticationRepository]
  FirebaseAuthenticationRepository({
    FirebaseAuthDataSource? firebaseAuthDataSource,
  }) : _dataSource = firebaseAuthDataSource ?? FirebaseAuthDataSourceImpl();

  final FirebaseAuthDataSource _dataSource;

  @override
  Stream<User?> get authStateChanges => _dataSource.authStateChanges;

  @override
  Future<Either<Failure, User>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _dataSource.signIn(
        email: email,
        password: password,
      );
      return Right(user);
    } on AuthException catch (e) {
      log('Sign in auth exception', error: e);
      return Left(AuthenticationFailure(e.message, e.code));
    } catch (e) {
      log('Unexpected sign in error', error: e);
      return Left(AuthenticationFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    try {
      final user = await _dataSource.signInWithGoogle();
      return Right(user);
    } on AuthException catch (e) {
      log('Google sign in auth exception', error: e);
      return Left(AuthenticationFailure(e.message, e.code));
    } catch (e) {
      log('Unexpected Google sign in error', error: e);
      return Left(AuthenticationFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final user = await _dataSource.signUp(
        email: email,
        password: password,
      );
      return Right(user);
    } on AuthException catch (e) {
      log('Sign up auth exception', error: e);
      return Left(AuthenticationFailure(e.message, e.code));
    } catch (e) {
      log('Unexpected sign up error', error: e);
      return Left(AuthenticationFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _dataSource.signOut();
      return const Right(null);
    } on AuthException catch (e) {
      log('Sign out auth exception', error: e);
      return Left(AuthenticationFailure(e.message, e.code));
    } catch (e) {
      log('Unexpected sign out error', error: e);
      return Left(AuthenticationFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final user = _dataSource.currentUser;
      return Right(user);
    } catch (e) {
      log('Unexpected error getting current user', error: e);
      return Left(AuthenticationFailure('Failed to get current user: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _dataSource.sendPasswordResetEmail(email);
      return const Right(null);
    } on AuthException catch (e) {
      log('Password reset auth exception', error: e);
      return Left(AuthenticationFailure(e.message, e.code));
    } catch (e) {
      log('Unexpected password reset error', error: e);
      return Left(AuthenticationFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendEmailVerification() async {
    try {
      await _dataSource.sendEmailVerification();
      return const Right(null);
    } on AuthException catch (e) {
      log('Email verification auth exception', error: e);
      return Left(AuthenticationFailure(e.message, e.code));
    } catch (e) {
      log('Unexpected email verification error', error: e);
      return Left(AuthenticationFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final user = await _dataSource.updateUserProfile(
        displayName: displayName,
        photoUrl: photoUrl,
      );
      return Right(user);
    } on AuthException catch (e) {
      log('Update profile auth exception', error: e);
      return Left(AuthenticationFailure(e.message, e.code));
    } catch (e) {
      log('Unexpected update profile error', error: e);
      return Left(AuthenticationFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      await _dataSource.deleteAccount();
      return const Right(null);
    } on AuthException catch (e) {
      log('Delete account auth exception', error: e);
      return Left(AuthenticationFailure(e.message, e.code));
    } catch (e) {
      log('Unexpected delete account error', error: e);
      return Left(AuthenticationFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> reauthenticateWithPassword({
    required String password,
  }) async {
    try {
      await _dataSource.reauthenticateWithPassword(password: password);
      return const Right(null);
    } on AuthException catch (e) {
      log('Reauthenticate auth exception', error: e);
      return Left(AuthenticationFailure(e.message, e.code));
    } catch (e) {
      log('Unexpected reauthenticate error', error: e);
      return Left(AuthenticationFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> getIdToken() async {
    try {
      final idToken = await _dataSource.getIdToken();
      return Right(idToken);
    } on AuthException catch (e) {
      log('Get ID token auth exception', error: e);
      return Left(AuthenticationFailure(e.message, e.code));
    } catch (e) {
      log('Unexpected get ID token error', error: e);
      return Left(AuthenticationFailure(e.toString()));
    }
  }
}

import 'dart:developer';

import 'package:revision/core/utils/result.dart';
import 'package:revision/features/authentication/data/datasources/firebase_auth_data_source.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/exceptions/auth_exception.dart';
import 'package:revision/features/authentication/domain/repositories/authentication_repository.dart';

/// Implementation of AuthenticationRepository that uses Firebase Auth
class FirebaseAuthenticationRepository implements AuthenticationRepository {
  /// Creates a new [FirebaseAuthenticationRepository]
  FirebaseAuthenticationRepository({
    FirebaseAuthDataSource? firebaseAuthDataSource,
  }) : _dataSource = firebaseAuthDataSource ?? FirebaseAuthDataSourceImpl();

  final FirebaseAuthDataSource _dataSource;

  @override
  Stream<User?> get authStateChanges => _dataSource.authStateChanges;

  @override
  User? get currentUser => _dataSource.currentUser;

  @override
  Future<Result<User>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _dataSource.signIn(
        email: email,
        password: password,
      );
      return Success(user);
    } on AuthException catch (e) {
      log('Sign in auth exception', error: e);
      return Failure(e);
    } catch (e) {
      log('Unexpected sign in error', error: e);
      return Failure(UnexpectedAuthException(e.toString()));
    }
  }

  @override
  Future<Result<User>> signInWithGoogle() async {
    try {
      final user = await _dataSource.signInWithGoogle();
      return Success(user);
    } on AuthException catch (e) {
      log('Google sign in auth exception', error: e);
      return Failure(e);
    } catch (e) {
      log('Unexpected Google sign in error', error: e);
      return Failure(UnexpectedAuthException(e.toString()));
    }
  }

  @override
  Future<Result<User>> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _dataSource.signUp(
        email: email,
        password: password,
      );
      return Success(user);
    } on AuthException catch (e) {
      log('Sign up auth exception', error: e);
      return Failure(e);
    } catch (e) {
      log('Unexpected sign up error', error: e);
      return Failure(UnexpectedAuthException(e.toString()));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _dataSource.signOut();
      return const Success(null);
    } on AuthException catch (e) {
      log('Sign out auth exception', error: e);
      return Failure(e);
    } catch (e) {
      log('Unexpected sign out error', error: e);
      return Failure(UnexpectedAuthException(e.toString()));
    }
  }

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    try {
      await _dataSource.sendPasswordResetEmail(email);
      return const Success(null);
    } on AuthException catch (e) {
      log('Password reset auth exception', error: e);
      return Failure(e);
    } catch (e) {
      log('Unexpected password reset error', error: e);
      return Failure(UnexpectedAuthException(e.toString()));
    }
  }
}

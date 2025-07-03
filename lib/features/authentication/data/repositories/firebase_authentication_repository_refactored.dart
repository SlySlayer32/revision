import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:revision/core/error/failures.dart';
import 'package:revision/features/authentication/data/datasources/firebase_auth_data_source.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/exceptions/auth_exception.dart';
import 'package:revision/features/authentication/domain/repositories/auth_repository.dart';

/// A mixin that provides common exception handling for authentication operations
mixin AuthExceptionHandler {
  /// Wraps an authentication operation with standardized exception handling
  Future<Either<Failure, T>> handleAuthOperation<T>(
    Future<T> Function() operation, {
    required String operationName,
    Map<String, dynamic>? context,
  }) async {
    try {
      final result = await operation();
      return Right(result);
    } on AuthException catch (e) {
      final contextInfo = context != null ? ' - Context: $context' : '';
      log('$operationName auth exception: ${e.code}$contextInfo', error: e);
      return Left(AuthenticationFailure(e.message, e.code));
    } catch (e) {
      final contextInfo = context != null ? ' - Context: $context' : '';
      log('Unexpected $operationName error$contextInfo', error: e);
      return Left(AuthenticationFailure(e.toString()));
    }
  }

  /// Wraps a void authentication operation with standardized exception handling
  Future<Either<Failure, void>> handleVoidAuthOperation(
    Future<void> Function() operation, {
    required String operationName,
    Map<String, dynamic>? context,
  }) async {
    try {
      await operation();
      return const Right(null);
    } on AuthException catch (e) {
      final contextInfo = context != null ? ' - Context: $context' : '';
      log('$operationName auth exception: ${e.code}$contextInfo', error: e);
      return Left(AuthenticationFailure(e.message, e.code));
    } catch (e) {
      final contextInfo = context != null ? ' - Context: $context' : '';
      log('Unexpected $operationName error$contextInfo', error: e);
      return Left(AuthenticationFailure(e.toString()));
    }
  }
}

/// Implementation of AuthRepository that uses Firebase Auth
class FirebaseAuthenticationRepository
    with AuthExceptionHandler
    implements AuthRepository {
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
    return handleAuthOperation(
      () => _dataSource.signIn(email: email, password: password),
      operationName: 'Sign in',
      context: {'email': email},
    );
  }

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    return handleAuthOperation(
      () => _dataSource.signInWithGoogle(),
      operationName: 'Google sign in',
    );
  }

  @override
  Future<Either<Failure, User>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    return handleAuthOperation(
      () => _dataSource.signUp(email: email, password: password),
      operationName: 'Sign up',
      context: {'email': email, 'hasDisplayName': displayName != null},
    );
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    return handleVoidAuthOperation(
      () => _dataSource.signOut(),
      operationName: 'Sign out',
    );
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
    return handleVoidAuthOperation(
      () => _dataSource.sendPasswordResetEmail(email),
      operationName: 'Password reset',
      context: {'email': email},
    );
  }

  @override
  Future<Either<Failure, void>> sendEmailVerification() async {
    return handleVoidAuthOperation(
      () => _dataSource.sendEmailVerification(),
      operationName: 'Email verification',
    );
  }

  @override
  Future<Either<Failure, User>> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    return handleAuthOperation(
      () => _dataSource.updateUserProfile(
        displayName: displayName,
        photoUrl: photoUrl,
      ),
      operationName: 'Update profile',
      context: {
        'hasDisplayName': displayName != null,
        'hasPhotoUrl': photoUrl != null,
      },
    );
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    return handleVoidAuthOperation(
      () => _dataSource.deleteAccount(),
      operationName: 'Delete account',
    );
  }

  @override
  Future<Either<Failure, void>> reauthenticateWithPassword({
    required String password,
  }) async {
    return handleVoidAuthOperation(
      () => _dataSource.reauthenticateWithPassword(password: password),
      operationName: 'Reauthenticate',
    );
  }

  @override
  Future<Either<Failure, String>> getIdToken() async {
    return handleAuthOperation(
      () => _dataSource.getIdToken(),
      operationName: 'Get ID token',
      context: {},
    );
  }
}

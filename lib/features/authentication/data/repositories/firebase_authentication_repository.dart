import 'package:dartz/dartz.dart';
import 'package:revision/core/error/failures.dart';
import 'package:revision/core/services/exception_handler_service.dart';
import 'package:revision/features/authentication/data/datasources/firebase_auth_data_source.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/repositories/auth_repository.dart';

/// Implementation of AuthRepository that uses Firebase Auth
class FirebaseAuthenticationRepository implements AuthRepository {
  /// Creates a new [FirebaseAuthenticationRepository]
  FirebaseAuthenticationRepository({
    FirebaseAuthDataSource? firebaseAuthDataSource,
    ExceptionHandlerService? exceptionHandler,
  })  : _dataSource = firebaseAuthDataSource ?? FirebaseAuthDataSourceImpl(),
        _exceptionHandler = exceptionHandler ?? ExceptionHandlerService();

  final FirebaseAuthDataSource _dataSource;
  final ExceptionHandlerService _exceptionHandler;

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
    } catch (e) {
      final failure = _exceptionHandler.handleAuthException(
        'signInWithEmailAndPassword',
        e,
        context: {'email': email, 'hasPassword': password.isNotEmpty},
      );
      return Left(failure);
    }
  }

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    try {
      final user = await _dataSource.signInWithGoogle();
      return Right(user);
    } catch (e) {
      final failure = _exceptionHandler.handleAuthException(
        'signInWithGoogle',
        e,
      );
      return Left(failure);
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
    } catch (e) {
      final failure = _exceptionHandler.handleAuthException(
        'signUpWithEmailAndPassword',
        e,
        context: {
          'email': email,
          'hasPassword': password.isNotEmpty,
          'hasDisplayName': displayName?.isNotEmpty ?? false,
        },
      );
      return Left(failure);
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _dataSource.signOut();
      return const Right(null);
    } catch (e) {
      final failure = _exceptionHandler.handleAuthException(
        'signOut',
        e,
      );
      return Left(failure);
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final user = _dataSource.currentUser;
      return Right(user);
    } catch (e) {
      final failure = _exceptionHandler.handleAuthException(
        'getCurrentUser',
        e,
      );
      return Left(failure);
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _dataSource.sendPasswordResetEmail(email);
      return const Right(null);
    } catch (e) {
      final failure = _exceptionHandler.handleAuthException(
        'sendPasswordResetEmail',
        e,
        context: {'email': email},
      );
      return Left(failure);
    }
  }

  @override
  Future<Either<Failure, void>> sendEmailVerification() async {
    try {
      await _dataSource.sendEmailVerification();
      return const Right(null);
    } catch (e) {
      final failure = _exceptionHandler.handleAuthException(
        'sendEmailVerification',
        e,
      );
      return Left(failure);
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
    } catch (e) {
      final failure = _exceptionHandler.handleAuthException(
        'updateUserProfile',
        e,
        context: {
          'hasDisplayName': displayName?.isNotEmpty ?? false,
          'hasPhotoUrl': photoUrl?.isNotEmpty ?? false,
        },
      );
      return Left(failure);
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      await _dataSource.deleteAccount();
      return const Right(null);
    } catch (e) {
      final failure = _exceptionHandler.handleAuthException(
        'deleteAccount',
        e,
      );
      return Left(failure);
    }
  }

  @override
  Future<Either<Failure, void>> reauthenticateWithPassword({
    required String password,
  }) async {
    try {
      await _dataSource.reauthenticateWithPassword(password: password);
      return const Right(null);
    } catch (e) {
      final failure = _exceptionHandler.handleAuthException(
        'reauthenticateWithPassword',
        e,
        context: {'hasPassword': password.isNotEmpty},
      );
      return Left(failure);
    }
  }

  @override
  Future<Either<Failure, String>> getIdToken() async {
    try {
      final idToken = await _dataSource.getIdToken();
      return Right(idToken);
    } catch (e) {
      final failure = _exceptionHandler.handleAuthException(
        'getIdToken',
        e,
      );
      return Left(failure);
    }
  }
}

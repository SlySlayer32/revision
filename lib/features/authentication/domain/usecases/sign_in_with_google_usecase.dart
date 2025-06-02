import 'package:dartz/dartz.dart';
import 'package:revision/core/error/failures.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/repositories/auth_repository.dart';

/// Use case for signing in with Google
class SignInWithGoogleUseCase {
  /// Creates a new [SignInWithGoogleUseCase]
  const SignInWithGoogleUseCase(this._repository);

  final AuthRepository _repository;

  /// Signs in the user with Google account
  Future<Either<Failure, User>> call() => _repository.signInWithGoogle();
}

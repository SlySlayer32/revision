import 'package:dartz/dartz.dart';
import 'package:revision/core/error/failures.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/repositories/auth_repository.dart';

/// Use case for registering a new user with email and password
class SignUpUseCase {
  /// Creates a new [SignUpUseCase] with the provided [authRepository]
  const SignUpUseCase(this._authRepository);

  final AuthRepository _authRepository;

  /// Registers a new user with email and password
  ///
  /// Returns an [Either] that is either a [Failure] or success with a [User]
  Future<Either<Failure, User>> call({
    required String email,
    required String password,
    String? displayName,
  }) async {
    return _authRepository.signUpWithEmailAndPassword(
      email: email,
      password: password,
      displayName: displayName,
    );
  }
}

import 'package:dartz/dartz.dart';
import 'package:revision/core/error/failures.dart';
import 'package:revision/features/authentication/domain/repositories/auth_repository.dart';

/// Use case for signing out the current user
class SignOutUseCase {
  /// Creates a new [SignOutUseCase] with the provided [authRepository]
  const SignOutUseCase(this._authRepository);

  final AuthRepository _authRepository;

  /// Signs out the current user
  ///
  /// Returns an [Either] that is either a [Failure] or success with void
  Future<Either<Failure, void>> call() async {
    return _authRepository.signOut();
  }
}

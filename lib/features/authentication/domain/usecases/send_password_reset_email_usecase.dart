import 'package:dartz/dartz.dart';
import 'package:revision/core/error/failures.dart';
import 'package:revision/features/authentication/domain/repositories/auth_repository.dart';

/// Use case for sending a password reset email
class SendPasswordResetEmailUseCase {
  /// Creates a new [SendPasswordResetEmailUseCase] with the provided [_authenticationRepository]
  const SendPasswordResetEmailUseCase(this._authenticationRepository);

  final AuthRepository _authenticationRepository;

  /// Sends a password reset email to the provided email address
  ///
  /// Returns an [Either] that is either a [Failure] or success with void
  Future<Either<Failure, void>> call(String email) async {
    return _authenticationRepository.sendPasswordResetEmail(email: email);
  }
}

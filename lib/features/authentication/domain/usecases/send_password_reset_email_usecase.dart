import 'package:revision/core/utils/result.dart';
import 'package:revision/features/authentication/domain/repositories/authentication_repository.dart';

/// Use case for sending a password reset email
class SendPasswordResetEmailUseCase {
  /// Creates a new [SendPasswordResetEmailUseCase] with the provided [_authenticationRepository]
  const SendPasswordResetEmailUseCase(this._authenticationRepository);

  final AuthenticationRepository _authenticationRepository;

  /// Sends a password reset email to the provided email address
  ///
  /// Returns a [Result] that is either a [Success] with void
  /// or a [Failure] with an exception
  Future<Result<void>> call(String email) async {
    return _authenticationRepository.sendPasswordResetEmail(email);
  }
}

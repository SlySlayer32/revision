import 'package:revision/core/utils/result.dart';
import 'package:revision/features/authentication/domain/repositories/auth_repository.dart';

/// Use case for sending email verification
class SendEmailVerificationUseCase {
  /// Creates a new [SendEmailVerificationUseCase]
  const SendEmailVerificationUseCase(this._repository);

  final AuthRepository _repository;

  /// Sends email verification to the currently signed-in user
  Future<Result<void>> call() async {
    final either = await _repository.sendEmailVerification();
    return either.fold(
      (failure) => Result.error(failure),
      (_) => Result.ok(null),
    );
  }
}

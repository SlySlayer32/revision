import 'package:revision/core/utils/result.dart';
import 'package:revision/features/authentication/domain/repositories/auth_repository.dart';
import 'package:logger/logger.dart';

/// Use case for sending email verification to the currently signed-in user.
///
/// This use case encapsulates the logic for triggering an email verification
/// through the [AuthRepository]. It returns a [Result] indicating success or failure.
class SendEmailVerificationUseCase {
  /// Creates a new [SendEmailVerificationUseCase].
  ///
  /// @param repository The authentication repository dependency.
  const SendEmailVerificationUseCase(this._repository);

  final AuthRepository _repository;

  /// Sends email verification to the currently signed-in user.
  ///
  /// @returns [Result<void>] indicating success or failure.
  Future<Result<void>> call() async {
    try {
      final either = await _repository.sendEmailVerification();
      return either.fold(
        (failure) {
          Logger().e('SendEmailVerification failed', failure);
          return Result.failure(failure);
        },
        (_) => const Result.success(null),
      );
    } catch (e, stack) {
      Logger().e('Unexpected error in SendEmailVerificationUseCase', e, stack);
      return Result.failure(Exception('Unexpected error occurred'));
    }
  }
}

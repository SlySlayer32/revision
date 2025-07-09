import 'package:dartz/dartz.dart';
import 'package:revision/core/failure/failure.dart';
import 'package:revision/features/authentication/domain/repositories/auth_repository.dart';

/// Use case for sending email verification
class SendEmailVerificationUseCase {
  /// Creates a new [SendEmailVerificationUseCase]
  const SendEmailVerificationUseCase(this._repository);

  final AuthRepository _repository;

  /// Sends email verification to the currently signed-in user
  Future<Either<Failure, void>> call() async {
    return await _repository.sendEmailVerification();
  }
}
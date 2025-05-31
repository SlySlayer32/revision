import 'package:revision/core/utils/result.dart';
import 'package:revision/features/authentication/domain/repositories/authentication_repository.dart';

/// Use case for signing out the current user
class SignOutUseCase {
  /// Creates a new [SignOutUseCase] with the provided [authenticationRepository]
  const SignOutUseCase(this._authenticationRepository);

  final AuthenticationRepository _authenticationRepository;

  /// Signs out the current user
  ///
  /// Returns a [Result] that is either a [Success] with void
  /// or a [Failure] with an exception
  Future<Result<void>> call() async {
    return _authenticationRepository.signOut();
  }
}

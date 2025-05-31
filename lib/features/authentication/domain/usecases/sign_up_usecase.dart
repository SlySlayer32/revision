import 'package:revision/core/utils/result.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/repositories/authentication_repository.dart';

/// Use case for registering a new user with email and password
class SignUpUseCase {
  /// Creates a new [SignUpUseCase] with the provided [authenticationRepository]
  const SignUpUseCase(this._authenticationRepository);

  final AuthenticationRepository _authenticationRepository;

  /// Registers a new user with email and password
  ///
  /// Returns a [Result] that is either a [Success] with a [User]
  /// or a [Failure] with an exception
  Future<Result<User>> call({
    required String email,
    required String password,
  }) async {
    return _authenticationRepository.signUp(
      email: email,
      password: password,
    );
  }
}

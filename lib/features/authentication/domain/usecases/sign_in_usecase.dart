import 'package:revision/core/utils/result.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/repositories/authentication_repository.dart';

/// Use case for signing in a user with email and password
class SignInUseCase {
  /// Creates a new [SignInUseCase] with the provided [authenticationRepository]
  const SignInUseCase(this._authenticationRepository);

  final AuthenticationRepository _authenticationRepository;

  /// Signs in a user with email and password
  ///
  /// Returns a [Result] that is either a [Success] with a [User]
  /// or a [Failure] with an exception
  Future<Result<User>> call({
    required String email,
    required String password,
  }) async {
    return _authenticationRepository.signIn(
      email: email,
      password: password,
    );
  }
}

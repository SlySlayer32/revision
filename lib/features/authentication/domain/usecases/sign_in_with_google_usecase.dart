import 'package:revision/core/utils/result.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/repositories/authentication_repository.dart';

/// Use case for signing in with Google
class SignInWithGoogleUseCase {
  /// Creates a new [SignInWithGoogleUseCase]
  const SignInWithGoogleUseCase(this._repository);

  final AuthenticationRepository _repository;

  /// Signs in the user with Google account
  Future<Result<User>> call() => _repository.signInWithGoogle();
}

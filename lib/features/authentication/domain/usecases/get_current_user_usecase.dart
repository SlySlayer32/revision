import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/repositories/authentication_repository.dart';

/// Use case for getting the current authenticated user
class GetCurrentUserUseCase {
  /// Creates a new [GetCurrentUserUseCase] with the provided [_authenticationRepository]
  const GetCurrentUserUseCase(this._authenticationRepository);

  final AuthenticationRepository _authenticationRepository;

  /// Returns the current authenticated user or null if not authenticated
  User? call() {
    return _authenticationRepository.currentUser;
  }
}

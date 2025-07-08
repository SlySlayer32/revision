import 'package:dartz/dartz.dart';
import 'package:revision/core/error/failures.dart';
import 'package:revision/features/authentication/domain/repositories/auth_repository.dart';

/// Use case for getting custom claims for the current authenticated user
/// Note: This functionality is now integrated into the User entity via getCurrentUser
class GetCustomClaimsUseCase {
  /// Creates a new [GetCustomClaimsUseCase] with the provided [_authRepository]
  const GetCustomClaimsUseCase(this._authRepository);

  final AuthRepository _authRepository;

  /// Returns the custom claims for the current authenticated user
  /// This method extracts claims from the current user entity
  Future<Either<Failure, Map<String, dynamic>>> call() async {
    final result = await _authRepository.getCurrentUser();
    return result.fold(Left.new, (user) => Right(user?.customClaims ?? {}));
  }
}

import 'package:dartz/dartz.dart';
import 'package:revision/core/error/failures.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/repositories/auth_repository.dart';

/// Use case for getting the current authenticated user
class GetCurrentUserWithClaimsUseCase {
  /// Creates a new [GetCurrentUserWithClaimsUseCase] with the provided [_authRepository]
  const GetCurrentUserWithClaimsUseCase(this._authRepository);

  final AuthRepository _authRepository;

  /// Returns the current authenticated user or null if not authenticated
  Future<Either<Failure, User?>> call() async {
    return _authRepository.getCurrentUser();
  }
}

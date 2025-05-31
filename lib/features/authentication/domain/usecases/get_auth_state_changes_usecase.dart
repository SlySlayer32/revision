import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/repositories/authentication_repository.dart';

/// Use case for getting authentication state changes
class GetAuthStateChangesUseCase {
  /// Creates a new [GetAuthStateChangesUseCase]
  const GetAuthStateChangesUseCase(this._repository);

  final AuthenticationRepository _repository;

  /// Gets the stream of authentication state changes
  Stream<User?> call() => _repository.authStateChanges;
}

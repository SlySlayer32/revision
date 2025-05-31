import 'package:revision/core/utils/result.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';

/// Abstract class that defines the contract for authentication operations
abstract class AuthenticationRepository {
  /// Stream of auth state changes
  Stream<User?> get authStateChanges;

  /// Sign up with email and password
  Future<Result<User>> signUp({
    required String email,
    required String password,
  });

  /// Sign in with email and password
  Future<Result<User>> signIn({
    required String email,
    required String password,
  });

  /// Sign out the current user
  Future<Result<void>> signOut();

  /// Request password reset email
  Future<Result<void>> sendPasswordResetEmail(String email);

  /// Get the current user
  User? get currentUser;

  /// Sign in with Google account
  Future<Result<User>> signInWithGoogle();
}

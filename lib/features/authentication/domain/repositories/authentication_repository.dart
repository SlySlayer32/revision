import 'package:firebase_auth/firebase_auth.dart';

/// Abstract class that defines the contract for authentication operations
abstract class AuthenticationRepository {
  /// Stream of auth state changes
  Stream<User?> get authStateChanges;

  /// Sign up with email and password
  Future<UserCredential> signUp({
    required String email,
    required String password,
  });

  /// Sign in with email and password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  });

  /// Sign out the current user
  Future<void> signOut();

  /// Request password reset email
  Future<void> sendPasswordResetEmail(String email);

  /// Get the current user
  User? get currentUser;
}

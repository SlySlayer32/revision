import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:revision/core/error/failures.dart';

import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Mock authentication repository for MVP demo
class MockAuthenticationRepository implements AuthRepository {
  static const User _mockUser = User(
    id: 'mock_user_123',
    email: 'demo@example.com',
    displayName: 'Demo User',
    photoUrl: null,
    isEmailVerified: true,
    createdAt: '2025-06-15T10:00:00Z',
    customClaims: <String, dynamic>{},
  );

  bool _isLoggedIn = false;
  final StreamController<User?> _authStateController =
      StreamController<User?>.broadcast();

  @override
  Stream<User?> get authStateChanges => _authStateController.stream;

  @override
  Future<Either<Failure, User>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 1));

    // Simple validation for demo
    if (email.isNotEmpty && password.length >= 6) {
      _isLoggedIn = true;
      final user = _mockUser.copyWith(email: email);
      _authStateController.add(user);
      return Right(user);
    }

    return const Left(AuthenticationFailure('Invalid credentials'));
  }

  @override
  Future<Either<Failure, User>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 1));

    if (email.isNotEmpty && password.length >= 6) {
      _isLoggedIn = true;
      final user = _mockUser.copyWith(
        email: email,
        displayName: displayName ?? 'Demo User',
      );
      _authStateController.add(user);
      return Right(user);
    }

    return const Left(AuthenticationFailure('Invalid registration data'));
  }

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    _isLoggedIn = true;
    _authStateController.add(_mockUser);
    return const Right(_mockUser);
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _isLoggedIn = false;
    _authStateController.add(null);
    return const Right(null);
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    return Right(_isLoggedIn ? _mockUser : null);
  }

  @override
  Future<Either<Failure, void>> sendEmailVerification() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail({
    required String email,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return const Right(null);
  }

  @override
  Future<Either<Failure, User>> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final updatedUser = _mockUser.copyWith(
      displayName: displayName,
      photoUrl: photoUrl,
    );
    _authStateController.add(updatedUser);
    return Right(updatedUser);
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _isLoggedIn = false;
    _authStateController.add(null);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> reauthenticateWithPassword({
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (password.length >= 6) {
      return const Right(null);
    }
    return const Left(AuthenticationFailure('Invalid password'));
  }

  void dispose() {
    _authStateController.close();
  }
}

// VGV-compliant mock classes for testing
// Following Very Good Ventures testing patterns

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart' hide State; // dartz also has a State class
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:mocktail/mocktail.dart';
import 'package:revision/core/error/failures.dart';
// No longer using custom Result for repository mocks, using Either instead.
// import 'package:revision/core/utils/result.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/repositories/auth_repository.dart';
import 'package:revision/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:revision/features/authentication/presentation/blocs/login_bloc.dart';
import 'package:revision/features/authentication/presentation/blocs/signup_bloc.dart';

// Core Mocks
// class MockResult<T> extends Mock implements Result<T> {} // Removed as Result is sealed and we use Either

// Authentication Domain Mocks
class MockAuthRepository extends Mock implements AuthRepository {}

class MockUser extends Mock implements User {}

// Firebase Mocks
class MockFirebaseAuth extends Mock implements firebase_auth.FirebaseAuth {}

class MockFirebaseUser extends Mock implements firebase_auth.User {}

class MockUserCredential extends Mock implements firebase_auth.UserCredential {}

class MockAuthCredential extends Mock implements firebase_auth.AuthCredential {}

// Use Case Mocks
abstract class MockUseCase<Type, Params> extends Mock {
  Future<Type> call(Params params);
}

abstract class MockUseCaseNoParams<Type> extends Mock {
  Future<Type> call();
}

abstract class MockStreamUseCase<Type, Params> extends Mock {
  Stream<Type> call(Params params);
}

abstract class MockStreamUseCaseNoParams<Type> extends Mock {
  Stream<Type> call();
}

// Authentication Use Case Mocks
class MockSignInUseCase extends Mock
    implements MockUseCase<Either<Failure, User>, Map<String, String>> {}

class MockSignUpUseCase extends Mock
    implements MockUseCase<Either<Failure, User>, Map<String, String>> {}

class MockSignOutUseCase extends Mock
    implements MockUseCaseNoParams<Either<Failure, void>> {}

class MockGetCurrentUserUseCase extends Mock
    implements MockUseCaseNoParams<Either<Failure, User?>> {}

class MockGetAuthStateChangesUseCase
    extends Mock // This one returns a direct Stream<User?>, not Either
    implements
        MockStreamUseCaseNoParams<User?> {}

// BLoC Mocks
class MockAuthenticationBloc
    extends MockBloc<AuthenticationEvent, AuthenticationState>
    implements AuthenticationBloc {}

class MockLoginBloc extends MockBloc<LoginEvent, LoginState>
    implements LoginBloc {}

class MockSignupBloc extends MockBloc<SignupEvent, SignupState>
    implements SignupBloc {}

// Generic Mocks for testing
class MockFunction extends Mock {
  void call();
}

class MockFunction1<T> extends Mock {
  void call(T arg);
}

class MockFunction2<T1, T2> extends Mock {
  void call(T1 arg1, T2 arg2);
}

// VGV Test Data Factory
class VGVTestDataFactory {
  static User createTestUser({
    String id = 'test-user-id',
    String email = 'test@example.com',
    String displayName = 'Test User',
    bool isEmailVerified = true,
    String? photoUrl, // Can be null
    String createdAt = '2023-01-01T00:00:00Z',
    Map<String, dynamic> customClaims = const {},
  }) {
    return User(
      id: id,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      isEmailVerified: isEmailVerified,
      createdAt: createdAt,
      customClaims: customClaims,
    );
  }

  static firebase_auth.User createMockFirebaseUser({
    String uid = 'test-user-id',
    String email = 'test@example.com',
    String displayName = 'Test User',
    bool emailVerified = true,
  }) {
    final user = MockFirebaseUser();
    when(() => user.uid).thenReturn(uid);
    when(() => user.email).thenReturn(email);
    when(() => user.displayName).thenReturn(displayName);
    when(() => user.emailVerified).thenReturn(emailVerified);
    return user;
  }

  static Exception createTestException([String message = 'Test error']) {
    return Exception(message);
  }

  static firebase_auth.FirebaseAuthException createFirebaseAuthException({
    String code = 'test-error',
    String message = 'Test Firebase error',
  }) {
    return firebase_auth.FirebaseAuthException(
      code: code,
      message: message,
    );
  }
}

// VGV Mock Setup Helpers
class VGVMockSetup {
  /// Sets up mock authentication repository for successful operations
  static void setupSuccessfulAuthRepository(MockAuthRepository mockRepository) {
    final testUser = VGVTestDataFactory.createTestUser();
    // const testUserNull = null; // For cases where User? is null // Removed as unused

    // Sign in success
    when(
      () => mockRepository.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => Right<Failure, User>(testUser));

    // Sign up success
    when(
      () => mockRepository.signUpWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
        displayName: any(named: 'displayName'),
      ),
    ).thenAnswer((_) async => Right<Failure, User>(testUser));

    // Sign out success
    when(() => mockRepository.signOut()).thenAnswer(
      (_) async => const Right<Failure, void>(null),
    ); // void is represented by null in Right

    // Get current user success (returning a User)
    when(() => mockRepository.getCurrentUser())
        .thenAnswer((_) async => Right<Failure, User?>(testUser));

    // Example for Get current user success (returning null User)
    // when(() => mockRepository.getCurrentUser())
    //     .thenAnswer((_) async => const Right<Failure, User?>(null)); // Directly use null

    // Auth state changes success
    when(() => mockRepository.authStateChanges) // Corrected to getter
        .thenAnswer((_) => Stream.value(testUser));
  }

  /// Sets up mock authentication repository for error scenarios
  static void setupErrorAuthRepository(MockAuthRepository mockRepository) {
    // Using specific Failure types as per AuthRepository contract
    const authFailure = AuthenticationFailure('Generic auth error');

    // All operations fail
    when(
      () => mockRepository.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => const Left<Failure, User>(authFailure));

    when(
      () => mockRepository.signUpWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
        displayName: any(named: 'displayName'),
      ),
    ).thenAnswer((_) async => const Left<Failure, User>(authFailure));

    when(() => mockRepository.signOut())
        .thenAnswer((_) async => const Left<Failure, void>(authFailure));

    when(() => mockRepository.getCurrentUser())
        .thenAnswer((_) async => const Left<Failure, User?>(authFailure));

    when(() => mockRepository.authStateChanges) // Corrected to getter
        .thenAnswer(
      (_) => Stream<User?>.error(authFailure),
    ); // Explicit type for Stream.error
  }
}

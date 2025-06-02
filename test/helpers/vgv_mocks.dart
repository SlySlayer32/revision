// VGV-compliant mock classes for testing
// Following Very Good Ventures testing patterns

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:mocktail/mocktail.dart';
import 'package:revision/core/utils/result.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/repositories/auth_repository.dart';

// Core Mocks
class MockResult<T> extends Mock implements Result<T> {}

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
    implements MockUseCase<Result<User>, Map<String, String>> {}

class MockSignUpUseCase extends Mock
    implements MockUseCase<Result<User>, Map<String, String>> {}

class MockSignOutUseCase extends Mock
    implements MockUseCaseNoParams<Result<void>> {}

class MockGetCurrentUserUseCase extends Mock
    implements MockUseCaseNoParams<Result<User?>> {}

class MockGetAuthStateChangesUseCase extends Mock
    implements MockStreamUseCaseNoParams<User?> {}

// BLoC Mocks
class MockAuthenticationBloc extends MockBloc<dynamic, dynamic>
    implements Bloc<dynamic, dynamic> {}

class MockLoginBloc extends MockBloc<dynamic, dynamic>
    implements Bloc<dynamic, dynamic> {}

class MockSignupBloc extends MockBloc<dynamic, dynamic>
    implements Bloc<dynamic, dynamic> {}

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
  }) {
    return User(
      id: id,
      email: email,
      displayName: displayName,
      isEmailVerified: isEmailVerified,
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

    // Sign in success
    when(
      () => mockRepository.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => Result.success(testUser));

    // Sign up success
    when(
      () => mockRepository.signUpWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
        displayName: any(named: 'displayName'),
      ),
    ).thenAnswer((_) async => Result.success(testUser));

    // Sign out success
    when(() => mockRepository.signOut())
        .thenAnswer((_) async => const Result.success(null));

    // Get current user success
    when(() => mockRepository.getCurrentUser())
        .thenAnswer((_) async => Result.success(testUser));

    // Auth state changes success
    when(() => mockRepository.getAuthStateChanges())
        .thenAnswer((_) => Stream.value(testUser));
  }

  /// Sets up mock authentication repository for error scenarios
  static void setupErrorAuthRepository(MockAuthRepository mockRepository) {
    final exception = VGVTestDataFactory.createTestException();

    // All operations fail
    when(
      () => mockRepository.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => Result.failure(exception));

    when(
      () => mockRepository.signUpWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
        displayName: any(named: 'displayName'),
      ),
    ).thenAnswer((_) async => Result.failure(exception));

    when(() => mockRepository.signOut())
        .thenAnswer((_) async => Result.failure(exception));

    when(() => mockRepository.getCurrentUser())
        .thenAnswer((_) async => Result.failure(exception));

    when(() => mockRepository.getAuthStateChanges())
        .thenAnswer((_) => Stream.error(exception));
  }
}

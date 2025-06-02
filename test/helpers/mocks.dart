// VGV-compliant mock classes for testing
// Following Very Good Ventures testing patterns

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:mocktail/mocktail.dart';
import 'package:revision/core/utils/result.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/repositories/auth_repository.dart';

// VGV Pattern: Core Mocks
class MockResult<T> extends Mock implements Result<T> {}

// VGV Pattern: Authentication Domain Mocks
class MockAuthRepository extends Mock implements AuthRepository {}

class MockUser extends Mock implements User {}

// VGV Pattern: Firebase Mocks
class MockFirebaseAuth extends Mock implements firebase_auth.FirebaseAuth {}

class MockFirebaseUser extends Mock implements firebase_auth.User {}

class MockUserCredential extends Mock implements firebase_auth.UserCredential {}

class MockAuthCredential extends Mock implements firebase_auth.AuthCredential {}

// VGV Pattern: Use Case Mocks
class MockSignInUseCase extends Mock {
  Future<Result<User>> call(Map<String, String> params);
}

class MockSignUpUseCase extends Mock {
  Future<Result<User>> call(Map<String, String> params);
}

class MockSignOutUseCase extends Mock {
  Future<Result<void>> call();
}

class MockGetCurrentUserUseCase extends Mock {
  Future<Result<User?>> call();
}

class MockGetAuthStateChangesUseCase extends Mock {
  Stream<User?> call();
}

// VGV Pattern: BLoC Mocks using bloc_test
class MockAuthenticationBloc extends MockBloc<dynamic, dynamic>
    implements Bloc<dynamic, dynamic> {}

class MockLoginBloc extends MockBloc<dynamic, dynamic>
    implements Bloc<dynamic, dynamic> {}

class MockSignupBloc extends MockBloc<dynamic, dynamic>
    implements Bloc<dynamic, dynamic> {}

// VGV Pattern: Generic Function Mocks
class MockFunction extends Mock {
  void call();
}

class MockFunction1<T> extends Mock {
  void call(T arg);
}

class MockFunction2<T1, T2> extends Mock {
  void call(T1 arg1, T2 arg2);
}

// VGV Pattern: Firebase Mock Helpers
class VGVFirebaseMockHelper {
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

// VGV Pattern: Test Constants
class VGVTestConstants {
  static const Duration defaultTimeout = Duration(seconds: 5);
  static const Duration shortTimeout = Duration(milliseconds: 500);
  static const Duration longTimeout = Duration(seconds: 30);

  // Test data
  static const String testEmail = 'test@example.com';
  static const String testPassword = 'TestPass123!';
  static const String testDisplayName = 'Test User';
  static const String testUserId = 'test-user-id';
  static const String testErrorMessage = 'Test error message';
}

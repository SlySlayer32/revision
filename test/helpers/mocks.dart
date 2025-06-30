// VGV-compliant mock classes for testing
// Following Very Good Ventures testing patterns

import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:mocktail/mocktail.dart';
// import 'package:revision/core/utils/result.dart'; // Removed custom Result
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/repositories/auth_repository.dart';
import 'package:revision/features/authentication/domain/usecases/get_auth_state_changes_usecase.dart'; // Import actual use case
import 'package:revision/features/authentication/domain/usecases/get_current_user_usecase.dart'; // Import actual use case
import 'package:revision/features/authentication/domain/usecases/send_password_reset_email_usecase.dart'; // Import actual use case
import 'package:revision/features/authentication/domain/usecases/sign_in_usecase.dart'; // Import actual use case
import 'package:revision/features/authentication/domain/usecases/sign_in_with_google_usecase.dart'; // Import actual use case
import 'package:revision/features/authentication/domain/usecases/sign_out_usecase.dart'; // Import actual use case
import 'package:revision/features/authentication/domain/usecases/sign_up_usecase.dart'; // Import actual use case
import 'package:revision/features/authentication/presentation/blocs/authentication_bloc.dart'; // For AuthenticationEvent, AuthenticationState, AuthenticationBloc
import 'package:revision/features/authentication/presentation/blocs/login_bloc.dart'; // For LoginBloc, LoginEvent, LoginState
import 'package:revision/features/authentication/presentation/blocs/signup_bloc.dart'; // For SignupBloc, SignupEvent, SignupState

// VGV Pattern: Core Mocks
// class MockResult<T> extends Mock implements Result<T> {} // Removed, Result is sealed and we use Either

// VGV Pattern: Authentication Domain Mocks
class MockAuthRepository extends Mock implements AuthRepository {}

class MockUser extends Mock implements User {}

// VGV Pattern: Firebase Mocks
class MockFirebaseAuth extends Mock implements firebase_auth.FirebaseAuth {}

class MockFirebaseUser extends Mock implements firebase_auth.User {}

class MockUserCredential extends Mock implements firebase_auth.UserCredential {}

class MockAuthCredential extends Mock implements firebase_auth.AuthCredential {}

// VGV Pattern: Use Case Mocks
// These now reflect that use cases return Either<Failure, T> and implement actual use cases
class MockSignInUseCase extends Mock implements SignInUseCase {}

class MockSignUpUseCase extends Mock implements SignUpUseCase {}

class MockSignOutUseCase extends Mock implements SignOutUseCase {}

class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}

class MockGetAuthStateChangesUseCase extends Mock
    implements GetAuthStateChangesUseCase {}

class MockSignInWithGoogleUseCase extends Mock
    implements SignInWithGoogleUseCase {}

class MockSendPasswordResetEmailUseCase extends Mock
    implements SendPasswordResetEmailUseCase {}

// VGV Pattern: BLoC Mocks using bloc_test
class MockAuthenticationBloc
    extends MockBloc<AuthenticationEvent, AuthenticationState>
    implements AuthenticationBloc {}

class MockLoginBloc extends MockBloc<LoginEvent, LoginState>
    implements LoginBloc {}

class MockSignupBloc extends MockBloc<SignupEvent, SignupState>
    implements SignupBloc {}

// VGV Pattern: Firebase AI Mocks
// Note: GenerativeModel is a final class, so we can't implement it directly
// Instead, we use a wrapper approach for testing
class MockGenerativeModel extends Mock {
  // We'll mock the methods we need rather than implementing the interface
}

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

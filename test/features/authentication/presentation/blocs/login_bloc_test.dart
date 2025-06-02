import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/core/error/failures.dart'; // Import for AuthenticationFailure
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/usecases/send_password_reset_email_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/sign_in_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:revision/features/authentication/presentation/blocs/login_bloc.dart';

class MockSignInUseCase extends Mock implements SignInUseCase {}

class MockSignInWithGoogleUseCase extends Mock
    implements SignInWithGoogleUseCase {}

class MockSendPasswordResetEmailUseCase extends Mock
    implements SendPasswordResetEmailUseCase {}

void main() {
  group('LoginBloc', () {
    late LoginBloc loginBloc;
    late MockSignInUseCase mockSignIn;
    late MockSignInWithGoogleUseCase mockSignInWithGoogle;
    late MockSendPasswordResetEmailUseCase mockSendPasswordResetEmail;

    setUp(() {
      mockSignIn = MockSignInUseCase();
      mockSignInWithGoogle = MockSignInWithGoogleUseCase();
      mockSendPasswordResetEmail = MockSendPasswordResetEmailUseCase();

      loginBloc = LoginBloc(
        signIn: mockSignIn,
        signInWithGoogle: mockSignInWithGoogle,
        sendPasswordResetEmail: mockSendPasswordResetEmail,
      );
    });

    tearDown(() {
      loginBloc.close();
    });

    const email = 'test@example.com';
    const password = 'password123';
    const user = User(
      id: '1',
      email: email,
      displayName: 'Test User',
      photoUrl: null,
      isEmailVerified: true,
      createdAt: '2023-01-01T00:00:00Z',
      customClaims: {},
    );

    test('initial state is LoginState with initial status', () {
      expect(loginBloc.state, equals(const LoginState()));
    });

    group('LoginRequested', () {
      void arrangeSignInSuccess() {
        when(
          () =>
              mockSignIn(const SignInParams(email: email, password: password)),
        ).thenAnswer((_) async => const Right(user));
      }

      void arrangeSignInFailure() {
        when(
          () =>
              mockSignIn(const SignInParams(email: email, password: password)),
        ).thenAnswer(
          (_) async => const Left(AuthenticationFailure('Sign in failed')),
        );
      }

      blocTest<LoginBloc, LoginState>(
        'emits [loading, success] when sign in succeeds',
        setUp: () {
          arrangeSignInSuccess();
        },
        build: () => loginBloc,
        act: (bloc) => bloc.add(
          const LoginRequested(email: email, password: password),
        ),
        expect: () => const [
          LoginState(status: LoginStatus.loading),
          LoginState(status: LoginStatus.success),
        ],
      );

      blocTest<LoginBloc, LoginState>(
        'emits [loading, failure] when sign in fails',
        setUp: () {
          arrangeSignInFailure();
        },
        build: () => loginBloc,
        act: (bloc) => bloc.add(
          const LoginRequested(email: email, password: password),
        ),
        expect: () => [
          const LoginState(status: LoginStatus.loading),
          isA<LoginState>()
              .having((s) => s.status, 'status', LoginStatus.failure)
              .having(
                (s) => s.errorMessage,
                'errorMessage',
                'Failure: Sign in failed (Code: null)', // Adjusted to match AuthenticationFailure.toString()
              ),
        ],
      );
    });
  });
}

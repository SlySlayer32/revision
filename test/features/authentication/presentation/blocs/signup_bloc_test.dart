import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/core/utils/result.dart'; // For Success and Failure
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/exceptions/auth_exception.dart'; // For specific auth exceptions
import 'package:revision/features/authentication/domain/usecases/sign_up_usecase.dart';
import 'package:revision/features/authentication/presentation/blocs/signup_bloc.dart';
import '../../../../helpers/helpers.dart'; // Import the helper

class MockSignUpUseCase extends Mock implements SignUpUseCase {}

void main() {
  // Ensure Firebase is initialized before tests run
  setUpAll(() async {
    await setupFirebaseAuthMocks();
  });

  group('SignupBloc', () {
    late SignupBloc signupBloc;
    late MockSignUpUseCase mockSignUp;

    setUp(() {
      mockSignUp = MockSignUpUseCase();
      signupBloc = SignupBloc(signUp: mockSignUp);
    });

    tearDown(() {
      signupBloc.close();
    });

    const email = 'test@example.com';
    const password = 'password123';
    const user = User(
      id: '1',
      email: email,
      displayName: null,
      photoUrl: null,
      isEmailVerified: false,
      createdAt: '2023-01-01T00:00:00Z', // Placeholder
      customClaims: {},
    );

    test('initial state is SignupState.initial', () {
      expect(signupBloc.state, equals(const SignupState.initial()));
    });
    group('SignupRequested', () {
      blocTest<SignupBloc, SignupState>(
        'emits [loading, success] when sign up succeeds',
        build: () {
          when(() => mockSignUp(email: email, password: password))
              .thenAnswer((_) async => const Success(user));
          return signupBloc;
        },
        act: (bloc) => bloc.add(
          const SignupRequested(
            email: email,
            password: password,
            confirmPassword: password,
          ),
        ),
        expect: () => [
          const SignupState.loading(),
          const SignupState.success(user),
        ],
      );
      blocTest<SignupBloc, SignupState>(
        'emits [loading, failure] when sign up fails with email already '
        'in use',
        build: () {
          const exception = EmailAlreadyInUseException();
          when(() => mockSignUp(email: email, password: password))
              .thenAnswer((_) async => const Failure<User>(exception));
          return signupBloc;
        },
        act: (bloc) => bloc.add(
          const SignupRequested(
            email: email,
            password: password,
            confirmPassword: password,
          ),
        ),
        expect: () => [
          const SignupState.loading(),
          SignupState.failure(const EmailAlreadyInUseException().toString()),
        ],
      );
      blocTest<SignupBloc, SignupState>(
        'emits [loading, failure] when sign up fails with weak password',
        build: () {
          const exception = WeakPasswordException();
          when(() => mockSignUp(email: email, password: password))
              .thenAnswer((_) async => const Failure<User>(exception));
          return signupBloc;
        },
        act: (bloc) => bloc.add(
          const SignupRequested(
            email: email,
            password: password,
            confirmPassword: password,
          ),
        ),
        expect: () => [
          const SignupState.loading(),
          SignupState.failure(const WeakPasswordException().toString()),
        ],
      );
      blocTest<SignupBloc, SignupState>(
        'emits [loading, failure] when sign up fails with network error',
        build: () {
          // Using a generic Exception as a last resort for this specific test case
          final exception = Exception('Network error');
          when(() => mockSignUp(email: email, password: password))
              .thenAnswer((_) async => Failure<User>(exception));
          return signupBloc;
        },
        act: (bloc) => bloc.add(
          const SignupRequested(
            email: email,
            password: password,
            confirmPassword: password,
          ),
        ),
        expect: () => [
          const SignupState.loading(),
          SignupState.failure(Exception('Network error').toString()),
        ],
      );
      blocTest<SignupBloc, SignupState>(
        'emits [loading, failure] when sign up fails with unexpected error',
        build: () {
          const exception = UnexpectedAuthException('Unexpected error');
          when(() => mockSignUp(email: email, password: password))
              .thenAnswer((_) async => const Failure<User>(exception));
          return signupBloc;
        },
        act: (bloc) => bloc.add(
          const SignupRequested(
            email: email,
            password: password,
            confirmPassword: password,
          ),
        ),
        expect: () => [
          const SignupState.loading(),
          SignupState.failure(
              const UnexpectedAuthException('Unexpected error').toString()),
        ],
      );
      blocTest<SignupBloc, SignupState>(
        'calls sign up use case with correct parameters',
        build: () {
          when(() => mockSignUp(email: email, password: password))
              .thenAnswer((_) async => const Success(user));
          return signupBloc;
        },
        act: (bloc) => bloc.add(
          const SignupRequested(
            email: email,
            password: password,
            confirmPassword: password,
          ),
        ),
        verify: (_) {
          verify(() => mockSignUp(email: email, password: password)).called(1);
        },
      );
    });
  });
}

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/core/utils/result.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/exceptions/auth_exception.dart';
import 'package:revision/features/authentication/domain/usecases/sign_up_usecase.dart';
import 'package:revision/features/authentication/presentation/blocs/signup_bloc.dart';

class MockSignUpUseCase extends Mock implements SignUpUseCase {}

void main() {
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
    const user = User(id: '1', email: email);

    test('initial state is SignupState.initial', () {
      expect(signupBloc.state, equals(const SignupState.initial()));
    });
    group('SignupRequested', () {
      blocTest<SignupBloc, SignupState>(
        'emits [loading, success] when sign up succeeds',
        build: () {
          when(() => mockSignUp(email: email, password: password))
              .thenAnswer((_) async => const Success<User>(user));
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
          const SignupState.failure('EmailAlreadyInUseException'),
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
          const SignupState.failure('WeakPasswordException'),
        ],
      );
      blocTest<SignupBloc, SignupState>(
        'emits [loading, failure] when sign up fails with network error',
        build: () {
          const exception = NetworkException();
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
          const SignupState.failure('NetworkException'),
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
          const SignupState.failure('Unexpected error'),
        ],
      );
      blocTest<SignupBloc, SignupState>(
        'calls sign up use case with correct parameters',
        build: () {
          when(() => mockSignUp(email: email, password: password))
              .thenAnswer((_) async => const Success<User>(user));
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

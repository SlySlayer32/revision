import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart'; // Added dartz
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/core/error/failures.dart'; // Added for Failure types
import 'package:revision/features/authentication/domain/entities/user.dart';
// import 'package:revision/features/authentication/domain/exceptions/auth_exception.dart'; // Will use standard Failures
import 'package:revision/features/authentication/domain/usecases/sign_up_usecase.dart';
import 'package:revision/features/authentication/presentation/blocs/signup_bloc.dart';
// import '../../../../helpers/helpers.dart'; // Firebase mocks not needed for BLoC test with mocked use case

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
    const user = User(
      id: '1',
      email: email,
      displayName: null,
      photoUrl: null,
      isEmailVerified: false,
      createdAt: '2023-01-01T00:00:00Z', // Placeholder
      customClaims: <String, dynamic>{},
    );

    test('initial state is SignupState.initial', () {
      expect(signupBloc.state, equals(const SignupState.initial()));
    });
    group('SignupRequested', () {
      blocTest<SignupBloc, SignupState>(
        'emits [loading, success] when sign up succeeds',
        build: () {
          when(() => mockSignUp(email: email, password: password)).thenAnswer(
            (_) async => const Right<Failure, User>(user),
          ); // Use Right
          return signupBloc;
        },
        act: (bloc) => bloc.add(
          const SignupRequested(
            email: email,
            password: password,
            confirmPassword: password, // Added comma
          ),
        ),
        expect: () => [
          const SignupState.loading(),
          const SignupState.success(user), // Added comma
        ],
      );
      blocTest<SignupBloc, SignupState>(
        'emits [loading, failure] when sign up fails with email already '
        'in use',
        build: () {
          const tFailure =
              AuthenticationFailure('Email already in use'); // Standard Failure
          when(() => mockSignUp(email: email, password: password)).thenAnswer(
            (_) async => const Left<Failure, User>(tFailure),
          ); // Use Left
          return signupBloc;
        },
        act: (bloc) => bloc.add(
          const SignupRequested(
            email: email,
            password: password,
            confirmPassword: password, // Added comma
          ),
        ),
        expect: () => [
          const SignupState.loading(),
          const SignupState.failure(
            'Email already in use',
          ), // Use message from Failure // Added comma
        ],
      );
      blocTest<SignupBloc, SignupState>(
        'emits [loading, failure] when sign up fails with weak password',
        build: () {
          const tFailure =
              ValidationFailure('Password is too weak'); // Standard Failure
          when(() => mockSignUp(email: email, password: password)).thenAnswer(
            (_) async => const Left<Failure, User>(tFailure),
          ); // Use Left
          return signupBloc;
        },
        act: (bloc) => bloc.add(
          const SignupRequested(
            email: email,
            password: password,
            confirmPassword: password, // Added comma
          ),
        ),
        expect: () => [
          const SignupState.loading(),
          const SignupState.failure(
            'Password is too weak',
          ), // Use message from Failure // Added comma
        ],
      );
      blocTest<SignupBloc, SignupState>(
        'emits [loading, failure] when sign up fails with network error',
        build: () {
          const tFailure = NetworkFailure('Network error'); // Standard Failure
          when(() => mockSignUp(email: email, password: password)).thenAnswer(
            (_) async => const Left<Failure, User>(tFailure),
          ); // Use Left
          return signupBloc;
        },
        act: (bloc) => bloc.add(
          const SignupRequested(
            email: email,
            password: password,
            confirmPassword: password, // Added comma
          ),
        ),
        expect: () => [
          const SignupState.loading(),
          const SignupState.failure(
            'Network error',
          ), // Use message from Failure // Added comma
        ],
      );
      blocTest<SignupBloc, SignupState>(
        'emits [loading, failure] when sign up fails with unexpected error',
        build: () {
          const tFailure =
              AuthenticationFailure('Unexpected error'); // Standard Failure
          when(() => mockSignUp(email: email, password: password)).thenAnswer(
            (_) async => const Left<Failure, User>(tFailure),
          ); // Use Left
          return signupBloc;
        },
        act: (bloc) => bloc.add(
          const SignupRequested(
            email: email,
            password: password,
            confirmPassword: password, // Added comma
          ),
        ),
        expect: () => [
          const SignupState.loading(),
          const SignupState.failure(
            'Unexpected error',
          ), // Use message from Failure // Added comma
        ],
      );
      blocTest<SignupBloc, SignupState>(
        'calls sign up use case with correct parameters',
        build: () {
          when(() => mockSignUp(email: email, password: password)).thenAnswer(
            (_) async => const Right<Failure, User>(user),
          ); // Use Right
          return signupBloc;
        },
        act: (bloc) => bloc.add(
          const SignupRequested(
            email: email,
            password: password,
            confirmPassword: password, // Added comma
          ),
        ),
        verify: (_) {
          verify(() => mockSignUp(email: email, password: password)).called(1);
        },
      );
    });
  });
}

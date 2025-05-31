import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/core/utils/result.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:revision/features/authentication/domain/usecases/get_auth_state_changes_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/sign_out_usecase.dart';
import 'package:revision/features/authentication/presentation/blocs/authentication_bloc.dart';

class MockAuthenticationRepository extends Mock
    implements AuthenticationRepository {}

class TestGetAuthStateChangesUseCase extends GetAuthStateChangesUseCase {
  TestGetAuthStateChangesUseCase()
      : super(
          MockAuthenticationRepository(),
        );

  late StreamController<User?> controller;

  @override
  Stream<User?> call() => controller.stream;
}

class MockSignOutUseCase extends Mock implements SignOutUseCase {}

void main() {
  group('AuthenticationBloc', () {
    late AuthenticationBloc authenticationBloc;
    late TestGetAuthStateChangesUseCase getAuthStateChanges;
    late MockSignOutUseCase mockSignOut;
    late StreamController<User?> authStateController;

    setUp(() {
      authStateController = StreamController<User?>();
      getAuthStateChanges = TestGetAuthStateChangesUseCase()
        ..controller = authStateController;
      mockSignOut = MockSignOutUseCase();

      authenticationBloc = AuthenticationBloc(
        getAuthStateChanges: getAuthStateChanges,
        signOut: mockSignOut,
      );
    });

    tearDown(() {
      authStateController.close();
      authenticationBloc.close();
    });

    const user = User(id: '1', email: 'test@example.com');

    test('initial state is AuthenticationState.unknown', () {
      expect(
        authenticationBloc.state,
        equals(const AuthenticationState.unknown()),
      );
    });

    group('AuthenticationStatusChanged', () {
      blocTest<AuthenticationBloc, AuthenticationState>(
        'emits authenticated when user is not null',
        build: () => authenticationBloc,
        act: (bloc) => authStateController.add(user),
        expect: () => const [
          AuthenticationState.authenticated(user),
        ],
      );

      blocTest<AuthenticationBloc, AuthenticationState>(
        'emits unauthenticated when user is null',
        build: () => authenticationBloc,
        act: (bloc) => authStateController.add(null),
        expect: () => const [
          AuthenticationState.unauthenticated(),
        ],
      );

      blocTest<AuthenticationBloc, AuthenticationState>(
        'emits states in order for auth changes',
        build: () => authenticationBloc,
        act: (bloc) {
          authStateController
            ..add(user)
            ..add(null)
            ..add(user);
        },
        expect: () => const [
          AuthenticationState.authenticated(user),
          AuthenticationState.unauthenticated(),
          AuthenticationState.authenticated(user),
        ],
      );
    });

    group('AuthenticationLogoutRequested', () {
      blocTest<AuthenticationBloc, AuthenticationState>(
        'calls sign out use case',
        build: () {
          when(() => mockSignOut())
              .thenAnswer((_) async => const Success<void>(null));
          return authenticationBloc;
        },
        act: (bloc) => bloc.add(AuthenticationLogoutRequested()),
        verify: (_) {
          verify(() => mockSignOut()).called(1);
        },
      );
      blocTest<AuthenticationBloc, AuthenticationState>(
        'does not emit new state on successful logout',
        build: () {
          when(() => mockSignOut())
              .thenAnswer((_) async => const Success<void>(null));
          return authenticationBloc;
        },
        act: (bloc) => bloc.add(AuthenticationLogoutRequested()),
        expect: () => <AuthenticationState>[],
      );
      blocTest<AuthenticationBloc, AuthenticationState>(
        'does not emit new state on failed logout',
        build: () {
          when(() => mockSignOut()).thenAnswer(
            (_) async => Failure<void>(Exception('Logout failed')),
          );
          return authenticationBloc;
        },
        act: (bloc) => bloc.add(AuthenticationLogoutRequested()),
        expect: () => <AuthenticationState>[],
      );
    });
  });
}

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/presentation/blocs/authentication_bloc.dart';

import '../../../../helpers/helpers.dart';

void main() {
  group('AuthenticationBloc', () {
    late AuthenticationBloc authenticationBloc;
    late MockGetAuthStateChangesUseCase getAuthStateChanges;
    late MockSignOutUseCase signOut;
    late StreamController<User?> authStateController;

    setUp(() {
      authStateController = StreamController<User?>();
      getAuthStateChanges = MockGetAuthStateChangesUseCase();
      signOut = MockSignOutUseCase();

      // Setup mock stream
      when(() => getAuthStateChanges()).thenAnswer(
        (_) => authStateController.stream,
      );

      authenticationBloc = AuthenticationBloc(
        getAuthStateChanges: getAuthStateChanges,
        signOut: signOut,
      );
    });

    tearDown(() {
      authStateController.close();
      authenticationBloc.close();
    });

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
        act: (bloc) => authStateController.add(TestDataFactory.user()),
        expect: () => [
          AuthenticationState.authenticated(TestDataFactory.user()),
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
          final user = TestDataFactory.user();
          authStateController
            ..add(user)
            ..add(null)
            ..add(user);
        },
        expect: () {
          final user = TestDataFactory.user();
          return [
            AuthenticationState.authenticated(user),
            const AuthenticationState.unauthenticated(),
            AuthenticationState.authenticated(user),
          ];
        },
      );
    });

    group('AuthenticationLogoutRequested', () {
      blocTest<AuthenticationBloc, AuthenticationState>(
        'calls sign out use case',
        build: () {
          MockSetup.setupSuccessfulSignOut(signOut);
          return authenticationBloc;
        },
        act: (bloc) => bloc.add(AuthenticationLogoutRequested()),
        verify: (_) {
          verify(() => signOut()).called(1);
        },
      );

      blocTest<AuthenticationBloc, AuthenticationState>(
        'does not emit new state on successful logout',
        build: () {
          MockSetup.setupSuccessfulSignOut(signOut);
          return authenticationBloc;
        },
        act: (bloc) => bloc.add(AuthenticationLogoutRequested()),
        expect: () => <AuthenticationState>[],
      );

      blocTest<AuthenticationBloc, AuthenticationState>(
        'does not emit new state on failed logout',
        build: () {
          MockSetup.setupFailedSignOut(signOut, errorMessage: 'Logout failed');
          return authenticationBloc;
        },
        act: (bloc) => bloc.add(AuthenticationLogoutRequested()),
        expect: () => <AuthenticationState>[],
      );
    });
  });
}

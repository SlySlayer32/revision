import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart'; // For Either
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/core/error/failures.dart'; // For Failure
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/presentation/blocs/authentication_bloc.dart';

// Assuming helpers.dart exports MockGetAuthStateChangesUseCase, MockSignOutUseCase from mocks.dart
// and VGVTestDataFactory from vgv_mocks.dart
import '../../../../helpers/helpers.dart';

// If not, import directly:
// import '../../../helpers/mocks.dart'; // Contains MockGetAuthStateChangesUseCase, MockSignOutUseCase
// import '../../../helpers/vgv_mocks.dart'; // Contains VGVTestDataFactory

void main() {
  group('AuthenticationBloc', () {
    late AuthenticationBloc authenticationBloc;
    // Use the mock types defined in mocks.dart (which implement the actual use cases)
    late MockGetAuthStateChangesUseCase mockGetAuthStateChanges;
    late MockSignOutUseCase mockSignOut;
    late StreamController<User?> authStateController;

    // A sample user for tests, created using VGVTestDataFactory
    final tUser =
        VGVTestDataFactory.createTestUser(email: 'test@example.com', id: '123');
    const tSignOutFailure = AuthenticationFailure('Logout failed');

    setUp(() {
      authStateController = StreamController<User?>();
      mockGetAuthStateChanges = MockGetAuthStateChangesUseCase();
      mockSignOut = MockSignOutUseCase();

      when(() => mockGetAuthStateChanges()).thenAnswer(
        (_) => authStateController.stream,
      );

      authenticationBloc = AuthenticationBloc(
        getAuthStateChanges: mockGetAuthStateChanges, // Pass the mock instance
        signOut: mockSignOut, // Pass the mock instance
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
        act: (bloc) => authStateController.add(tUser), // Use VGVTestDataFactory
        expect: () => [
          AuthenticationState.authenticated(tUser), // Use VGVTestDataFactory
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
            ..add(tUser) // Use VGVTestDataFactory
            ..add(null)
            ..add(tUser); // Use VGVTestDataFactory
        },
        expect: () {
          return [
            AuthenticationState.authenticated(tUser), // Use VGVTestDataFactory
            const AuthenticationState.unauthenticated(),
            AuthenticationState.authenticated(tUser), // Use VGVTestDataFactory
          ];
        },
      );
    });

    group('AuthenticationLogoutRequested', () {
      blocTest<AuthenticationBloc, AuthenticationState>(
        'calls sign out use case and expects Right(null) for success',
        build: () {
          // Directly mock signOut use case for success
          when(() => mockSignOut())
              .thenAnswer((_) async => const Right<Failure, void>(null));
          return authenticationBloc;
        },
        act: (bloc) => bloc.add(const AuthenticationLogoutRequested()),
        verify: (_) {
          verify(() => mockSignOut()).called(1);
        },
        expect: () =>
            <AuthenticationState>[], // No state change expected on successful logout by default
      );

      blocTest<AuthenticationBloc, AuthenticationState>(
        'calls sign out use case and expects Left(Failure) for failure',
        build: () {
          // Directly mock signOut use case for failure
          when(() => mockSignOut()).thenAnswer(
              (_) async => const Left<Failure, void>(tSignOutFailure));
          return authenticationBloc;
        },
        act: (bloc) => bloc.add(const AuthenticationLogoutRequested()),
        verify: (_) {
          verify(() => mockSignOut()).called(1);
        },
        // Depending on bloc logic, it might emit a failure state or handle silently.
        // Current tests imply no state emission on logout attempt.
        expect: () => <AuthenticationState>[],
      );
    });
  });
}

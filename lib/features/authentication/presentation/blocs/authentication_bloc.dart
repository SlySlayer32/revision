import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/usecases/get_auth_state_changes_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/sign_out_usecase.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

/// BLoC responsible for managing the authentication state of the app
class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  /// Creates a new [AuthenticationBloc]
  AuthenticationBloc({
    required GetAuthStateChangesUseCase getAuthStateChanges,
    required SignOutUseCase signOut,
  })  : _getAuthStateChanges = getAuthStateChanges,
        _signOut = signOut,
        super(const AuthenticationState.unknown()) {
    debugPrint(
        'AuthenticationBloc: Initializing and subscribing to auth state changes');
    on<AuthenticationStatusChanged>(_onAuthenticationStatusChanged);
    on<AuthenticationLogoutRequested>(_onAuthenticationLogoutRequested);

    _authStateSubscription = _getAuthStateChanges().listen(
      (user) {
        debugPrint(
            'AuthenticationBloc: Auth state changed, user = \\${user?.email ?? "null"}');
        add(AuthenticationStatusChanged(user));
      },
    );
  }

  final GetAuthStateChangesUseCase _getAuthStateChanges;
  final SignOutUseCase _signOut;
  late final StreamSubscription<User?> _authStateSubscription;

  Future<void> _onAuthenticationStatusChanged(
    AuthenticationStatusChanged event,
    Emitter<AuthenticationState> emit,
  ) async {
    if (event.user != null) {
      emit(AuthenticationState.authenticated(event.user!));
    } else {
      emit(const AuthenticationState.unauthenticated());
    }
  }

  Future<void> _onAuthenticationLogoutRequested(
    AuthenticationLogoutRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    try {
      final result = await _signOut();
      result.fold(
        (failure) => log('Error signing out', error: failure),
        (_) => log('User signed out successfully'),
      );
    } catch (e) {
      log('Unexpected error signing out', error: e);
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription.cancel();
    return super.close();
  }
}

import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:revision/core/utils/auth_security_utils.dart';
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
  }) : _getAuthStateChanges = getAuthStateChanges,
       _signOut = signOut,
       super(const AuthenticationState.unknown()) {
    AuthSecurityUtils.logAuthEvent('BLoC initialized');
    on<AuthenticationStatusChanged>(_onAuthenticationStatusChanged);
    on<AuthenticationLogoutRequested>(_onAuthenticationLogoutRequested);

    _authStateSubscription = _getAuthStateChanges().listen(
      (user) {
        AuthSecurityUtils.logAuthEvent(
          'Auth state changed',
          user: user,
        );
        add(AuthenticationStatusChanged(user));
      },
      onError: (error, stackTrace) {
        AuthSecurityUtils.logAuthError(
          'Auth state stream error',
          error,
          stackTrace: stackTrace,
        );
        add(AuthenticationStatusChanged(null));
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
    try {
      final user = event.user;
      if (user != null) {
        AuthSecurityUtils.logAuthEvent(
          'User authenticated',
          user: user,
        );
        emit(AuthenticationState.authenticated(user));
      } else {
        AuthSecurityUtils.logAuthEvent('User unauthenticated');
        emit(const AuthenticationState.unauthenticated());
      }
    } catch (e, stackTrace) {
      AuthSecurityUtils.logAuthError(
        'Authentication status change',
        e,
        stackTrace: stackTrace,
        user: event.user,
      );
      // Fallback to unauthenticated state on error
      emit(const AuthenticationState.unauthenticated());
    }
  }

  Future<void> _onAuthenticationLogoutRequested(
    AuthenticationLogoutRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    try {
      AuthSecurityUtils.logAuthEvent('Logout requested');
      final result = await AuthSecurityUtils.withAuthTimeout(
        _signOut(),
        'logout',
      );
      result.fold(
        (failure) => AuthSecurityUtils.logAuthError(
          'Sign out',
          failure,
        ),
        (_) => AuthSecurityUtils.logAuthEvent('User signed out successfully'),
      );
    } catch (e) {
      AuthSecurityUtils.logAuthError('Logout operation', e);
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription.cancel();
    return super.close();
  }
}

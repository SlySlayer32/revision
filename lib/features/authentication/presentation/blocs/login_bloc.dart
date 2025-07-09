import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:revision/core/utils/auth_security_utils.dart';
import 'package:revision/features/authentication/domain/usecases/send_password_reset_email_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/sign_in_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/sign_in_with_google_usecase.dart';

part 'login_event.dart';
part 'login_state.dart';

/// BLoC responsible for handling login events and states
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  /// Creates a new [LoginBloc]
  LoginBloc({
    required SignInUseCase signIn,
    required SignInWithGoogleUseCase signInWithGoogle,
    required SendPasswordResetEmailUseCase sendPasswordResetEmail,
  }) : _signIn = signIn,
       _signInWithGoogle = signInWithGoogle,
       _sendPasswordResetEmail = sendPasswordResetEmail,
       super(const LoginState()) {
    on<LoginRequested>(_onLoginRequested);
    on<LoginWithGoogleRequested>(_onLoginWithGoogleRequested);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
  }

  final SignInUseCase _signIn;
  final SignInWithGoogleUseCase _signInWithGoogle;
  final SendPasswordResetEmailUseCase _sendPasswordResetEmail;
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<LoginState> emit,
  ) async {
    try {
      // Check rate limiting
      if (AuthSecurityUtils.isAuthRateLimited(event.email)) {
        AuthSecurityUtils.logAuthError(
          'Login attempt rate limited',
          Exception('Rate limit exceeded'),
          data: {'email': event.email},
        );
        emit(
          state.copyWith(
            status: LoginStatus.failure,
            errorMessage: 'Too many login attempts. Please try again later.',
          ),
        );
        return;
      }

      emit(state.copyWith(status: LoginStatus.loading));

      final result = await AuthSecurityUtils.withAuthTimeout(
        _signIn(
          SignInParams(email: event.email, password: event.password),
        ),
        'login',
      );

      result.fold((failure) {
        AuthSecurityUtils.logAuthError('Login failed', failure);
        emit(
          state.copyWith(
            status: LoginStatus.failure,
            errorMessage: failure.message,
          ),
        );
      }, (user) {
        AuthSecurityUtils.logAuthEvent('Login successful', user: user);
        emit(state.copyWith(status: LoginStatus.success));
      });
    } catch (e) {
      AuthSecurityUtils.logAuthError('Login error', e);
      final errorCategory = AuthSecurityUtils.categorizeAuthError(e);
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: errorCategory.userMessage,
        ),
      );
    }
  }

  Future<void> _onLoginWithGoogleRequested(
    LoginWithGoogleRequested event,
    Emitter<LoginState> emit,
  ) async {
    try {
      emit(state.copyWith(status: LoginStatus.loading));

      final result = await AuthSecurityUtils.withAuthTimeout(
        _signInWithGoogle(),
        'google_login',
      );

      result.fold((failure) {
        AuthSecurityUtils.logAuthError('Google login failed', failure);
        emit(
          state.copyWith(
            status: LoginStatus.failure,
            errorMessage: failure.message,
          ),
        );
      }, (user) {
        AuthSecurityUtils.logAuthEvent('Google login successful', user: user);
        emit(state.copyWith(status: LoginStatus.success));
      });
    } catch (e) {
      AuthSecurityUtils.logAuthError('Google login error', e);
      final errorCategory = AuthSecurityUtils.categorizeAuthError(e);
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: errorCategory.userMessage,
        ),
      );
    }
  }

  Future<void> _onForgotPasswordRequested(
    ForgotPasswordRequested event,
    Emitter<LoginState> emit,
  ) async {
    try {
      // Check rate limiting for password reset
      if (AuthSecurityUtils.isAuthRateLimited('password_reset_${event.email}')) {
        AuthSecurityUtils.logAuthError(
          'Password reset rate limited',
          Exception('Rate limit exceeded'),
          data: {'email': event.email},
        );
        emit(
          state.copyWith(
            status: LoginStatus.failure,
            errorMessage: 'Too many password reset attempts. Please try again later.',
          ),
        );
        return;
      }

      emit(state.copyWith(status: LoginStatus.loading));

      final result = await AuthSecurityUtils.withAuthTimeout(
        _sendPasswordResetEmail(event.email),
        'password_reset',
      );

      result.fold(
        (failure) {
          AuthSecurityUtils.logAuthError('Password reset failed', failure);
          emit(
            state.copyWith(
              status: LoginStatus.failure,
              errorMessage: failure.message,
            ),
          );
        },
        (_) {
          AuthSecurityUtils.logAuthEvent('Password reset sent');
          emit(
            state.copyWith(
              status: LoginStatus.success,
              errorMessage: 'Password reset email sent',
            ),
          );
        },
      );
    } catch (e) {
      AuthSecurityUtils.logAuthError('Password reset error', e);
      final errorCategory = AuthSecurityUtils.categorizeAuthError(e);
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: errorCategory.userMessage,
        ),
      );
    }
  }
}

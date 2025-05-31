import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
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
  })  : _signIn = signIn,
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
      emit(state.copyWith(status: LoginStatus.loading));

      final result =
          await _signIn(email: event.email, password: event.password);
      result.fold(
        success: (_) => emit(state.copyWith(status: LoginStatus.success)),
        failure: (error) {
          log('Login error', error: error);
          emit(
            state.copyWith(
              status: LoginStatus.failure,
              errorMessage: error.toString(),
            ),
          );
        },
      );
    } catch (e) {
      log('Unexpected login error', error: e);
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: 'An unexpected error occurred',
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

      final result = await _signInWithGoogle();
      result.fold(
        success: (_) => emit(state.copyWith(status: LoginStatus.success)),
        failure: (error) {
          log('Google login error', error: error);
          emit(
            state.copyWith(
              status: LoginStatus.failure,
              errorMessage: error.toString(),
            ),
          );
        },
      );
    } catch (e) {
      log('Unexpected Google login error', error: e);
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: 'An unexpected error occurred',
        ),
      );
    }
  }

  Future<void> _onForgotPasswordRequested(
    ForgotPasswordRequested event,
    Emitter<LoginState> emit,
  ) async {
    try {
      emit(state.copyWith(status: LoginStatus.loading));

      final result = await _sendPasswordResetEmail(event.email);
      result.fold(
        success: (_) {
          emit(
            state.copyWith(
              status: LoginStatus.success,
              errorMessage: 'Password reset email sent',
            ),
          );
        },
        failure: (error) {
          log('Password reset error', error: error);
          emit(
            state.copyWith(
              status: LoginStatus.failure,
              errorMessage: error.toString(),
            ),
          );
        },
      );
    } catch (e) {
      log('Unexpected password reset error', error: e);
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: 'An unexpected error occurred',
        ),
      );
    }
  }
}

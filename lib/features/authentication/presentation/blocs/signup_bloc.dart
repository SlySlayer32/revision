import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/exceptions/auth_exception.dart';
import 'package:revision/features/authentication/domain/usecases/sign_up_usecase.dart';

part 'signup_event.dart';
part 'signup_state.dart';

/// BLoC responsible for managing sign up functionality
class SignupBloc extends Bloc<SignupEvent, SignupState> {
  /// Creates a new [SignupBloc]
  SignupBloc({
    required SignUpUseCase signUp,
  })  : _signUp = signUp,
        super(const SignupState.initial()) {
    on<SignupRequested>(_onSignupRequested);
  }

  final SignUpUseCase _signUp;

  Future<void> _onSignupRequested(
    SignupRequested event,
    Emitter<SignupState> emit,
  ) async {
    // Validate that passwords match
    if (event.password != event.confirmPassword) {
      emit(const SignupState.failure('Passwords do not match'));
      return;
    }

    emit(const SignupState.loading());

    final result = await _signUp(
      email: event.email,
      password: event.password,
    );
    result.fold(
      (failure) {
        log('Sign up error', error: failure);
        if (failure is AuthException) {
          emit(SignupState.failure(failure.message));
        } else {
          emit(const SignupState.failure('An unexpected error occurred'));
        }
      },
      (user) => emit(SignupState.success(user)),
    );
  }
}

import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:revision/core/utils/auth_security_utils.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/usecases/sign_up_usecase.dart';

part 'signup_event.dart';
part 'signup_state.dart';

/// BLoC responsible for managing sign up functionality
class SignupBloc extends Bloc<SignupEvent, SignupState> {
  /// Creates a new [SignupBloc]
  SignupBloc({required SignUpUseCase signUp})
    : _signUp = signUp,
      super(const SignupState.initial()) {
    on<SignupRequested>(_onSignupRequested);
  }

  final SignUpUseCase _signUp;

  Future<void> _onSignupRequested(
    SignupRequested event,
    Emitter<SignupState> emit,
  ) async {
    try {
      // Validate that passwords match
      if (event.password != event.confirmPassword) {
        emit(const SignupState.failure('Passwords do not match'));
        return;
      }

      // Check rate limiting
      if (AuthSecurityUtils.isAuthRateLimited('signup_${event.email}')) {
        AuthSecurityUtils.logAuthError(
          'Signup attempt rate limited',
          Exception('Rate limit exceeded'),
          data: {'email': event.email},
        );
        emit(
          const SignupState.failure('Too many signup attempts. Please try again later.'),
        );
        return;
      }

      emit(const SignupState.loading());

      final result = await AuthSecurityUtils.withAuthTimeout(
        _signUp(email: event.email, password: event.password),
        'signup',
      );

      result.fold(
        (failure) {
          AuthSecurityUtils.logAuthError('Signup failed', failure);
          emit(SignupState.failure(failure.message));
        },
        (user) {
          AuthSecurityUtils.logAuthEvent('Signup successful', user: user);
          emit(SignupState.success(user));
        },
      );
    } catch (e) {
      AuthSecurityUtils.logAuthError('Signup error', e);
      final errorCategory = AuthSecurityUtils.categorizeAuthError(e);
      emit(SignupState.failure(errorCategory.userMessage));
    }
  }
}

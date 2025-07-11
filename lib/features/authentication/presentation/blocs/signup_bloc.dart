import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:revision/core/utils/auth_security_utils.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/usecases/sign_up_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/send_email_verification_usecase.dart';

part 'signup_event.dart';
part 'signup_state.dart';

/// BLoC responsible for managing sign up functionality.
class SignupBloc extends Bloc<SignupEvent, SignupState> {
  SignupBloc({
    required SignUpUseCase signUp,
    required SendEmailVerificationUseCase sendEmailVerification,
  })  : _signUp = signUp,
        _sendEmailVerification = sendEmailVerification,
        super(const SignupState.initial()) {
    on<SignupRequested>(_onSignupRequested);
  }

  final SignUpUseCase _signUp;
  final SendEmailVerificationUseCase _sendEmailVerification;

  Future<void> _onSignupRequested(
    SignupRequested event,
    Emitter<SignupState> emit,
  ) async {
    try {
      // Validate passwords match
      if (event.password != event.confirmPassword) {
        emit(const SignupState.failure('Passwords do not match'));
        return;
      }

      // Validate terms of service acceptance
      if (!event.acceptedTerms) {
        emit(const SignupState.failure('You must accept the Terms of Service'));
        return;
      }

      // Validate privacy policy acceptance
      if (!event.acceptedPrivacy) {
        emit(const SignupState.failure('You must accept the Privacy Policy'));
        return;
      }

      // Validate age requirement
      if (!event.isAdult) {
        emit(const SignupState.failure('You must be at least 13 years old to use this service'));
        return;
      }

      // Validate security question if enabled
      if (event.securityQuestion != null &&
          (event.securityAnswer == null || event.securityAnswer!.isEmpty)) {
        emit(const SignupState.failure('Please provide an answer to your security question'));
        return;
      }

      if (event.securityAnswer != null && event.securityAnswer!.length < 3) {
        emit(const SignupState.failure('Security answer must be at least 3 characters'));
        return;
      }

      // Check rate limiting
      if (AuthSecurityUtils.isAuthRateLimited('signup_${event.email}')) {
        AuthSecurityUtils.logAuthError(
          'Signup attempt rate limited',
          Exception('Rate limit exceeded'),
          data: {'email': event.email},
        );
        emit(const SignupState.failure('Too many signup attempts. Please try again later.'));
        return;
      }

      emit(const SignupState.loading());

      // Run sign up with timeout and error categorization
      final result = await AuthSecurityUtils.withAuthTimeout(
        _signUp(email: event.email, password: event.password),
        'signup',
      );

      await result.fold(
        (failure) async {
          AuthSecurityUtils.logAuthError('Signup failed', failure);
          emit(SignupState.failure(failure.message));
        },
        (user) async {
          AuthSecurityUtils.logAuthEvent('Signup successful', user: user);

          // Send email verification
          final verificationResult = await _sendEmailVerification();
          verificationResult.fold(
            (verificationFailure) {
              log('Email verification error', error: verificationFailure);
              // Still consider signup successful, but show warning
              emit(SignupState.success(user,
                  message: 'Account created successfully! Please check your email for verification link.'));
            },
            (_) {
              emit(SignupState.success(user,
                  message: 'Account created successfully! Please check your email for verification link.'));
            },
          );
        },
      );
    } catch (e) {
      AuthSecurityUtils.logAuthError('Signup error', e);
      final errorCategory = AuthSecurityUtils.categorizeAuthError(e);
      emit(SignupState.failure(errorCategory.userMessage));
    }
  }
}
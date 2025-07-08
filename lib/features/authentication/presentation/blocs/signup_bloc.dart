import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/usecases/send_email_verification_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/sign_up_usecase.dart';

part 'signup_event.dart';
part 'signup_state.dart';

/// BLoC responsible for managing sign up functionality
class SignupBloc extends Bloc<SignupEvent, SignupState> {
  /// Creates a new [SignupBloc]
  SignupBloc({
    required SignUpUseCase signUp,
    required SendEmailVerificationUseCase sendEmailVerification,
  }) : _signUp = signUp,
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
    // Validate that passwords match
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

    emit(const SignupState.loading());

    final result = await _signUp(email: event.email, password: event.password);
    result.fold((failure) {
      log('Sign up error', error: failure);
      // Extract message from Failure or fallback to generic message
      emit(SignupState.failure(failure.message));
    }, (user) async {
      // Send email verification after successful signup
      log('User signed up successfully, sending email verification');
      
      final verificationResult = await _sendEmailVerification();
      verificationResult.fold(
        (failure) {
          log('Email verification error', error: failure);
          // Still consider signup successful, but show warning
          emit(SignupState.success(user, 
            message: 'Account created successfully! Please check your email for verification link.'));
        },
        (_) {
          emit(SignupState.success(user, 
            message: 'Account created successfully! Please check your email for verification link.'));
        },
      );
    });
  }
}

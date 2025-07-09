part of 'signup_bloc.dart';

/// Base class for signup events
sealed class SignupEvent extends Equatable {
  /// Creates a new [SignupEvent]
  const SignupEvent();

  @override
  List<Object?> get props => [];
}

/// Event triggered when a user attempts to sign up
final class SignupRequested extends SignupEvent {
  /// Creates a new [SignupRequested]
  const SignupRequested({
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.acceptedTerms,
    required this.acceptedPrivacy,
    required this.isAdult,
    this.phoneNumber,
    this.securityQuestion,
    this.securityAnswer,
  });

  /// The email address
  final String email;

  /// The password
  final String password;

  /// The confirmation password
  final String confirmPassword;

  /// Whether the user accepted the terms of service
  final bool acceptedTerms;

  /// Whether the user accepted the privacy policy
  final bool acceptedPrivacy;

  /// Whether the user confirmed they are 13 or older
  final bool isAdult;

  /// Optional phone number for verification
  final String? phoneNumber;

  /// Optional security question
  final String? securityQuestion;

  /// Optional security answer
  final String? securityAnswer;

  @override
  List<Object?> get props => [
    email,
    password,
    confirmPassword,
    acceptedTerms,
    acceptedPrivacy,
    isAdult,
    phoneNumber,
    securityQuestion,
    securityAnswer,
  ];
}

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
  });

  /// The email address
  final String email;

  /// The password
  final String password;

  /// The confirmation password
  final String confirmPassword;

  @override
  List<Object> get props => [email, password, confirmPassword];
}

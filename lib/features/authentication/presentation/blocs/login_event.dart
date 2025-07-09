part of 'login_bloc.dart';

/// Base class for login events
sealed class LoginEvent extends Equatable {
  /// Creates a new [LoginEvent]
  const LoginEvent();

  @override
  List<Object?> get props => [];
}

/// Event triggered when user requests to log in
final class LoginRequested extends LoginEvent {
  /// Creates a new [LoginRequested] event
  const LoginRequested({required this.email, required this.password});

  /// The email address to log in with
  final String email;

  /// The password to log in with
  final String password;

  @override
  List<Object> get props => [email, password];
}

/// Event triggered when user requests to log in with Google
final class LoginWithGoogleRequested extends LoginEvent {
  /// Creates a new [LoginWithGoogleRequested] event
  const LoginWithGoogleRequested();
}

/// Event triggered when user requests to reset password
final class ForgotPasswordRequested extends LoginEvent {
  /// Creates a new [ForgotPasswordRequested] event
  const ForgotPasswordRequested({required this.email});

  /// The email address to send password reset to
  final String email;

  @override
  List<Object> get props => [email];
}

/// Event triggered when user requests biometric authentication
final class BiometricLoginRequested extends LoginEvent {
  /// Creates a new [BiometricLoginRequested] event
  const BiometricLoginRequested();
}

/// Event triggered when password strength needs to be validated
final class PasswordStrengthChecked extends LoginEvent {
  /// Creates a new [PasswordStrengthChecked] event
  const PasswordStrengthChecked({required this.password});

  /// The password to check strength for
  final String password;

  @override
  List<Object> get props => [password];
}

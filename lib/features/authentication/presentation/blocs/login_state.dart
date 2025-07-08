part of 'login_bloc.dart';

import 'package:revision/core/utils/security_utils.dart';

/// Enum representing the different statuses of login
enum LoginStatus {
  /// Initial state
  initial,

  /// Loading state while performing authentication
  loading,

  /// Authentication was successful
  success,

  /// Authentication failed
  failure,

  /// Rate limited - too many attempts
  rateLimited,

  /// Account locked due to failed attempts
  accountLocked,

  /// CAPTCHA required
  captchaRequired,
}

/// State representing the current login status
class LoginState extends Equatable {
  /// Creates a new [LoginState]
  const LoginState({
    this.status = LoginStatus.initial,
    this.errorMessage,
    this.passwordStrength,
    this.failedAttempts = 0,
    this.isRateLimited = false,
    this.showCaptcha = false,
    this.biometricAvailable = false,
    this.rememberMe = false,
  });

  /// The current status of login
  final LoginStatus status;

  /// Error message in case of failure
  final String? errorMessage;

  /// Current password strength
  final PasswordStrength? passwordStrength;

  /// Number of failed login attempts
  final int failedAttempts;

  /// Whether the user is currently rate limited
  final bool isRateLimited;

  /// Whether CAPTCHA should be shown
  final bool showCaptcha;

  /// Whether biometric authentication is available
  final bool biometricAvailable;

  /// Whether remember me is enabled
  final bool rememberMe;

  /// Creates a copy of the current state with updated values
  LoginState copyWith({
    LoginStatus? status,
    String? errorMessage,
    PasswordStrength? passwordStrength,
    int? failedAttempts,
    bool? isRateLimited,
    bool? showCaptcha,
    bool? biometricAvailable,
    bool? rememberMe,
  }) {
    return LoginState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      passwordStrength: passwordStrength ?? this.passwordStrength,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      isRateLimited: isRateLimited ?? this.isRateLimited,
      showCaptcha: showCaptcha ?? this.showCaptcha,
      biometricAvailable: biometricAvailable ?? this.biometricAvailable,
      rememberMe: rememberMe ?? this.rememberMe,
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        passwordStrength,
        failedAttempts,
        isRateLimited,
        showCaptcha,
        biometricAvailable,
        rememberMe,
      ];
}

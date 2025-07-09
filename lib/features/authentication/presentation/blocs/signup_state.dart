part of 'signup_bloc.dart';

/// Class representing the state of signup process
class SignupState extends Equatable {
  /// Creates a new [SignupState]
  const SignupState._({
    this.status = SignupStatus.initial,
    this.user,
    this.errorMessage,
    this.successMessage,
  });

  /// Creates a [SignupState] with initial status
  const SignupState.initial() : this._();

  /// Creates a [SignupState] with loading status
  const SignupState.loading() : this._(status: SignupStatus.loading);

  /// Creates a [SignupState] with success status
  const SignupState.success(User user, {String? message})
    : this._(status: SignupStatus.success, user: user, successMessage: message);

  /// Creates a [SignupState] with failure status
  const SignupState.failure(String message)
    : this._(status: SignupStatus.failure, errorMessage: message);

  /// The current status of signup
  final SignupStatus status;

  /// The user that was signed up, if successful
  final User? user;

  /// The error message, if signup failed
  final String? errorMessage;

  /// The success message, if signup succeeded
  final String? successMessage;

  @override
  List<Object?> get props => [status, user, errorMessage, successMessage];
}

/// Enum representing the possible signup statuses
enum SignupStatus {
  /// Initial state
  initial,

  /// Signup in progress
  loading,

  /// Signup successful
  success,

  /// Signup failed
  failure,
}

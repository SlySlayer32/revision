part of 'login_bloc.dart';

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
}

/// State representing the current login status
class LoginState extends Equatable {
  /// Creates a new [LoginState]
  const LoginState({this.status = LoginStatus.initial, this.errorMessage});

  /// The current status of login
  final LoginStatus status;

  /// Error message in case of failure
  final String? errorMessage;

  /// Creates a copy of the current state with updated values
  LoginState copyWith({LoginStatus? status, String? errorMessage}) {
    return LoginState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}

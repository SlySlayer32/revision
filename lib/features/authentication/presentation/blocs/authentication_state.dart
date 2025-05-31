part of 'authentication_bloc.dart';

/// Class representing the state of authentication
class AuthenticationState extends Equatable {
  const AuthenticationState._({
    this.status = AuthenticationStatus.unknown,
    this.user,
  });

  /// Creates an [AuthenticationState] with unknown status
  const AuthenticationState.unknown() : this._();

  /// Creates an [AuthenticationState] with authenticated status
  const AuthenticationState.authenticated(User user)
      : this._(status: AuthenticationStatus.authenticated, user: user);

  /// Creates an [AuthenticationState] with unauthenticated status
  const AuthenticationState.unauthenticated()
      : this._(status: AuthenticationStatus.unauthenticated);

  /// The current status of authentication
  final AuthenticationStatus status;

  /// The current user, or null if unauthenticated
  final User? user;

  @override
  List<Object?> get props => [status, user];
}

/// Enum representing the possible authentication statuses
enum AuthenticationStatus {
  /// User is authenticated
  authenticated,

  /// User is not authenticated
  unauthenticated,

  /// Authentication status is not yet determined
  unknown,
}

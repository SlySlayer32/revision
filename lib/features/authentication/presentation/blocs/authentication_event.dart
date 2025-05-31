part of 'authentication_bloc.dart';

/// Base class for authentication events
sealed class AuthenticationEvent extends Equatable {
  /// Creates a new [AuthenticationEvent]
  const AuthenticationEvent();

  @override
  List<Object?> get props => [];
}

/// Event triggered when authentication status changes
final class AuthenticationStatusChanged extends AuthenticationEvent {
  /// Creates a new [AuthenticationStatusChanged]
  const AuthenticationStatusChanged(this.user);

  /// The current user, or null if unauthenticated
  final User? user;

  @override
  List<Object?> get props => [user];
}

/// Event triggered when user requests to log out
final class AuthenticationLogoutRequested extends AuthenticationEvent {}

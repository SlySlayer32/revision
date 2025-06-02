import 'package:equatable/equatable.dart';

/// Base class for authentication exceptions
abstract class AuthException extends Equatable implements Exception {
  /// Creates a new AuthException with a message and optional code
  const AuthException(this.message, [this.code]);

  /// The error message describing what went wrong
  final String message;

  /// The error code for programmatic handling
  final String? code;

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() =>
      '$runtimeType: $message${code != null ? ' (code: $code)' : ''}';
}

/// Exception thrown when credentials are invalid
class InvalidCredentialsException extends AuthException {
  /// Creates a new InvalidCredentialsException
  const InvalidCredentialsException([
    super.message = 'Invalid email or password',
    super.code = 'invalid-credentials',
  ]);
}

/// Exception thrown when email format is invalid
class InvalidEmailException extends AuthException {
  /// Creates a new InvalidEmailException
  const InvalidEmailException([
    super.message = 'Please enter a valid email address.',
    super.code = 'invalid-email',
  ]);
}

/// Exception thrown when password is too weak
class WeakPasswordException extends AuthException {
  /// Creates a new WeakPasswordException
  const WeakPasswordException([
    super.message = 'Password is too weak',
    super.code = 'weak-password',
  ]);
}

/// Exception thrown when user is not found
class UserNotFoundException extends AuthException {
  /// Creates a new UserNotFoundException
  const UserNotFoundException([
    super.message = 'User not found',
    super.code = 'user-not-found',
  ]);
}

/// Exception thrown when a user email already exists during sign-up
class EmailAlreadyInUseException extends AuthException {
  /// Creates a new EmailAlreadyInUseException
  const EmailAlreadyInUseException([
    super.message = 'Email already in use',
    super.code = 'email-already-in-use',
  ]);
}

/// Exception thrown when a network issue occurs
class NetworkException extends AuthException {
  /// Creates a new NetworkException
  const NetworkException([
    super.message = 'Network error occurred',
    super.code = 'network-error',
  ]);
}

/// Exception thrown when an unexpected error occurs
class UnexpectedAuthException extends AuthException {
  /// Creates a new UnexpectedAuthException
  const UnexpectedAuthException([
    super.message = 'An unexpected error occurred',
    super.code = 'unexpected-error',
  ]);
}

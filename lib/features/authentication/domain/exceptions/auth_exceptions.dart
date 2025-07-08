import 'package:revision/core/error/exceptions.dart';

// Base authentication exception
class AuthenticationException extends AppException {
  const AuthenticationException(super.message, [super.code]);
}

// Specific authentication exceptions
class InvalidCredentialsException extends AuthenticationException {
  const InvalidCredentialsException()
    : super('Invalid email or password', 'invalid-credentials');
}

class UserNotFoundException extends AuthenticationException {
  const UserNotFoundException()
    : super('No user found with this email', 'user-not-found');
}

class EmailAlreadyInUseException extends AuthenticationException {
  const EmailAlreadyInUseException()
    : super('Email is already in use', 'email-already-in-use');
}

class WeakPasswordException extends AuthenticationException {
  const WeakPasswordException()
    : super('Password is too weak', 'weak-password');
}

class NetworkAuthException extends AuthenticationException {
  const NetworkAuthException()
    : super('Network connection failed', 'network-request-failed');
}

class TooManyRequestsException extends AuthenticationException {
  const TooManyRequestsException()
    : super('Too many requests. Try again later', 'too-many-requests');
}

class AccountDisabledException extends AuthenticationException {
  const AccountDisabledException()
    : super('User account has been disabled', 'user-disabled');
}

class EmailNotVerifiedException extends AuthenticationException {
  const EmailNotVerifiedException()
    : super('Email address is not verified', 'email-not-verified');
}

class ReauthenticationRequiredException extends AuthenticationException {
  const ReauthenticationRequiredException()
    : super('Recent authentication required', 'requires-recent-login');
}

class ProviderAlreadyLinkedException extends AuthenticationException {
  const ProviderAlreadyLinkedException()
    : super(
        'Account is already linked to another provider',
        'provider-already-linked',
      );
}

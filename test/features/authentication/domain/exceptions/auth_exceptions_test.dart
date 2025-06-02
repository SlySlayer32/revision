import 'package:flutter_test/flutter_test.dart';
import 'package:revision/features/authentication/domain/exceptions/auth_exceptions.dart';

void main() {
  group('Authentication Exceptions', () {
    test('InvalidCredentialsException should have correct message', () {
      const exception = InvalidCredentialsException();
      expect(exception.message, equals('Invalid email or password'));
      expect(exception.code, equals('invalid-credentials'));
    });

    test('UserNotFoundException should have correct message', () {
      const exception = UserNotFoundException();
      expect(exception.message, equals('No user found with this email'));
      expect(exception.code, equals('user-not-found'));
    });

    test('EmailAlreadyInUseException should have correct message', () {
      const exception = EmailAlreadyInUseException();
      expect(exception.message, equals('Email is already in use'));
      expect(exception.code, equals('email-already-in-use'));
    });

    test('WeakPasswordException should have correct message', () {
      const exception = WeakPasswordException();
      expect(exception.message, equals('Password is too weak'));
      expect(exception.code, equals('weak-password'));
    });

    test('NetworkException should have correct message', () {
      const exception = NetworkAuthException();
      expect(exception.message, equals('Network connection failed'));
      expect(exception.code, equals('network-request-failed'));
    });

    test('TooManyRequestsException should have correct message', () {
      const exception = TooManyRequestsException();
      expect(exception.message, equals('Too many requests. Try again later'));
      expect(exception.code, equals('too-many-requests'));
    });

    test('AccountDisabledException should have correct message', () {
      const exception = AccountDisabledException();
      expect(exception.message, equals('User account has been disabled'));
      expect(exception.code, equals('user-disabled'));
    });

    test('EmailNotVerifiedException should have correct message', () {
      const exception = EmailNotVerifiedException();
      expect(exception.message, equals('Email address is not verified'));
      expect(exception.code, equals('email-not-verified'));
    });

    test('should be subclasses of AuthenticationException', () {
      expect(
        const InvalidCredentialsException(),
        isA<AuthenticationException>(),
      );
      expect(
        const UserNotFoundException(),
        isA<AuthenticationException>(),
      );
      expect(
        const EmailAlreadyInUseException(),
        isA<AuthenticationException>(),
      );
      expect(
        const WeakPasswordException(),
        isA<AuthenticationException>(),
      );
      expect(
        const NetworkAuthException(),
        isA<AuthenticationException>(),
      );
      expect(
        const TooManyRequestsException(),
        isA<AuthenticationException>(),
      );
      expect(
        const AccountDisabledException(),
        isA<AuthenticationException>(),
      );
      expect(
        const EmailNotVerifiedException(),
        isA<AuthenticationException>(),
      );
    });
  });
}

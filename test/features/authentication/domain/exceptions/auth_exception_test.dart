import 'package:flutter_test/flutter_test.dart';
import 'package:revision/features/authentication/domain/exceptions/auth_exception.dart';

void main() {
  group('AuthException', () {
    test('creates an auth exception with message', () {
      const message = 'Test error message';
      const exception = EmailAlreadyInUseException(message);

      expect(exception.message, equals(message));
      expect(
        exception.toString(),
        equals(
            'EmailAlreadyInUseException: $message (code: email-already-in-use)'),
      );
    });

    test('supports value comparisons', () {
      const message = 'Test error';
      const exception1 = EmailAlreadyInUseException(message);
      const exception2 = EmailAlreadyInUseException(message);

      expect(exception1, equals(exception2));
    });
  });

  group('InvalidCredentialsException', () {
    test('creates exception with default message', () {
      const exception = InvalidCredentialsException();

      expect(exception.message, equals('Invalid email or password'));
    });

    test('creates exception with custom message', () {
      const customMessage = 'Custom invalid credentials message';
      const exception = InvalidCredentialsException(customMessage);

      expect(exception.message, equals(customMessage));
    });
  });

  group('EmailAlreadyInUseException', () {
    test('creates exception with default message', () {
      const exception = EmailAlreadyInUseException();

      expect(exception.message, equals('Email already in use'));
    });

    test('creates exception with custom message', () {
      const customMessage = 'Custom email in use message';
      const exception = EmailAlreadyInUseException(customMessage);

      expect(exception.message, equals(customMessage));
    });
  });

  group('WeakPasswordException', () {
    test('creates exception with default message', () {
      const exception = WeakPasswordException();

      expect(exception.message, equals('Password is too weak'));
    });

    test('creates exception with custom message', () {
      const customMessage = 'Custom weak password message';
      const exception = WeakPasswordException(customMessage);

      expect(exception.message, equals(customMessage));
    });
  });

  group('UserNotFoundException', () {
    test('creates exception with default message', () {
      const exception = UserNotFoundException();

      expect(exception.message, equals('User not found'));
    });

    test('creates exception with custom message', () {
      const customMessage = 'Custom user not found message';
      const exception = UserNotFoundException(customMessage);

      expect(exception.message, equals(customMessage));
    });
  });

  group('NetworkException', () {
    test('creates exception with default message', () {
      const exception = NetworkException();

      expect(exception.message, equals('Network error occurred'));
    });

    test('creates exception with custom message', () {
      const customMessage = 'Custom network error message';
      const exception = NetworkException(customMessage);

      expect(exception.message, equals(customMessage));
    });
  });

  group('UnexpectedAuthException', () {
    test('creates exception with default message', () {
      const exception = UnexpectedAuthException();

      expect(exception.message, equals('An unexpected error occurred'));
    });

    test('creates exception with custom message', () {
      const customMessage = 'Custom unexpected error message';
      const exception = UnexpectedAuthException(customMessage);

      expect(exception.message, equals(customMessage));
    });
  });
}

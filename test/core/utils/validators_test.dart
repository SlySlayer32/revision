// VGV-compliant validators tests
// Following Very Good Ventures testing patterns

import 'package:flutter_test/flutter_test.dart';
import 'package:revision/core/utils/validators.dart';

void main() {
  group('Validators', () {
    group('validateEmail', () {
      test('should return null for valid emails', () {
        const validEmails = [
          'test@example.com',
          'user.name@domain.co.uk',
          'user+tag@example.org',
          'user123@test-domain.com',
          'a@b.co',
          'very.long.email.address@very-long-domain-name.com',
        ];

        for (final email in validEmails) {
          expect(
            Validators.validateEmail(email),
            isNull,
            reason: 'Failed for: $email',
          );
        }
      });

      test('should return error for invalid emails', () {
        const invalidEmails = [
          'invalid-email',
          '@example.com',
          'user@',
          'user@@example.com',
          'user@.com',
          'user@example.',
          'user name@example.com',
          'user@exam ple.com',
          'user@example..com',
          '.user@example.com',
          'user.@example.com',
        ];

        for (final email in invalidEmails) {
          expect(
            Validators.validateEmail(email),
            isNotNull,
            reason: 'Should fail for: $email',
          );
        }
      });

      test('should return error for empty string', () {
        expect(
          Validators.validateEmail(''),
          equals('Email cannot be empty'),
        );
      });

      test('should return error for invalid format', () {
        expect(
          Validators.validateEmail('invalid-email'),
          equals('Please enter a valid email'),
        );
      });
    });

    group('validatePassword', () {
      test('should return null for valid passwords', () {
        const validPasswords = [
          'password123',
          'mypassword',
          'test123',
          'validpass',
          'longpassword1234',
        ];

        for (final password in validPasswords) {
          expect(
            Validators.validatePassword(password),
            isNull,
            reason: 'Failed for: $password',
          );
        }
      });

      test('should return error for empty password', () {
        expect(
          Validators.validatePassword(''),
          equals('Password cannot be empty'),
        );
      });

      test('should return error for passwords too short', () {
        const shortPasswords = [
          '123',
          'pass',
          '12345',
        ];

        for (final password in shortPasswords) {
          expect(
            Validators.validatePassword(password),
            equals('Password must be at least 6 characters'),
            reason: 'Should fail for short password: $password',
          );
        }
      });
    });

    group('validateDisplayName', () {
      test('should return null for valid display names', () {
        const validNames = [
          'John',
          'Jane Doe',
          'Mary-Jane',
          "O'Connor",
          'José',
          'François',
          'Anna-Maria',
          'Dr. Smith',
          'Valid Display Name',
        ];

        for (final name in validNames) {
          expect(
            Validators.validateDisplayName(name),
            isNull,
            reason: 'Failed for: $name',
          );
        }
      });

      test('should return error for null input', () {
        expect(
          Validators.validateDisplayName(null),
          equals('Display name cannot be empty'),
        );
      });

      test('should return error for empty string', () {
        expect(
          Validators.validateDisplayName(''),
          equals('Display name cannot be empty'),
        );
      });

      test('should return error for names too short', () {
        expect(
          Validators.validateDisplayName('A'),
          equals('Display name must be at least 2 characters'),
        );
      });

      test('should return error for names too long', () {
        final longName = 'A' * 51;
        expect(
          Validators.validateDisplayName(longName),
          equals('Display name cannot exceed 50 characters'),
        );
      });
    });

    group('edge cases', () {
      test('should handle unicode characters in display names', () {
        expect(Validators.validateDisplayName('José María'), isNull);
        expect(Validators.validateDisplayName('François'), isNull);
      });

      test('should handle special characters in display names', () {
        expect(Validators.validateDisplayName("O'Connor"), isNull);
        expect(Validators.validateDisplayName('Mary-Jane'), isNull);
        expect(Validators.validateDisplayName('Dr. Smith'), isNull);
      });

      test('should handle international email domains', () {
        expect(Validators.validateEmail('test@domain.co.uk'), isNull);
        expect(Validators.validateEmail('user@sub.domain.org'), isNull);
      });

      test('should handle long but valid inputs', () {
        const longEmail = 'very.long.email.address@very-long-domain-name.com';
        expect(Validators.validateEmail(longEmail), isNull);

        const longPassword = 'very-long-password-that-meets-requirements';
        expect(Validators.validatePassword(longPassword), isNull);

        const longName = 'This is a fairly long display name but valid';
        expect(Validators.validateDisplayName(longName), isNull);
      });
    });
  });
}

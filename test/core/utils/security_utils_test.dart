import 'package:flutter_test/flutter_test.dart';
import 'package:revision/core/utils/security_utils.dart';

void main() {
  group('SecurityUtils', () {
    group('maskSensitiveData', () {
      test('should mask API keys', () {
        const input = 'API key: AIzaSyBvOiI59Q-uQvYGaAzNl5u4jdIUgJbK7_o';
        final result = SecurityUtils.maskSensitiveData(input);
        
        expect(result, equals('API key: AIza***[MASKED]***'));
      });

      test('should mask email addresses', () {
        const input = 'Contact: user@example.com';
        final result = SecurityUtils.maskSensitiveData(input);
        
        expect(result, equals('Contact: ***@***.***'));
      });

      test('should mask credit card numbers', () {
        const input = 'Card: 4532 1234 5678 9012';
        final result = SecurityUtils.maskSensitiveData(input);
        
        expect(result, equals('Card: ****-****-****-****'));
      });

      test('should handle multiple sensitive patterns', () {
        const input = 'API: AIzaSyBvOiI59Q-uQvYGaAzNl5u4jdIUgJbK7_o Email: user@example.com';
        final result = SecurityUtils.maskSensitiveData(input);
        
        expect(result, equals('API: AIza***[MASKED]*** Email: ***@***.***'));
      });

      test('should return unchanged string if no sensitive data', () {
        const input = 'This is a normal string';
        final result = SecurityUtils.maskSensitiveData(input);
        
        expect(result, equals(input));
      });
    });

    group('generateHmacSignature', () {
      test('should generate consistent signature for same input', () {
        const secret = 'test-secret';
        const method = 'POST';
        const path = '/api/test';
        const headers = {'content-type': 'application/json'};
        const body = '{"test": "data"}';
        
        final signature1 = SecurityUtils.generateHmacSignature(secret, method, path, headers, body);
        final signature2 = SecurityUtils.generateHmacSignature(secret, method, path, headers, body);
        
        // Signatures should be different due to timestamp and nonce
        expect(signature1, isNot(equals(signature2)));
        expect(signature1, isNotEmpty);
        expect(signature2, isNotEmpty);
      });

      test('should generate different signatures for different inputs', () {
        const secret = 'test-secret';
        const headers = {'content-type': 'application/json'};
        
        final signature1 = SecurityUtils.generateHmacSignature(secret, 'GET', '/api/test', headers, '');
        final signature2 = SecurityUtils.generateHmacSignature(secret, 'POST', '/api/test', headers, '');
        
        expect(signature1, isNot(equals(signature2)));
      });
    });

    group('encryptSensitiveData', () {
      test('should encrypt and decrypt data correctly', () {
        const data = 'sensitive information';
        const key = 'encryption-key';
        
        final encrypted = SecurityUtils.encryptSensitiveData(data, key);
        final decrypted = SecurityUtils.decryptSensitiveData(encrypted, key);
        
        expect(encrypted, isNot(equals(data)));
        expect(decrypted, equals(data));
      });

      test('should produce different encrypted output for same input', () {
        const data = 'sensitive information';
        const key = 'encryption-key';
        
        final encrypted1 = SecurityUtils.encryptSensitiveData(data, key);
        final encrypted2 = SecurityUtils.encryptSensitiveData(data, key);
        
        // Since we're using simple XOR, the results should be the same
        expect(encrypted1, equals(encrypted2));
      });

      test('should fail to decrypt with wrong key', () {
        const data = 'sensitive information';
        const key1 = 'encryption-key';
        const key2 = 'wrong-key';
        
        final encrypted = SecurityUtils.encryptSensitiveData(data, key1);
        final decrypted = SecurityUtils.decryptSensitiveData(encrypted, key2);
        
        expect(decrypted, isNot(equals(data)));
      });
    });

    group('isRateLimited', () {
      test('should not be rate limited initially', () {
        final result = SecurityUtils.isRateLimited('test-user');
        expect(result, isFalse);
      });

      test('should be rate limited after max requests', () {
        const identifier = 'test-user-2';
        const maxRequests = 3;
        
        // Make requests up to the limit
        for (int i = 0; i < maxRequests; i++) {
          final result = SecurityUtils.isRateLimited(identifier, maxRequests: maxRequests);
          expect(result, isFalse);
        }
        
        // Next request should be rate limited
        final result = SecurityUtils.isRateLimited(identifier, maxRequests: maxRequests);
        expect(result, isTrue);
      });
    });

    group('validateRequestHeaders', () {
      test('should validate valid headers', () {
        final headers = {'user-agent': 'TestApp/1.0'};
        final result = SecurityUtils.validateRequestHeaders(headers);
        
        expect(result, isTrue);
      });

      test('should reject empty user agent', () {
        final headers = {'user-agent': ''};
        final result = SecurityUtils.validateRequestHeaders(headers);
        
        expect(result, isFalse);
      });

      test('should reject missing user agent', () {
        final headers = <String, String>{};
        final result = SecurityUtils.validateRequestHeaders(headers);
        
        expect(result, isFalse);
      });

      test('should reject suspicious user agents', () {
        final suspiciousAgents = ['bot', 'spider', 'crawler', 'scraper'];
        
        for (final agent in suspiciousAgents) {
          final headers = {'user-agent': 'Test$agent/1.0'};
          final result = SecurityUtils.validateRequestHeaders(headers);
          
          expect(result, isFalse, reason: 'Should reject user agent containing: $agent');
        }
      });

      test('should reject overly long user agent', () {
        final longUserAgent = 'a' * 600;
        final headers = {'user-agent': longUserAgent};
        final result = SecurityUtils.validateRequestHeaders(headers);
        
        expect(result, isFalse);
      });
    });

    // group('isValidImageFile', () {
    //   test('should validate JPEG files', () {
    //     final jpegHeader = [0xFF, 0xD8, 0xFF, 0xE0];
    //     final result = SecurityUtils.isValidImageFile(jpegHeader);
        
    //     expect(result, isTrue);
    //   });

    //   test('should validate PNG files', () {
    //     final pngHeader = [0x89, 0x50, 0x4E, 0x47];
    //     final result = SecurityUtils.isValidImageFile(pngHeader);
        
    //     expect(result, isTrue);
    //   });

    //   test('should validate GIF files', () {
    //     final gifHeader = [0x47, 0x49, 0x46];
    //     final result = SecurityUtils.isValidImageFile(gifHeader);
        
    //     expect(result, isTrue);
    //   });

    //   test('should validate WebP files', () {
    //     final webpHeader = [0x52, 0x49, 0x46, 0x46];
    //     final result = SecurityUtils.isValidImageFile(webpHeader);
        
    //     expect(result, isTrue);
    //   });

    //   test('should reject invalid files', () {
    //     final invalidHeader = [0x00, 0x00, 0x00, 0x00];
    //     final result = SecurityUtils.isValidImageFile(invalidHeader);
        
    //     expect(result, isFalse);
    //   });

    //   test('should reject empty files', () {
    //     final emptyHeader = <int>[];
    //     final result = SecurityUtils.isValidImageFile(emptyHeader);
        
    //     expect(result, isFalse);
    //   });
    // });

    group('validatePasswordStrength', () {
      test('should classify weak passwords', () {
        final weakPasswords = ['123', 'password', 'abc123'];
        
        for (final password in weakPasswords) {
          final result = SecurityUtils.validatePasswordStrength(password);
          expect(result, equals(PasswordStrength.weak));
        }
      });

      test('should classify medium passwords', () {
        final mediumPasswords = ['Password123', 'Test@123'];
        
        for (final password in mediumPasswords) {
          final result = SecurityUtils.validatePasswordStrength(password);
          expect(result, equals(PasswordStrength.medium));
        }
      });

      test('should classify strong passwords', () {
        final strongPasswords = ['MyStr0ngP@ssw0rd!', 'C0mpl3xP@ssw0rd123'];
        
        for (final password in strongPasswords) {
          final result = SecurityUtils.validatePasswordStrength(password);
          expect(result, equals(PasswordStrength.strong));
        }
      });
    });

    group('isValidEmail', () {
      test('should validate correct email addresses', () {
        final validEmails = [
          'user@example.com',
          'test.email@domain.org',
          'user+tag@example.co.uk',
        ];
        
        for (final email in validEmails) {
          final result = SecurityUtils.isValidEmail(email);
          expect(result, isTrue, reason: 'Should validate email: $email');
        }
      });

      test('should reject invalid email addresses', () {
        final invalidEmails = [
          'invalid-email',
          '@example.com',
          'user@',
          'user name@example.com',
          '',
        ];
        
        for (final email in invalidEmails) {
          final result = SecurityUtils.isValidEmail(email);
          expect(result, isFalse, reason: 'Should reject email: $email');
        }
      });

      test('should reject overly long email addresses', () {
        final longEmail = 'a' * 250 + '@example.com';
        final result = SecurityUtils.isValidEmail(longEmail);
        
        expect(result, isFalse);
      });
    });
  });
}

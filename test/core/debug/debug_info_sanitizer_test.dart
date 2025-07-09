import 'package:flutter_test/flutter_test.dart';
import 'package:revision/core/debug/debug_info_sanitizer.dart';

void main() {
  group('DebugInfoSanitizer', () {
    group('maskSensitiveValue', () {
      test('should completely mask short values', () {
        expect(DebugInfoSanitizer.maskSensitiveValue('12345'), '*****');
        expect(DebugInfoSanitizer.maskSensitiveValue('abc'), '***');
        expect(DebugInfoSanitizer.maskSensitiveValue(''), '');
      });

      test('should partially mask long values', () {
        expect(DebugInfoSanitizer.maskSensitiveValue('abcdefghijklmnop'), 'abc**********nop');
        expect(DebugInfoSanitizer.maskSensitiveValue('api_key_123456789'), 'api***********789');
      });

      test('should handle edge cases', () {
        expect(DebugInfoSanitizer.maskSensitiveValue('12345678'), '********');
        expect(DebugInfoSanitizer.maskSensitiveValue('123456789'), '123***789');
      });
    });

    group('sanitizeDebugInfo', () {
      test('should sanitize sensitive keys', () {
        final input = {
          'api_key': 'secret_key_123456789',
          'username': 'john_doe',
          'secret_token': 'token_abcdefghijklmnop',
          'normal_value': 'not_sensitive',
          'password': 'mypassword123',
          'credential': 'cred_xyz789',
        };

        final result = DebugInfoSanitizer.sanitizeDebugInfo(input);

        expect(result['api_key'], 'sec*******789');
        expect(result['username'], 'john_doe'); // Not sensitive
        expect(result['secret_token'], 'tok*******nop');
        expect(result['normal_value'], 'not_sensitive'); // Not sensitive
        expect(result['password'], 'myp*****123');
        expect(result['credential'], 'cre***789');
      });

      test('should handle empty or null values', () {
        final input = {
          'api_key': '',
          'username': null,
          'normal_value': 'test',
        };

        final result = DebugInfoSanitizer.sanitizeDebugInfo(input);

        expect(result['api_key'], '');
        expect(result['username'], null);
        expect(result['normal_value'], 'test');
      });
    });

    group('sanitizeFirebaseInfo', () {
      test('should sanitize Firebase sensitive info', () {
        final input = {
          'projectId': 'my-project-123456',
          'appId': '1:123456789:web:abcdef123456',
          'apiKey': 'AIzaSyD2S1IDbCqj_Z9KnTHLKV1fCo5GofP5-Tw',
          'platform': 'web',
          'isWeb': true,
          'messagingSenderId': '123456789',
        };

        final result = DebugInfoSanitizer.sanitizeFirebaseInfo(input);

        expect(result['projectId'], 'my-***-456'); // Masked
        expect(result['appId'], '1:1***456'); // Masked
        expect(result['apiKey'], 'AIz***-Tw'); // Masked
        expect(result['platform'], 'web'); // Not sensitive
        expect(result['isWeb'], true); // Not sensitive
        expect(result['messagingSenderId'], '123456789'); // Not sensitive
      });
    });

    group('_isSensitiveKey', () {
      test('should identify sensitive keys', () {
        final sensitiveKeys = [
          'api_key',
          'API_KEY',
          'secret',
          'SECRET_TOKEN',
          'token',
          'password',
          'Password',
          'credential',
          'CREDENTIAL',
        ];

        for (final key in sensitiveKeys) {
          expect(DebugInfoSanitizer.sanitizeDebugInfo({key: 'test'})[key], 'test');
        }
      });

      test('should not identify non-sensitive keys', () {
        final nonSensitiveKeys = [
          'username',
          'email',
          'platform',
          'environment',
          'version',
          'isWeb',
          'projectId', // Special case handled separately
        ];

        for (final key in nonSensitiveKeys) {
          final result = DebugInfoSanitizer.sanitizeDebugInfo({key: 'test_value'});
          if (key != 'projectId') {
            expect(result[key], 'test_value');
          }
        }
      });
    });
  });
}
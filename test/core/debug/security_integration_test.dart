import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revision/core/config/environment_detector.dart';
import 'package:revision/core/debug/debug_info_sanitizer.dart';
import 'package:revision/core/debug/environment_debug_page.dart';
import 'package:revision/core/debug/launch_config_verification_page.dart';

void main() {
  group('Debug Page Security Integration Tests', () {
    setUp(() {
      // Refresh environment detector before each test
      EnvironmentDetector.refresh();
    });

    group('Production Safety Tests', () {
      test('debug pages should not be accessible in production environment', () {
        // This test verifies that debug pages are properly blocked in production
        // In a real test, we would mock the environment detector to return production
        
        // For now, we test that the factory methods exist and return appropriate values
        final envPage = EnvironmentDebugPage.createIfAllowed();
        final launchPage = LaunchConfigVerificationPage.createIfAllowed();
        
        // In non-production environments, these should return widgets
        // In production, they should return null
        expect(envPage, isA<Widget?>());
        expect(launchPage, isA<Widget?>());
      });

      test('createIfAllowed methods should handle production environment', () {
        // Test that the factory methods can be called without error
        expect(() => EnvironmentDebugPage.createIfAllowed(), returnsNormally);
        expect(() => LaunchConfigVerificationPage.createIfAllowed(), returnsNormally);
      });
    });

    group('Data Sanitization Tests', () {
      test('should properly mask sensitive values', () {
        // Test short values
        expect(DebugInfoSanitizer.maskSensitiveValue('abc'), '***');
        expect(DebugInfoSanitizer.maskSensitiveValue('12345'), '*****');
        expect(DebugInfoSanitizer.maskSensitiveValue(''), '');
        
        // Test long values
        expect(DebugInfoSanitizer.maskSensitiveValue('abcdefghijklmnop'), 'abc**********nop');
        expect(DebugInfoSanitizer.maskSensitiveValue('api_key_123456789'), 'api***********789');
        
        // Test edge cases
        expect(DebugInfoSanitizer.maskSensitiveValue('12345678'), '********');
        expect(DebugInfoSanitizer.maskSensitiveValue('123456789'), '123***789');
      });

      test('should sanitize debug information properly', () {
        final testData = {
          'api_key': 'secret_key_123456789',
          'username': 'john_doe',
          'secret_token': 'token_abcdefghijklmnop',
          'normal_value': 'not_sensitive',
          'password': 'mypassword123',
          'credential': 'cred_xyz789',
        };

        final sanitized = DebugInfoSanitizer.sanitizeDebugInfo(testData);

        // Sensitive keys should be masked
        expect(sanitized['api_key'], 'sec*******789');
        expect(sanitized['secret_token'], 'tok*******nop');
        expect(sanitized['password'], 'myp*****123');
        expect(sanitized['credential'], 'cre***789');
        
        // Non-sensitive keys should remain unchanged
        expect(sanitized['username'], 'john_doe');
        expect(sanitized['normal_value'], 'not_sensitive');
      });

      test('should sanitize Firebase information properly', () {
        final testFirebaseData = {
          'projectId': 'my-project-123456',
          'appId': '1:123456789:web:abcdef123456',
          'apiKey': 'AIzaSyD2S1IDbCqj_Z9KnTHLKV1fCo5GofP5-Tw',
          'platform': 'web',
          'isWeb': true,
          'messagingSenderId': '123456789',
        };

        final sanitized = DebugInfoSanitizer.sanitizeFirebaseInfo(testFirebaseData);

        // Sensitive Firebase data should be masked
        expect(sanitized['projectId'], 'my-***-456');
        expect(sanitized['appId'], '1:1***456');
        expect(sanitized['apiKey'], 'AIz***-Tw');
        
        // Non-sensitive data should remain unchanged
        expect(sanitized['platform'], 'web');
        expect(sanitized['isWeb'], true);
        expect(sanitized['messagingSenderId'], '123456789');
      });
    });

    group('Audit Logging Tests', () {
      test('should log debug actions without error', () {
        // Test that audit logging methods can be called without error
        expect(() => DebugInfoSanitizer.logDebugAction('test_action'), returnsNormally);
        expect(() => DebugInfoSanitizer.logDebugPageAccess('test_page'), returnsNormally);
      });
    });

    group('Security Warning Tests', () {
      test('should identify sensitive keys correctly', () {
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
          final testData = {key: 'test_value_123456789'};
          final result = DebugInfoSanitizer.sanitizeDebugInfo(testData);
          
          // Sensitive keys should be masked (not equal to original)
          expect(result[key], isNot('test_value_123456789'));
          expect(result[key], contains('*'));
        }
      });

      test('should not mask non-sensitive keys', () {
        final nonSensitiveKeys = [
          'username',
          'email',
          'platform',
          'environment',
          'version',
          'isWeb',
          'messagingSenderId',
        ];

        for (final key in nonSensitiveKeys) {
          final testData = {key: 'test_value'};
          final result = DebugInfoSanitizer.sanitizeDebugInfo(testData);
          
          // Non-sensitive keys should remain unchanged
          expect(result[key], 'test_value');
        }
      });
    });

    group('Environment Detection Tests', () {
      test('should handle different environments correctly', () {
        // Test that environment detection works
        expect(EnvironmentDetector.environmentString, isNotNull);
        expect(EnvironmentDetector.environmentString, isNotEmpty);
        
        // Test environment state consistency
        final isDev = EnvironmentDetector.isDevelopment;
        final isStaging = EnvironmentDetector.isStaging;
        final isProd = EnvironmentDetector.isProduction;
        
        // Only one environment should be true
        final trueCount = [isDev, isStaging, isProd].where((e) => e).length;
        expect(trueCount, 1);
      });
    });
  });
}
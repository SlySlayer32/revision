import 'package:flutter_test/flutter_test.dart';
import 'package:revision/core/constants/environment_config.dart';

void main() {
  group('Environment', () {
    group('Environment Values', () {
      test('should have three environment types', () {
        expect(Environment.values.length, equals(3));
        expect(Environment.values, contains(Environment.development));
        expect(Environment.values, contains(Environment.staging));
        expect(Environment.values, contains(Environment.production));
      });

      test('should have correct string representations', () {
        expect(
          Environment.development.toString(),
          equals('Environment.development'),
        );
        expect(Environment.staging.toString(), equals('Environment.staging'));
        expect(
          Environment.production.toString(),
          equals('Environment.production'),
        );
      });
    });

    group('Name Extension', () {
      test('should return correct names for each environment', () {
        expect(Environment.development.name, equals('development'));
        expect(Environment.staging.name, equals('staging'));
        expect(Environment.production.name, equals('production'));
      });

      test('should have consistent naming', () {
        for (final env in Environment.values) {
          expect(env.name, isNotEmpty);
          expect(
            env.name,
            matches(RegExp(r'^[a-z]+$')),
          ); // Only lowercase letters
        }
      });
    });

    group('Firebase Functions URL Extension', () {
      test('should return correct URLs for each environment', () {
        expect(
          Environment.development.firebaseFunctionsUrl,
          equals('http://localhost:5001/revision-ai-editor/us-central1'),
        );
        expect(
          Environment.staging.firebaseFunctionsUrl,
          equals(
            'https://us-central1-revision-ai-editor-staging.cloudfunctions.net',
          ),
        );
        expect(
          Environment.production.firebaseFunctionsUrl,
          equals('https://us-central1-revision-ai-editor.cloudfunctions.net'),
        );
      });

      test('should use HTTPS for staging and production', () {
        expect(
          Environment.staging.firebaseFunctionsUrl,
          startsWith('https://'),
        );
        expect(
          Environment.production.firebaseFunctionsUrl,
          startsWith('https://'),
        );
      });

      test('should use HTTP for development (emulator)', () {
        expect(
          Environment.development.firebaseFunctionsUrl,
          startsWith('http://'),
        );
        expect(
          Environment.development.firebaseFunctionsUrl,
          contains('localhost'),
        );
        expect(Environment.development.firebaseFunctionsUrl, contains(':5001'));
      });

      test('should have valid URL formats', () {
        for (final env in Environment.values) {
          final url = env.firebaseFunctionsUrl;
          expect(url, isNotEmpty);
          expect(url, matches(RegExp('^https?://.+')));
        }
      });

      test('should include correct project naming', () {
        expect(
          Environment.development.firebaseFunctionsUrl,
          contains('revision-ai-editor'),
        );
        expect(
          Environment.staging.firebaseFunctionsUrl,
          contains('revision-ai-editor-staging'),
        );
        expect(
          Environment.production.firebaseFunctionsUrl,
          contains('revision-ai-editor'),
        );
      });

      test('should include correct region', () {
        for (final env in Environment.values) {
          expect(env.firebaseFunctionsUrl, contains('us-central1'));
        }
      });
    });

    group('Debug Mode Extension', () {
      test('should return true for development', () {
        expect(Environment.development.isDebugMode, isTrue);
      });

      test('should return false for staging and production', () {
        expect(Environment.staging.isDebugMode, isFalse);
        expect(Environment.production.isDebugMode, isFalse);
      });

      test('should have consistent debug mode logic', () {
        // Only development should have debug mode enabled
        final debugEnvironments =
            Environment.values.where((env) => env.isDebugMode);
        expect(debugEnvironments.length, equals(1));
        expect(debugEnvironments.first, equals(Environment.development));
      });
    });

    group('Analytics Extension', () {
      test('should return false for development', () {
        expect(Environment.development.enableAnalytics, isFalse);
      });

      test('should return true for staging and production', () {
        expect(Environment.staging.enableAnalytics, isTrue);
        expect(Environment.production.enableAnalytics, isTrue);
      });

      test('should have consistent analytics logic', () {
        // Development should not have analytics, others should
        final analyticsEnvironments =
            Environment.values.where((env) => env.enableAnalytics);
        expect(analyticsEnvironments.length, equals(2));
        expect(analyticsEnvironments, contains(Environment.staging));
        expect(analyticsEnvironments, contains(Environment.production));
      });
    });

    group('Environment Configuration Consistency', () {
      test('should have inverse relationship between debug and analytics', () {
        for (final env in Environment.values) {
          // Generally, debug environments don't need analytics and vice versa
          if (env == Environment.development) {
            expect(env.isDebugMode, isTrue);
            expect(env.enableAnalytics, isFalse);
          } else {
            expect(env.isDebugMode, isFalse);
            expect(env.enableAnalytics, isTrue);
          }
        }
      });

      test('should have correct emulator configuration for development', () {
        final devUrl = Environment.development.firebaseFunctionsUrl;
        expect(devUrl, contains('localhost'));
        expect(devUrl, contains('5001')); // Firebase Functions emulator port
        expect(Environment.development.isDebugMode, isTrue);
      });

      test(
          'should have production-ready configuration for non-dev environments',
          () {
        final prodEnvironments = [Environment.staging, Environment.production];

        for (final env in prodEnvironments) {
          expect(env.firebaseFunctionsUrl, startsWith('https://'));
          expect(env.firebaseFunctionsUrl, contains('cloudfunctions.net'));
          expect(env.isDebugMode, isFalse);
          expect(env.enableAnalytics, isTrue);
        }
      });
    });

    group('URL Security and Format Validation', () {
      test('should use secure protocols for production environments', () {
        expect(
          Environment.staging.firebaseFunctionsUrl,
          matches(RegExp('^https://')),
        );
        expect(
          Environment.production.firebaseFunctionsUrl,
          matches(RegExp('^https://')),
        );
      });

      test('should have valid domain formats', () {
        expect(
          Environment.staging.firebaseFunctionsUrl,
          contains('.cloudfunctions.net'),
        );
        expect(
          Environment.production.firebaseFunctionsUrl,
          contains('.cloudfunctions.net'),
        );
      });

      test('should not have trailing slashes', () {
        for (final env in Environment.values) {
          expect(env.firebaseFunctionsUrl, isNot(endsWith('/')));
        }
      });

      test('should have valid port for development', () {
        final devUrl = Environment.development.firebaseFunctionsUrl;
        final portMatch = RegExp(r':(\d+)').firstMatch(devUrl);
        expect(portMatch, isNotNull);

        final port = int.parse(portMatch!.group(1)!);
        expect(port, equals(5001)); // Standard Firebase Functions emulator port
        expect(port, greaterThan(1000));
        expect(port, lessThan(65536));
      });
    });

    group('Environment Naming Conventions', () {
      test('should follow consistent naming patterns', () {
        expect(Environment.development.name, matches(RegExp(r'^[a-z]+$')));
        expect(Environment.staging.name, matches(RegExp(r'^[a-z]+$')));
        expect(Environment.production.name, matches(RegExp(r'^[a-z]+$')));
      });

      test('should have meaningful names', () {
        final names = Environment.values.map((e) => e.name).toList();
        expect(names, contains('development'));
        expect(names, contains('staging'));
        expect(names, contains('production'));
      });

      test('should have unique names', () {
        final names = Environment.values.map((e) => e.name).toSet();
        expect(names.length, equals(Environment.values.length));
      });
    });

    group('Configuration Validation', () {
      test('should have valid configuration for each environment', () {
        for (final env in Environment.values) {
          // Name should be non-empty
          expect(env.name, isNotEmpty);

          // URL should be valid
          expect(env.firebaseFunctionsUrl, isNotEmpty);
          expect(env.firebaseFunctionsUrl, matches(RegExp('^https?://.+')));

          // Boolean flags should be consistent
          expect(env.isDebugMode, isA<bool>());
          expect(env.enableAnalytics, isA<bool>());
        }
      });

      test('should have different configurations for each environment', () {
        final configs = Environment.values
            .map(
              (env) => {
                'name': env.name,
                'url': env.firebaseFunctionsUrl,
                'debug': env.isDebugMode,
                'analytics': env.enableAnalytics,
              },
            )
            .toList();

        // Each environment should have a unique configuration
        expect(configs.length, equals(3));

        // URLs should be different
        final urls = configs.map((c) => c['url']).toSet();
        expect(urls.length, equals(3));

        // Names should be different
        final names = configs.map((c) => c['name']).toSet();
        expect(names.length, equals(3));
      });
    });

    group('Extension Method Coverage', () {
      test('should implement all required extensions', () {
        for (final env in Environment.values) {
          // Test that all extension methods work
          expect(() => env.name, returnsNormally);
          expect(() => env.firebaseFunctionsUrl, returnsNormally);
          expect(() => env.isDebugMode, returnsNormally);
          expect(() => env.enableAnalytics, returnsNormally);
        }
      });

      test('should have consistent return types', () {
        for (final env in Environment.values) {
          expect(env.name, isA<String>());
          expect(env.firebaseFunctionsUrl, isA<String>());
          expect(env.isDebugMode, isA<bool>());
          expect(env.enableAnalytics, isA<bool>());
        }
      });
    });
  });
}

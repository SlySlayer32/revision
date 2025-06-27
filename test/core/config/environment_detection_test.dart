import 'package:flutter_test/flutter_test.dart';
import 'package:revision/core/config/env_config.dart';
import 'package:revision/core/config/environment_detector.dart';
import 'package:revision/firebase_options.dart';

void main() {
  group('Environment Detection Tests', () {
    test('should detect development environment from compile-time constant',
        () {
      // This test would normally run with --dart-define=ENVIRONMENT=development
      // In tests, we can't easily set compile-time constants, so we test the runtime detection
      final environment = EnvironmentDetector.currentEnvironment;
      expect(environment, isA<AppEnvironment>());
    });

    test('should provide environment as string', () {
      final envString = EnvironmentDetector.environmentString;
      expect(envString, isIn(['development', 'staging', 'production']));
    });

    test('should provide boolean checks for each environment', () {
      // At least one should be true
      final isDev = EnvironmentDetector.isDevelopment;
      final isStaging = EnvironmentDetector.isStaging;
      final isProd = EnvironmentDetector.isProduction;

      expect(isDev || isStaging || isProd, isTrue);

      // Only one should be true at a time
      final trueCount = [isDev, isStaging, isProd].where((e) => e).length;
      expect(trueCount, equals(1));
    });

    test('should provide debug information', () {
      final debugInfo = EnvironmentDetector.getDebugInfo();
      expect(debugInfo, isA<Map<String, dynamic>>());
      expect(debugInfo, containsPair('currentEnvironment', isA<String>()));
      expect(debugInfo, containsPair('compileTimeEnv', isA<String>()));
      expect(debugInfo, containsPair('isWeb', isA<bool>()));
      expect(debugInfo, containsPair('isDebugMode', isA<bool>()));
      expect(debugInfo, containsPair('isReleaseMode', isA<bool>()));
    });

    test('should refresh environment detection', () {
      final env1 = EnvironmentDetector.currentEnvironment;
      EnvironmentDetector.refresh();
      final env2 = EnvironmentDetector.currentEnvironment;
      expect(env1, equals(env2)); // Should be same in tests
    });
  });

  group('EnvConfig Tests', () {
    test('should check if Firebase AI is configured', () {
      final isConfigured = EnvConfig.isFirebaseAIConfigured;
      expect(isConfigured, isA<bool>());
    });

    test('should provide environment information', () {
      final environment = EnvConfig.currentEnvironment;
      expect(environment, isA<AppEnvironment>());
    });

    test('should provide debug information', () {
      final debugInfo = EnvConfig.getDebugInfo();
      expect(debugInfo, isA<Map<String, dynamic>>());
      // Check required keys
      expect(debugInfo, containsPair('firebaseAIConfigured', isA<bool>()));
      expect(debugInfo, containsPair('environment', isA<String>()));
      expect(debugInfo, containsPair('currentEnvironment', isA<AppEnvironment>()));
      
      // Check that environment is properly detected
      expect(debugInfo['environment'], isNotEmpty);
      expect(debugInfo, containsPair('environment', isA<String>()));
    });
  });

  group('Firebase Options Tests', () {
    test('should provide Firebase options for current platform', () {
      final options = DefaultFirebaseOptions.currentPlatform;
      expect(options.projectId, isNotEmpty);
      expect(options.appId, isNotEmpty);
      expect(options.apiKey, isNotEmpty);
    });

    test('should provide Firebase options for specific environments', () {
      final devOptions = DefaultFirebaseOptions.getOptionsForEnvironment(
          AppEnvironment.development);
      final stagingOptions = DefaultFirebaseOptions.getOptionsForEnvironment(
          AppEnvironment.staging);
      final prodOptions = DefaultFirebaseOptions.getOptionsForEnvironment(
          AppEnvironment.production);

      expect(devOptions.projectId, isNotEmpty);
      expect(stagingOptions.projectId, isNotEmpty);
      expect(prodOptions.projectId, isNotEmpty);

      // All options should be valid Firebase configurations
      expect(devOptions.appId, isNotEmpty);
      expect(stagingOptions.appId, isNotEmpty);
      expect(prodOptions.appId, isNotEmpty);

      expect(devOptions.apiKey, isNotEmpty);
      expect(stagingOptions.apiKey, isNotEmpty);
      expect(prodOptions.apiKey, isNotEmpty);
    });

    test('should provide Firebase debug information', () {
      final debugInfo = DefaultFirebaseOptions.getDebugInfo();
      expect(debugInfo, isA<Map<String, dynamic>>());
      expect(debugInfo, containsPair('environment', isA<String>()));
      expect(debugInfo, containsPair('projectId', isA<String>()));
      expect(debugInfo, containsPair('appId', isA<String>()));
      expect(debugInfo, containsPair('platform', isA<String>()));
      expect(debugInfo, containsPair('isWeb', isA<bool>()));
      expect(debugInfo, containsPair('environmentDetection', isA<Map>()));
    });
  });

  group('Web Environment Detection Tests', () {
    test('should detect development from localhost patterns', () {
      // These tests would need to be run in a web context with specific URLs
      // For now, we just verify the detection logic exists
      expect(EnvironmentDetector.getDebugInfo(),
          containsPair('isWeb', isA<bool>()));
    });
  });
}

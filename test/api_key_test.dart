import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:revision/core/config/env_config.dart';

void main() {
  group('API Key Configuration Tests', () {
    setUpAll(() async {
      // Load the .env file for testing
      await dotenv.load(fileName: '.env');
    });

    test('should load GEMINI_API_KEY from .env file', () {
      // Test direct dotenv access
      final directApiKey = dotenv.env['GEMINI_API_KEY'];
      expect(directApiKey, isNotNull);
      expect(directApiKey, isNotEmpty);
      expect(directApiKey, startsWith('AIza'));
      
      print('✅ Direct dotenv access: API key found (${directApiKey?.length} chars)');
    });

    test('should access GEMINI_API_KEY through EnvConfig', () {
      // Test EnvConfig access
      final configApiKey = EnvConfig.geminiApiKey;
      expect(configApiKey, isNotNull);
      expect(configApiKey, isNotEmpty);
      expect(configApiKey, startsWith('AIza'));
      
      print('✅ EnvConfig access: API key found (${configApiKey?.length} chars)');
    });

    test('should report Gemini API as configured', () {
      // Test configuration check
      final isConfigured = EnvConfig.isGeminiRestApiConfigured;
      expect(isConfigured, isTrue);
      
      print('✅ Configuration check: ${isConfigured ? "CONFIGURED" : "NOT CONFIGURED"}');
    });

    test('should provide debug information', () {
      // Test debug info
      final debugInfo = EnvConfig.getDebugInfo();
      expect(debugInfo, isNotNull);
      expect(debugInfo['geminiRestApiConfigured'], isTrue);
      expect(debugInfo['geminiApiKeyPresent'], isTrue);
      expect(debugInfo['geminiApiKeyLength'], greaterThan(0));
      
      print('✅ Debug info: $debugInfo');
    });
  });
}

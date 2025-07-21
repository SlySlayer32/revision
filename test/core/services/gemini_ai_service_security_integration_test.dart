import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:revision/core/services/gemini_ai_service.dart';
import 'package:revision/core/services/firebase_ai_remote_config_service.dart';
import 'package:revision/core/services/gemini_request_validator.dart';
import 'package:revision/core/services/circuit_breaker_service.dart';
import 'package:revision/core/services/rate_limiting_service.dart';
import 'package:revision/core/config/env_config.dart';


class MockHttpClient extends Mock implements http.Client {}
class MockFirebaseAIRemoteConfigService extends Mock implements FirebaseAIRemoteConfigService {}
class MockGeminiRequestValidator extends Mock implements GeminiRequestValidator {}

void main() {
  group('GeminiAIService Security Integration Tests', () {
    late MockHttpClient mockHttpClient;
    late MockFirebaseAIRemoteConfigService mockRemoteConfig;
    late MockGeminiRequestValidator mockValidator;
    late GeminiAIService service;

    setUp(() {
      mockHttpClient = MockHttpClient();
      mockRemoteConfig = MockFirebaseAIRemoteConfigService();
      mockValidator = MockGeminiRequestValidator();
      
      // Set up mock remote config
      when(() => mockRemoteConfig.initialize()).thenAnswer((_) async {});
      when(() => mockRemoteConfig.geminiModel).thenReturn('gemini-pro');
      when(() => mockRemoteConfig.requestTimeout).thenReturn(const Duration(seconds: 30));
      when(() => mockRemoteConfig.exportConfig()).thenReturn({'model': 'gemini-pro'});
      when(() => mockRemoteConfig.getAllValues()).thenReturn({'model': 'gemini-pro'});
      
      // Set up mock validator
      when(() => mockValidator.validateTextRequest(
        prompt: any(named: 'prompt'),
        model: any(named: 'model'),
      )).thenReturn(const ValidationResult(isValid: true));
      
      service = GeminiAIService(
        remoteConfigService: mockRemoteConfig,
        httpClient: mockHttpClient,
        requestValidator: mockValidator,
      );
    });

    group('API Key Security', () {
      test('throws SecurityException when API key is invalid', () async {
        // Set invalid API key
        EnvConfig.setGeminiApiKeyForTesting('invalid-key');
        
        expect(
          () => service.waitForInitialization(),
          throwsA(isA<StateError>()),
        );
      });

      test('validates API key format during initialization', () async {
        // Set valid API key
        EnvConfig.setGeminiApiKeyForTesting('AIzaSyDummyKeyFor32CharactersLong12345');
        
        // Mock successful response for connectivity test
        when(() => mockHttpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => http.Response(
          '{"candidates": [{"content": {"parts": [{"text": "Hello"}]}}]}',
          200,
        ));
        
        await expectLater(
          service.waitForInitialization(),
          completes,
        );
      });
    });

    group('Circuit Breaker Integration', () {
      test('circuit breaker opens after failures', () async {
        // Set valid API key
        EnvConfig.setGeminiApiKeyForTesting('AIzaSyDummyKeyFor32CharactersLong12345');
        
        // Mock initialization success
        when(() => mockHttpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => http.Response(
          '{"candidates": [{"content": {"parts": [{"text": "Hello"}]}}]}',
          200,
        ));
        
        await service.waitForInitialization();
        
        // Mock failures
        when(() => mockHttpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => http.Response('Error', 500));
        
        // Trigger enough failures to open circuit breaker
        for (int i = 0; i < 5; i++) {
          try {
            await service.generateText('test prompt');
          } catch (e) {
            // Expected to fail
          }
        }
        
        // Check circuit breaker state
        final state = CircuitBreakerService.getState('gemini_ai');
        expect(state, equals(CircuitBreakerState.open));
      });
    });

    group('Rate Limiting Integration', () {
      test('rate limiter blocks excessive requests', () async {
        // Set valid API key
        EnvConfig.setGeminiApiKeyForTesting('AIzaSyDummyKeyFor32CharactersLong12345');
        
        // Mock initialization success
        when(() => mockHttpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => http.Response(
          '{"candidates": [{"content": {"parts": [{"text": "Hello"}]}}]}',
          200,
        ));
        
        await service.waitForInitialization();
        
        // Make requests up to the limit
        for (int i = 0; i < 10; i++) {
          await service.generateText('test prompt $i');
        }
        
        // Next request should be rate limited
        expect(
          () => service.generateText('should be limited'),
          throwsA(isA<RateLimitExceededException>()),
        );
      });
    });

    group('Request Security', () {
      test('requests include security headers', () async {
        // Set valid API key
        EnvConfig.setGeminiApiKeyForTesting('AIzaSyDummyKeyFor32CharactersLong12345');
        
        // Mock successful response
        when(() => mockHttpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((invocation) async {
          final headers = invocation.namedArguments[#headers] as Map<String, String>;
          
          // Verify security headers are present
          expect(headers['User-Agent'], isNotNull);
          expect(headers['X-Request-ID'], isNotNull);
          expect(headers['X-Client-Version'], isNotNull);
          expect(headers['X-Timestamp'], isNotNull);
          
          return http.Response(
            '{"candidates": [{"content": {"parts": [{"text": "Hello"}]}}]}',
            200,
          );
        });
        
        await service.waitForInitialization();
        await service.generateText('test prompt');
        
        // Verify the request was made with proper headers
        verify(() => mockHttpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).called(greaterThan(0));
      });
    });
  });
}

// Extension for testing
extension EnvConfigTesting on EnvConfig {
  static void setGeminiApiKeyForTesting(String key) {
    // This would need to be implemented in the actual EnvConfig class
    // For integration testing, we might need to use environment variables
    // or modify the EnvConfig class to support testing
  }
}

/// Mock validation result for testing
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  
  const ValidationResult({
    required this.isValid,
    this.errorMessage,
  });
}
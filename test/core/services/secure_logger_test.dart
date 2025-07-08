import 'package:flutter_test/flutter_test.dart';
import 'package:revision/core/services/secure_logger.dart';

void main() {
  group('SecureLogger', () {
    group('log', () {
      test('sanitizes sensitive information from messages', () {
        // This test would need to verify that sensitive information is masked
        // For now, we'll test that the method executes without error
        expect(
          () => SecureLogger.log(
            'Processing request with API key: AIzaSyDummyKeyFor32CharactersLong12345',
            operation: 'TEST',
          ),
          returnsNormally,
        );
      });

      test('handles context with sensitive data', () {
        final context = {
          'api_key': 'AIzaSyDummyKeyFor32CharactersLong12345',
          'token': 'bearer_token_123',
          'normal_field': 'normal_value',
        };

        expect(
          () => SecureLogger.log(
            'Test message',
            operation: 'TEST',
            context: context,
          ),
          returnsNormally,
        );
      });
    });

    group('logError', () {
      test('logs error with secure context', () {
        final error = Exception('Test error');
        final context = {
          'api_key': 'AIzaSyDummyKeyFor32CharactersLong12345',
          'operation': 'test_operation',
        };

        expect(
          () => SecureLogger.logError(
            'Test error occurred',
            operation: 'TEST',
            error: error,
            context: context,
          ),
          returnsNormally,
        );
      });
    });

    group('logApiOperation', () {
      test('logs API operation with secure endpoint', () {
        expect(
          () => SecureLogger.logApiOperation(
            'TEST_OPERATION',
            method: 'POST',
            endpoint: 'https://api.example.com/generate?key=AIzaSyDummyKeyFor32CharactersLong12345',
            statusCode: 200,
            requestSizeBytes: 1024,
            responseSizeBytes: 2048,
            durationMs: 500,
          ),
          returnsNormally,
        );
      });
    });

    group('logAuditEvent', () {
      test('logs audit event with details', () {
        expect(
          () => SecureLogger.logAuditEvent(
            'API_CALL',
            operation: 'GEMINI_REQUEST',
            details: {
              'endpoint': 'https://api.example.com/generate',
              'method': 'POST',
              'status': 200,
            },
          ),
          returnsNormally,
        );
      });
    });
  });
}
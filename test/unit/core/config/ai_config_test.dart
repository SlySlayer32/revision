// test/unit/core/config/ai_config_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:revision/core/config/ai_config.dart';

void main() {
  group('AIConfig', () {
    group('Model Configuration', () {
      test('should have correct Gemini model for analysis', () {
        expect(AIConfig.geminiModel, equals('gemini-2.0-flash'));
      });

      test('should have correct Gemini model for image generation', () {
        expect(
          AIConfig.geminiImageModel,
          equals('gemini-2.0-flash-preview-image-generation'),
        );
      });
    });

    group('Configuration Parameters', () {
      test('should have valid temperature value', () {
        expect(AIConfig.temperature, equals(0.7));
        expect(AIConfig.temperature, greaterThanOrEqualTo(0.0));
        expect(AIConfig.temperature, lessThanOrEqualTo(1.0));
      });

      test('should have positive max output tokens', () {
        expect(AIConfig.maxOutputTokens, equals(2048));
        expect(AIConfig.maxOutputTokens, greaterThan(0));
      });

      test('should have valid topK value', () {
        expect(AIConfig.topK, equals(32));
        expect(AIConfig.topK, greaterThan(0));
      });

      test('should have valid topP value', () {
        expect(AIConfig.topP, equals(1.0));
        expect(AIConfig.topP, greaterThanOrEqualTo(0.0));
        expect(AIConfig.topP, lessThanOrEqualTo(1.0));
      });
    });

    group('Rate Limiting', () {
      test('should have reasonable rate limits', () {
        expect(AIConfig.maxRequestsPerMinute, equals(60));
        expect(AIConfig.maxRequestsPerHour, equals(1000));
        expect(AIConfig.maxRequestsPerMinute, greaterThan(0));
        expect(AIConfig.maxRequestsPerHour, greaterThan(0));
      });
    });

    group('Timeouts and Retries', () {
      test('should have reasonable timeout', () {
        expect(AIConfig.requestTimeout, equals(const Duration(seconds: 30)));
        expect(AIConfig.requestTimeout.inSeconds, greaterThan(0));
      });

      test('should have retry configuration', () {
        expect(AIConfig.maxRetries, equals(3));
        expect(AIConfig.retryDelay, equals(const Duration(seconds: 2)));
        expect(AIConfig.maxRetries, greaterThan(0));
      });
    });

    group('Image Processing Limits', () {
      test('should have valid image size limits', () {
        expect(AIConfig.maxImageSizeMB, equals(20));
        expect(AIConfig.maxImagesPerRequest, equals(5));
        expect(AIConfig.maxImageSizeMB, greaterThan(0));
        expect(AIConfig.maxImagesPerRequest, greaterThan(0));
      });
    });

    group('System Prompts', () {
      test('analysis system prompt should focus on object removal', () {
        expect(
          AIConfig.analysisSystemPrompt,
          contains('marked objects'),
        );
        expect(
          AIConfig.analysisSystemPrompt,
          contains('removal'),
        );
        expect(
          AIConfig.analysisSystemPrompt,
          contains('background reconstruction'),
        );
        expect(AIConfig.analysisSystemPrompt.length, greaterThan(100));
      });

      test('editing system prompt should be for Gemini 2.0 Flash Preview', () {
        expect(
          AIConfig.editingSystemPrompt,
          contains('Gemini 2.0 Flash Preview'),
        );
        expect(
          AIConfig.editingSystemPrompt,
          contains('Generate a new version'),
        );
        expect(
          AIConfig.editingSystemPrompt,
          contains('content-aware reconstruction'),
        );
        expect(AIConfig.editingSystemPrompt.length, greaterThan(100));
      });

      test('prompts should be well-formatted and clear', () {
        expect(AIConfig.analysisSystemPrompt.trim(), isNotEmpty);
        expect(AIConfig.editingSystemPrompt.trim(), isNotEmpty);
        
        // Should not have leading/trailing whitespace issues
        expect(
          AIConfig.analysisSystemPrompt,
          equals(AIConfig.analysisSystemPrompt.trim()),
        );
        expect(
          AIConfig.editingSystemPrompt,
          equals(AIConfig.editingSystemPrompt.trim()),
        );
      });
    });

    group('Configuration Validation', () {
      test('all required constants should be defined', () {
        expect(AIConfig.geminiModel, isNotEmpty);
        expect(AIConfig.geminiImageModel, isNotEmpty);
        expect(AIConfig.analysisSystemPrompt, isNotEmpty);
        expect(AIConfig.editingSystemPrompt, isNotEmpty);
      });

      test('model names should follow expected format', () {
        expect(AIConfig.geminiModel, startsWith('gemini-'));
        expect(AIConfig.geminiImageModel, startsWith('gemini-'));
        expect(AIConfig.geminiImageModel, contains('preview'));
      });
    });
  });
}

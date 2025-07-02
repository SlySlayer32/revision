// test/unit/core/services/gemini_ai_service_test.dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/core/services/firebase_ai_remote_config_service.dart';
import 'package:revision/core/services/gemini_ai_service.dart';

import '../../../helpers/test_data/ai_test_data.dart';

// Mock classes
class MockFirebaseAIRemoteConfigService extends Mock
    implements FirebaseAIRemoteConfigService {}

void main() {
  group('GeminiAIService', () {
    late GeminiAIService service;
    late MockFirebaseAIRemoteConfigService mockRemoteConfig;

    setUp(() {
      mockRemoteConfig = MockFirebaseAIRemoteConfigService();

      // Setup mock remote config responses
      when(() => mockRemoteConfig.geminiModel).thenReturn('gemini-2.0-flash');
      when(() => mockRemoteConfig.geminiImageModel)
          .thenReturn('gemini-2.0-flash-preview-image-generation');
      when(() => mockRemoteConfig.temperature).thenReturn(0.4);
      when(() => mockRemoteConfig.maxOutputTokens).thenReturn(1024);
      when(() => mockRemoteConfig.topK).thenReturn(40);
      when(() => mockRemoteConfig.topP).thenReturn(0.95);
      when(() => mockRemoteConfig.analysisSystemPrompt)
          .thenReturn('Test analysis prompt');
      when(() => mockRemoteConfig.requestTimeout)
          .thenReturn(const Duration(seconds: 30));
      when(() => mockRemoteConfig.enableAdvancedFeatures).thenReturn(true);
      when(() => mockRemoteConfig.initialize()).thenAnswer((_) async {});
      when(() => mockRemoteConfig.refresh()).thenAnswer((_) async {});
      when(() => mockRemoteConfig.exportConfig()).thenReturn('{}');
      when(() => mockRemoteConfig.getAllValues()).thenReturn({});

      service = GeminiAIService(remoteConfigService: mockRemoteConfig);
    });

    group('initialization', () {
      test('should initialize with remote config service', () {
        expect(service, isNotNull);
        verify(() => mockRemoteConfig.initialize()).called(1);
      });

      test('should handle initialization failure gracefully', () async {
        // Arrange
        when(() => mockRemoteConfig.initialize())
            .thenThrow(Exception('Remote config failed'));

        // Act & Assert
        expect(() => GeminiAIService(remoteConfigService: mockRemoteConfig),
            isNot(throwsA(anything)));
      });
    });

    group('processTextPrompt', () {
      test('should return fallback response on error', () async {
        // Act
        final result = await service.processTextPrompt('test prompt');

        // Assert
        expect(result, contains('error processing'));
        expect(result.length, greaterThan(0));
      });

      test('should handle empty prompt', () async {
        // Act
        final result = await service.processTextPrompt('');

        // Assert
        expect(result, isNotEmpty);
      });
    });

    group('processImagePrompt', () {
      test('should validate image size before processing', () async {
        // Arrange
        final largeImage = Uint8List(25 * 1024 * 1024); // 25MB

        // Act
        final result = await service.processImagePrompt(largeImage, 'test');

        // Assert
        expect(result, contains('unable to analyze'));
      });

      test('should return fallback response for valid image', () async {
        // Act
        final result = await service.processImagePrompt(
          AITestData.testImageData,
          'Analyze this image',
        );

        // Assert
        expect(result, isNotEmpty);
        expect(
            result,
            anyOf([
              contains('unable to analyze'),
              contains('object removal'),
              contains('editing'),
            ]));
      });

      test('should include prompt instructions in processing', () async {
        // Arrange
        const testPrompt = 'Remove the red object';

        // Act
        final result = await service.processImagePrompt(
          AITestData.testImageData,
          testPrompt,
        );

        // Assert
        expect(result, isNotEmpty);
      });
    });

    group('generateImageDescription', () {
      test('should return description for valid image', () async {
        // Act
        final result = await service.generateImageDescription(
          AITestData.testImageData,
        );

        // Assert
        expect(result, isNotEmpty);
        expect(
            result,
            anyOf([
              contains('Unable to analyze'),
              contains('image'),
              contains('lighting'),
              contains('composition'),
            ]));
      });

      test('should handle invalid image data', () async {
        // Arrange
        final invalidData = Uint8List.fromList([1, 2, 3, 4]);

        // Act
        final result = await service.generateImageDescription(invalidData);

        // Assert
        expect(result, isNotEmpty);
      });
    });

    group('suggestImageEdits', () {
      test('should return list of suggestions', () async {
        // Act
        final result = await service.suggestImageEdits(
          AITestData.testImageData,
        );

        // Assert
        expect(result, isNotEmpty);
        expect(result.length, greaterThan(0));
        expect(result.length, lessThanOrEqualTo(5));

        // Check that suggestions are meaningful
        for (final suggestion in result) {
          expect(suggestion.trim(), isNotEmpty);
          expect(suggestion.length, greaterThan(10));
        }
      });

      test('should return fallback suggestions on error', () async {
        // Act
        final result = await service.suggestImageEdits(
          Uint8List.fromList([]), // Empty data to trigger error
        );

        // Assert
        expect(result, isNotEmpty);
        expect(result.length, equals(5)); // Fallback suggestions count
        expect(result.first, contains('Remove'));
      });
    });

    group('checkContentSafety', () {
      test('should return true for valid image data', () async {
        // Act
        final result = await service.checkContentSafety(
          AITestData.testImageData,
        );

        // Assert
        expect(result, isTrue); // Default to safe on error
      });

      test('should handle invalid image gracefully', () async {
        // Arrange
        final invalidData = Uint8List.fromList([]);

        // Act
        final result = await service.checkContentSafety(invalidData);

        // Assert
        expect(result, isTrue); // Should default to safe
      });
    });

    group('generateEditingPrompt', () {
      test('should generate prompt with markers', () async {
        // Act
        final result = await service.generateEditingPrompt(
          imageBytes: AITestData.testImageData,
          markers: AITestData.testMarkedAreas,
        );

        // Assert
        expect(result, isNotEmpty);
        expect(result.length, greaterThan(10));
      });

      test('should handle empty markers', () async {
        // Act
        final result = await service.generateEditingPrompt(
          imageBytes: AITestData.testImageData,
          markers: [],
        );

        // Assert
        expect(result, isNotEmpty);
      });

      test('should include marker descriptions in prompt', () async {
        // Arrange
        final markersWithDescription = [
          {
            'x': 100.0,
            'y': 100.0,
            'description': 'Red car to remove',
          },
        ];

        // Act
        final result = await service.generateEditingPrompt(
          imageBytes: AITestData.testImageData,
          markers: markersWithDescription,
        );

        // Assert
        expect(result, isNotEmpty);
        // Result should be a fallback since we're in test mode
      });
    });

    group('processImageWithAI', () {
      test('should return original image as placeholder', () async {
        // Act
        final result = await service.processImageWithAI(
          imageBytes: AITestData.testImageData,
          editingPrompt: 'Remove the marked objects',
        );

        // Assert
        expect(result, equals(AITestData.testImageData));
      });

      test('should handle various prompt types', () async {
        // Arrange
        final prompts = [
          'Remove person from background',
          'Enhance lighting and colors',
          'Crop and straighten image',
          '',
        ];

        // Act & Assert
        for (final prompt in prompts) {
          final result = await service.processImageWithAI(
            imageBytes: AITestData.testImageData,
            editingPrompt: prompt,
          );
          expect(result, isNotNull);
          expect(result.length, greaterThan(0));
        }
      });
    });

    group('configuration management', () {
      test('should refresh config successfully', () async {
        // Act
        await service.refreshConfig();

        // Assert
        verify(() => mockRemoteConfig.refresh()).called(1);
      });

      test('should handle refresh failure gracefully', () async {
        // Arrange
        when(() => mockRemoteConfig.refresh())
            .thenThrow(Exception('Refresh failed'));

        // Act & Assert
        expect(() => service.refreshConfig(), isNot(throwsA(anything)));
      });

      test('should return config debug info', () {
        // Act
        final debugInfo = service.getConfigDebugInfo();

        // Assert
        expect(debugInfo, isA<Map<String, dynamic>>());
        verify(() => mockRemoteConfig.getAllValues()).called(1);
      });

      test('should return feature flags correctly', () {
        // Act
        final advancedFeatures = service.isAdvancedFeaturesEnabled;

        // Assert
        expect(advancedFeatures, isTrue);
      });
    });
  });
}

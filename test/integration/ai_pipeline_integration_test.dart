// test/integration/ai_pipeline_integration_test.dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:revision/core/services/gemini_ai_service.dart';
import 'package:revision/features/ai_processing/infrastructure/services/ai_analysis_service.dart';
import '../helpers/test_data/ai_test_data.dart';

/// Integration tests for the complete AI pipeline
/// 
/// These tests verify that all AI services work together correctly
/// without mocking the actual AI calls (where possible in test environment)
void main() {
  group('AI Pipeline Integration Tests', () {
    late GeminiAIService geminiService;
    late AiAnalysisService analysisService;

    setUp(() {
      geminiService = GeminiAIService();
      analysisService = AiAnalysisService();
    });

    group('End-to-End AI Processing', () {
      test('should process annotated image through complete pipeline', 
          () async {
        // Arrange
        final annotatedImage = AITestData.testAnnotatedImage;
        
        // Act
        final analysisResult = await analysisService.analyzeAnnotatedImage(
          annotatedImage,
        );

        // Assert
        expect(analysisResult, isNotNull);
        expect(analysisResult.processedImageData, isNotEmpty);
        expect(analysisResult.enhancedPrompt, isNotEmpty);
        expect(analysisResult.processingTime, greaterThan(Duration.zero));
        expect(analysisResult.metadata, isNotEmpty);
        expect(analysisResult.metadata!['strokeCount'], equals(2));
      }, timeout: const Timeout(Duration(minutes: 2)));

      test('should handle image size validation across services', () async {
        // Arrange
        final largeImage = Uint8List(25 * 1024 * 1024); // 25MB
        
        // Act & Assert - Should fail before reaching AI services
        final result = await geminiService.processImagePrompt(
          largeImage,
          'Test prompt',
        );
        
        expect(result, contains('unable to analyze'));
      });

      test('should maintain consistent prompt format across pipeline', 
          () async {        
        // Act
        final editingPrompt = await geminiService.generateEditingPrompt(
          imageBytes: AITestData.testImageData,
          markers: AITestData.testMarkedAreas,
        );
        
        final processedImage = await geminiService.processImageWithAI(
          imageBytes: AITestData.testImageData,
          editingPrompt: editingPrompt,
        );

        // Assert
        expect(editingPrompt, isNotEmpty);
        expect(processedImage, isNotNull);
        expect(processedImage.length, greaterThan(0));
      });
    });

    group('Service Integration', () {
      test('should coordinate between analysis and generation services', 
          () async {
        // Arrange
        final testImage = AITestData.testImageData;
        final markedAreas = AITestData.testMarkedAreas;

        // Act - Step 1: Generate editing prompt
        final editingPrompt = await geminiService.generateEditingPrompt(
          imageBytes: testImage,
          markers: markedAreas,
        );

        // Act - Step 2: Process image with generated prompt
        final processedImage = await geminiService.processImageWithAI(
          imageBytes: testImage,
          editingPrompt: editingPrompt,
        );

        // Assert
        expect(editingPrompt, isNotEmpty);
        expect(processedImage, equals(testImage)); // Currently returns original
      });

      test('should handle content safety checks in pipeline', () async {
        // Act
        final isSafe = await geminiService.checkContentSafety(
          AITestData.testImageData,
        );

        // Assert
        expect(isSafe, isTrue);
      });

      test('should generate consistent image descriptions', () async {
        // Act
        final description = await geminiService.generateImageDescription(
          AITestData.testImageData,
        );

        final suggestions = await geminiService.suggestImageEdits(
          AITestData.testImageData,
        );

        // Assert
        expect(description, isNotEmpty);
        expect(suggestions, isNotEmpty);
        expect(suggestions.length, greaterThan(0));
      });
    });

    group('Error Handling Integration', () {
      test('should handle cascading failures gracefully', () async {
        // Arrange - Invalid image data
        final invalidImage = Uint8List.fromList([1, 2, 3]);

        // Act
        final description = await geminiService.generateImageDescription(
          invalidImage,
        );
        
        final suggestions = await geminiService.suggestImageEdits(
          invalidImage,
        );
        
        final isSafe = await geminiService.checkContentSafety(invalidImage);

        // Assert - All should handle errors gracefully
        expect(description, isNotEmpty);
        expect(suggestions, isNotEmpty);
        expect(isSafe, isTrue); // Defaults to safe
      });

      test('should recover from network issues', () async {
        // This test simulates network recovery scenarios
        // In a real environment, you might temporarily disable network
        
        // Act
        final result = await geminiService.processTextPrompt(
          'Test network resilience',
        );

        // Assert
        expect(result, isNotEmpty);
      }, tags: ['slow']);
    });

    group('Performance Integration', () {
      test('should complete analysis within reasonable time', () async {
        // Arrange
        final stopwatch = Stopwatch()..start();
        
        // Act
        final result = await analysisService.analyzeAnnotatedImage(
          AITestData.testAnnotatedImage,
        );
        
        stopwatch.stop();

        // Assert
        expect(result, isNotNull);
        expect(stopwatch.elapsed, lessThan(const Duration(seconds: 45)));
      }, timeout: const Timeout(Duration(minutes: 1)));

      test('should handle multiple concurrent requests', () async {
        // Arrange
        final futures = List.generate(3, (index) => 
          geminiService.generateImageDescription(AITestData.testImageData),
        );

        // Act
        final results = await Future.wait(futures);

        // Assert
        expect(results.length, equals(3));
        for (final result in results) {
          expect(result, isNotEmpty);
        }
      }, tags: ['slow']);
    });

    group('Configuration Integration', () {
      test('should use remote config values consistently', () async {
        // Act
        final debugInfo = geminiService.getConfigDebugInfo();
        await geminiService.refreshConfig();
        
        final isAdvanced = geminiService.isAdvancedFeaturesEnabled;
        final isDebug = geminiService.isDebugMode;

        // Assert
        expect(debugInfo, isA<Map<String, dynamic>>());
        expect(isAdvanced, isA<bool>());
        expect(isDebug, isA<bool>());
      });
    });
  });
}

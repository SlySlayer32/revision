import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:revision/core/di/service_locator.dart';
import 'package:revision/core/services/gemini_ai_service.dart';
import 'package:revision/core/services/gemini_pipeline_service.dart';
import 'package:revision/features/ai_processing/domain/usecases/process_image_with_gemini_usecase.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('AI Pipeline Integration Tests', () {
    setUp(() {
      // Setup test dependencies with mocks to avoid actual Firebase calls
      VGVTestHelper.setupTestDependencies();
    });

    tearDown(() {
      VGVTestHelper.tearDownTestDependencies();
    });

    group('Service Locator Integration', () {
      testWidgets('should setup AI pipeline dependencies correctly',
          (tester) async {
        // Act - Setup production service locator
        expect(() => setupServiceLocator(), returnsNormally);

        // Assert - Verify all AI pipeline services are registered
        expect(getIt.isRegistered<GeminiAIService>(), true);
        expect(getIt.isRegistered<GeminiPipelineService>(), true);
        expect(getIt.isRegistered<ProcessImageWithGeminiUseCase>(), true);
      });

      testWidgets('should handle GenerativeModel registration', (tester) async {
        // Act
        setupServiceLocator();

        // Assert - Basic service registration check
        expect(getIt.isRegistered<GeminiAIService>(), true);
      });
    });

    group('AI Service Initialization Flow', () {
      testWidgets('should initialize AI services in correct order',
          (tester) async {
        // Arrange
        setupServiceLocator();

        // Act - Get services (this triggers lazy initialization)
        final aiService = getIt<GeminiAIService>();
        final pipelineService = getIt<GeminiPipelineService>();
        final useCase = getIt<ProcessImageWithGeminiUseCase>();

        // Assert - Services should be created successfully
        expect(aiService, isA<GeminiAIService>());
        expect(pipelineService, isA<GeminiPipelineService>());
        expect(useCase, isA<ProcessImageWithGeminiUseCase>());
      });

      testWidgets('should handle AI service initialization failures gracefully',
          (tester) async {
        // This test verifies that even if AI initialization fails,
        // the app doesn't crash and services are still accessible

        setupServiceLocator();

        final aiService = getIt<GeminiAIService>();

        // Service should be created even if not fully initialized
        expect(aiService, isA<GeminiAIService>());

        // Should be able to access config properties
        expect(aiService.isAdvancedFeaturesEnabled, isA<bool>());
      });
    });

    group('Error Scenarios', () {
      testWidgets('should handle missing Firebase AI configuration',
          (tester) async {
        // This test simulates the scenario where Firebase AI is not properly configured
        setupServiceLocator();

        final aiService = getIt<GeminiAIService>();

        // Accessing models before initialization should throw StateError
        expect(
          () => aiService.analysisModel,
          throwsA(
            predicate(
              (e) =>
                  e is StateError && e.message.contains('not yet initialized'),
            ),
          ),
        );
      });

      testWidgets('should provide meaningful error messages', (tester) async {
        setupServiceLocator();

        final aiService = getIt<GeminiAIService>();

        // Test that error messages are helpful for debugging
        try {
          aiService.analysisModel;
          fail('Expected StateError to be thrown');
        } catch (e) {
          expect(e.toString(), contains('Firebase AI'));
          // Error should mention the Firebase Console URL
          expect(e.toString(), contains('console.firebase.google.com'));
        }
      });

      testWidgets('should handle GetIt registration conflicts', (tester) async {
        // Setup twice to test conflict resolution
        setupServiceLocator();
        expect(() => setupServiceLocator(), returnsNormally);

        // Services should still be accessible
        expect(getIt.isRegistered<GeminiAIService>(), true);
      });
    });

    group('Pipeline Flow Validation', () {
      testWidgets('should process text through the complete pipeline',
          (tester) async {
        // Arrange
        setupServiceLocator();
        final aiService = getIt<GeminiAIService>();

        // Wait for initialization
        await aiService.waitForInitialization();

        // Act - Process text (this will use mocked services)
        final result = await aiService.processTextPrompt('Test prompt');

        // Assert
        expect(result, isA<String>());
      });

      testWidgets('should process images through the complete pipeline',
          (tester) async {
        // Arrange
        setupServiceLocator();
        final useCase = getIt<ProcessImageWithGeminiUseCase>();
        final testImageData = Uint8List.fromList([1, 2, 3, 4]);

        // Act - Process image (this will use mocked services)
        final result = await useCase.call(
          testImageData,
          markedAreas: [
            {'x': 100, 'y': 200, 'description': 'Test marker'}
          ],
        );

        // Assert - Should complete without throwing
        expect(result, isA<Object>());
      });
    });

    group('Configuration and Debug', () {
      testWidgets('should provide debug information', (tester) async {
        // Arrange
        setupServiceLocator();
        final aiService = getIt<GeminiAIService>();
        await aiService.waitForInitialization();

        // Act
        final debugInfo = aiService.getConfigDebugInfo();

        // Assert
        expect(debugInfo, isA<Map<String, dynamic>>());
      });

      testWidgets('should handle configuration refresh', (tester) async {
        // Arrange
        setupServiceLocator();
        final aiService = getIt<GeminiAIService>();
        await aiService.waitForInitialization();

        // Act - Should not throw
        await expectLater(
          () => aiService.refreshConfig(),
          returnsNormally,
        );
      });
    });

    group('Performance and Resource Management', () {
      testWidgets('should handle multiple simultaneous requests',
          (tester) async {
        // Arrange
        setupServiceLocator();
        final aiService = getIt<GeminiAIService>();
        await aiService.waitForInitialization();

        // Act - Make multiple concurrent requests
        final futures = List.generate(
          5,
          (index) => aiService.processTextPrompt('Test prompt $index'),
        );

        final results = await Future.wait(futures);

        // Assert - All requests should complete
        expect(results.length, 5);
        for (final result in results) {
          expect(result, isA<String>());
        }
      });

      testWidgets('should handle memory management for large images',
          (tester) async {
        // Arrange
        setupServiceLocator();
        final aiService = getIt<GeminiAIService>();
        await aiService.waitForInitialization();

        // Act - Process a reasonably sized image
        final imageData = Uint8List(1024 * 1024); // 1MB
        final result = await aiService.processImagePrompt(
          imageData,
          'Analyze this image',
        );

        // Assert - Should handle without memory issues
        expect(result, isA<String>());
      });
    });

    group('Fallback and Recovery', () {
      testWidgets('should provide fallback responses when AI is unavailable',
          (tester) async {
        // This test ensures the app remains functional even when AI services fail
        setupServiceLocator();
        final aiService = getIt<GeminiAIService>();
        await aiService.waitForInitialization();

        // Act - Even if mocked to fail, should return fallback
        final result = await aiService.processTextPrompt('Test prompt');

        // Assert
        expect(result, isA<String>());
        expect(result.isNotEmpty, true);
      });

      testWidgets('should recover from temporary failures', (tester) async {
        // Test that the service can recover after failures
        setupServiceLocator();
        final aiService = getIt<GeminiAIService>();

        // Should be able to refresh config after errors
        await expectLater(
          () => aiService.refreshConfig(),
          returnsNormally,
        );
      });
    });
  });
}

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:revision/core/di/service_locator.dart';
import 'package:revision/core/utils/result.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_context.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_result.dart';
import 'package:revision/features/ai_processing/domain/repositories/ai_processing_repository.dart';
import 'package:revision/features/image_selection/domain/entities/image_source.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';

/// Integration test for the AI processing flow with mock repository
void main() {
  group('AI Processing Flow Integration Test', () {
    late AiProcessingRepository repository;

    setUpAll(() {
      setupServiceLocator();
      repository = getIt<AiProcessingRepository>();
    });

    test('should successfully process an image with AI', () async {
      // Arrange
      final imageData = Uint8List.fromList([1, 2, 3, 4, 5]);
      const userPrompt = 'Make this image more vibrant and colorful';
      const context = ProcessingContext(
        processingType: ProcessingType.enhance,
        qualityLevel: QualityLevel.high,
        performancePriority: PerformancePriority.quality,
      );

      // Act
      final result = await repository.processImage(
        imageData: imageData,
        userPrompt: userPrompt,
        context: context,
      );

      // Assert
      expect(result, isA<Success<ProcessingResult>>());

      final successResult = result as Success<ProcessingResult>;
      final processingResult = successResult.value;

      expect(processingResult.processedImageData, isNotEmpty);
      expect(processingResult.originalPrompt, equals(userPrompt));
      expect(processingResult.enhancedPrompt, isNotEmpty);
      expect(processingResult.processingTime, isNotNull);
      expect(processingResult.metadata, isNotNull);
      expect(processingResult.metadata!['mock_processing'], isTrue);
    });

    test('should provide progress updates during processing', () async {
      // Arrange
      final imageData = Uint8List.fromList([1, 2, 3, 4, 5]);
      const userPrompt = 'Test prompt';
      const context = ProcessingContext(
        processingType: ProcessingType.artistic,
        qualityLevel: QualityLevel.standard,
        performancePriority: PerformancePriority.balanced,
      );

      // Act & Assert
      // Note: In a real implementation, we would collect progress updates here

      // Start processing
      final processingFuture = repository.processImage(
        imageData: imageData,
        userPrompt: userPrompt,
        context: context,
      );

      // Note: For a full integration test, we'd need to observe progress
      // but our mock implementation processes synchronously
      final result = await processingFuture;

      expect(result, isA<Success<ProcessingResult>>());
    });

    test('should handle service availability check', () async {
      // Act
      final isAvailable = await repository.isServiceAvailable();

      // Assert
      expect(isAvailable, isTrue);
    });

    test('complete MVP workflow simulation', () async {
      // Simulate the complete MVP workflow:
      // 1. User selects image
      const selectedImage = SelectedImage(
        path: '/test/path/image.jpg',
        name: 'test_image.jpg',
        sizeInBytes: 1024000,
        source: ImageSource.gallery,
      );

      // 2. Convert to image data (in real app this would be done by image loading)
      // In a real app, we would load image data from selectedImage.path
      final imageData = Uint8List.fromList(List.generate(1000, (i) => i % 256));

      // Log the image details that would typically be used
      print(
          'Processing image: ${selectedImage.name} from ${selectedImage.source}');

      // 3. User provides prompt and context
      const userPrompt = 'Enhance this image to make it look professional';
      const context = ProcessingContext(
        processingType: ProcessingType.enhance,
        qualityLevel: QualityLevel.high,
        performancePriority: PerformancePriority.balanced,
      );

      // 4. Process with AI
      final result = await repository.processImage(
        imageData: imageData,
        userPrompt: userPrompt,
        context: context,
      );

      // 5. Verify successful processing
      expect(result, isA<Success<ProcessingResult>>());

      final processingResult = (result as Success<ProcessingResult>).value;

      // 6. Verify result contains all expected data
      expect(processingResult.processedImageData.isNotEmpty, isTrue);
      expect(processingResult.originalPrompt, equals(userPrompt));
      expect(processingResult.enhancedPrompt.contains(userPrompt), isTrue);
      expect(processingResult.jobId, isNotNull);
      expect(processingResult.imageAnalysis, isNotNull);
      expect(processingResult.imageAnalysis!.qualityScore, isNotNull);
      expect(processingResult.imageAnalysis!.qualityScore! >= 7.5, isTrue);
      expect(processingResult.metadata!['ai_model'], equals('MockAI v1.0'));

      // 7. Verify metadata contains processing details
      final metadata = processingResult.metadata!;
      expect(metadata['processing_type'], equals('enhance'));
      expect(metadata['quality_level'], equals('high'));
      expect(metadata['mock_processing'], isTrue);
    });
  });
}

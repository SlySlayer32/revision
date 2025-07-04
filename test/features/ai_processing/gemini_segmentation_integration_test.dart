import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/core/services/gemini_ai_service.dart';
import 'package:revision/features/ai_processing/domain/entities/image_marker.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_context.dart';
import 'package:revision/features/ai_processing/domain/entities/segmentation_mask.dart';
import 'package:revision/features/ai_processing/domain/entities/segmentation_result.dart';
import 'package:revision/features/ai_processing/domain/usecases/generate_segmentation_masks_usecase.dart';

class MockGeminiAIService extends Mock implements GeminiAIService {}

void main() {
  group('Gemini 2.5 Segmentation Integration Tests', () {
    late MockGeminiAIService mockGeminiService;
    late GenerateSegmentationMasksUseCase segmentationUseCase;
    late Uint8List testImageBytes;

    setUp(() {
      mockGeminiService = MockGeminiAIService();
      segmentationUseCase = GenerateSegmentationMasksUseCase(mockGeminiService);
      
      // Create test image data
      testImageBytes = Uint8List.fromList(List.generate(1024, (i) => i % 256));
    });

    test('should generate segmentation masks for wooden and glass items', () async {
      // Arrange - Mock the Gemini 2.5 segmentation response
      final expectedResult = SegmentationResult(
        masks: [
          SegmentationMask(
            boundingBox: const BoundingBox2D(
              y0: 100, x0: 150, y1: 400, x1: 500,
            ),
            label: 'wooden chair',
            maskData: Uint8List.fromList([1, 2, 3, 4]), // Mock PNG data
            confidence: 0.92,
          ),
          SegmentationMask(
            boundingBox: const BoundingBox2D(
              y0: 200, x0: 600, y1: 350, x1: 800,
            ),
            label: 'glass vase',
            maskData: Uint8List.fromList([5, 6, 7, 8]), // Mock PNG data
            confidence: 0.87,
          ),
        ],
        processingTimeMs: 1200,
        imageWidth: 1024,
        imageHeight: 768,
        confidence: 0.895,
      );

      when(() => mockGeminiService.generateSegmentationMasks(
        imageBytes: any(named: 'imageBytes'),
        targetObjects: 'wooden and glass items',
        confidenceThreshold: any(named: 'confidenceThreshold'),
      )).thenAnswer((_) async => expectedResult);

      // Act
      final result = await segmentationUseCase(
        testImageBytes,
        targetObjects: 'wooden and glass items',
        confidenceThreshold: 0.7,
      );

      // Assert
      expect(result.isSuccess, true);
      result.when(
        success: (segmentationResult) {
          expect(segmentationResult.masks.length, 2);
          expect(segmentationResult.masks[0].label, 'wooden chair');
          expect(segmentationResult.masks[1].label, 'glass vase');
          expect(segmentationResult.confidence, greaterThan(0.8));
          expect(segmentationResult.stats.uniqueLabels.length, 2);
        },
        failure: (error) => fail('Expected success but got failure: $error'),
      );

      // Verify the service was called with correct parameters
      verify(() => mockGeminiService.generateSegmentationMasks(
        imageBytes: testImageBytes,
        targetObjects: 'wooden and glass items',
        confidenceThreshold: 0.7,
      )).called(1);
    });

    test('should create AI segmentation markers from segmentation result', () {
      // Arrange
      final segmentationMask = SegmentationMask(
        boundingBox: const BoundingBox2D(
          y0: 100, x0: 150, y1: 400, x1: 500,
        ),
        label: 'wooden table',
        maskData: Uint8List.fromList([1, 2, 3, 4]),
        confidence: 0.91,
      );

      // Act
      final marker = ImageMarker.fromSegmentation(
        id: 'seg_001',
        segmentationMask: segmentationMask,
      );

      // Assert
      expect(marker.id, 'seg_001');
      expect(marker.label, 'wooden table');
      expect(marker.markerType, MarkerType.aiSegmentation);
      expect(marker.confidence, 0.91);
      expect(marker.segmentationMask, isNotNull);
      expect(marker.boundingBox, isNotNull);
    });

    test('should create processing context for segmentation', () {
      // Act
      final context = ProcessingContext.segmentation(
        targetObjects: 'furniture and decorative items',
        confidenceThreshold: 0.8,
      );

      // Assert
      expect(context.processingType, ProcessingType.segmentation);
      expect(context.qualityLevel, QualityLevel.high);
      expect(context.performancePriority, PerformancePriority.quality);
      expect(context.customInstructions, contains('furniture and decorative items'));
      expect(context.customInstructions, contains('0.8'));
      expect(context.isValid, true);
      expect(context.requiresMarkers, false); // AI generates its own markers
    });

    test('should create processing context for object detection', () {
      // Act
      final context = ProcessingContext.objectDetection(
        targetObjects: 'cars and bicycles',
      );

      // Assert
      expect(context.processingType, ProcessingType.objectDetection);
      expect(context.qualityLevel, QualityLevel.standard);
      expect(context.performancePriority, PerformancePriority.speed);
      expect(context.customInstructions, contains('cars and bicycles'));
      expect(context.isValid, true);
      expect(context.requiresMarkers, false);
    });

    test('should handle point containment for different marker types', () {
      // Arrange - User-defined marker
      final userMarker = ImageMarker.userPoint(
        id: 'user_001',
        label: 'click point',
        x: 100,
        y: 200,
      );

      // AI detection marker
      final detectionMarker = ImageMarker.fromObjectDetection(
        id: 'det_001',
        label: 'detected car',
        boundingBox: const BoundingBox2D(
          y0: 180, x0: 80, y1: 220, x1: 120,
        ),
        confidence: 0.85,
      );

      // Act & Assert - User marker (point-based containment)
      expect(userMarker.containsPoint(105, 205, 1024, 768), true);
      expect(userMarker.containsPoint(200, 300, 1024, 768), false);

      // AI detection marker (bounding box containment)
      expect(detectionMarker.containsPoint(100, 200, 1024, 768), true);
      expect(detectionMarker.containsPoint(50, 150, 1024, 768), false);
    });

    test('should convert segmentation mask to absolute coordinates', () {
      // Arrange - Normalized coordinates (0-1000 scale)
      final mask = SegmentationMask(
        boundingBox: const BoundingBox2D(
          y0: 100, // 10% from top
          x0: 200, // 20% from left
          y1: 500, // 50% from top
          x1: 800, // 80% from left
        ),
        label: 'test object',
        maskData: Uint8List.fromList([1, 2, 3, 4]),
        confidence: 0.9,
      );

      // Act - Convert to absolute coordinates for 1024x768 image
      final absoluteBox = mask.toAbsoluteCoordinates(1024, 768);

      // Assert
      expect(absoluteBox.y0, closeTo(76.8, 0.1)); // 100/1000 * 768
      expect(absoluteBox.x0, closeTo(204.8, 0.1)); // 200/1000 * 1024
      expect(absoluteBox.y1, closeTo(384.0, 0.1)); // 500/1000 * 768
      expect(absoluteBox.x1, closeTo(819.2, 0.1)); // 800/1000 * 1024
    });

    test('should calculate segmentation statistics correctly', () {
      // Arrange
      final result = SegmentationResult(
        masks: [
          SegmentationMask(
            boundingBox: const BoundingBox2D(y0: 0, x0: 0, y1: 100, x1: 100),
            label: 'chair',
            maskData: Uint8List.fromList([1]),
            confidence: 0.9,
          ),
          SegmentationMask(
            boundingBox: const BoundingBox2D(y0: 0, x0: 0, y1: 200, x1: 200),
            label: 'table',
            maskData: Uint8List.fromList([1]),
            confidence: 0.8,
          ),
          SegmentationMask(
            boundingBox: const BoundingBox2D(y0: 0, x0: 0, y1: 150, x1: 150),
            label: 'chair',
            maskData: Uint8List.fromList([1]),
            confidence: 0.85,
          ),
        ],
        processingTimeMs: 1000,
        imageWidth: 1024,
        imageHeight: 768,
      );

      // Act
      final stats = result.stats;

      // Assert
      expect(stats.totalMasks, 3);
      expect(stats.averageConfidence, closeTo(0.85, 0.01)); // (0.9 + 0.8 + 0.85) / 3
      expect(stats.uniqueLabels, containsAll(['chair', 'table']));
      expect(stats.uniqueLabels.length, 2);
      expect(stats.totalArea, 90000.0); // 10000 + 40000 + 22500
    });

    group('Error Handling', () {
      test('should handle invalid confidence threshold', () async {
        // Act
        final result = await segmentationUseCase(
          testImageBytes,
          confidenceThreshold: 1.5, // Invalid - greater than 1.0
        );

        // Assert
        expect(result.isFailure, true);
        result.when(
          success: (_) => fail('Expected failure but got success'),
          failure: (error) {
            expect(error.toString(), contains('Confidence threshold must be between 0.0 and 1.0'));
          },
        );
      });

      test('should handle empty image data', () async {
        // Act
        final result = await segmentationUseCase(Uint8List(0));

        // Assert
        expect(result.isFailure, true);
        result.when(
          success: (_) => fail('Expected failure but got success'),
          failure: (error) {
            expect(error.toString(), contains('Image data cannot be empty'));
          },
        );
      });
    });
  });
}

/// Example usage of the new segmentation workflow
void exampleSegmentationWorkflow() async {
  // Initialize services (normally done via dependency injection)
  final geminiService = GeminiAIService();
  final segmentationUseCase = GenerateSegmentationMasksUseCase(geminiService);
  
  // Load image data (example)
  final imageBytes = Uint8List.fromList([/* image data */]);
  
  // Create processing context for segmentation
  final context = ProcessingContext.segmentation(
    targetObjects: 'wooden and glass items',
    confidenceThreshold: 0.7,
  );
  
  print('Processing Context: $context');
  print('Estimated processing time: ${context.estimatedProcessingTimeSeconds}s');
  
  // Generate segmentation masks
  final result = await segmentationUseCase(
    imageBytes,
    targetObjects: 'wooden and glass items',
    confidenceThreshold: 0.7,
  );
  
  result.when(
    success: (segmentationResult) {
      print('✅ Segmentation successful!');
      print('📊 Statistics: ${segmentationResult.stats}');
      
      // Convert to image markers for UI interaction
      final markers = segmentationResult.masks.map((mask) => 
        ImageMarker.fromSegmentation(
          id: 'seg_${mask.label.replaceAll(' ', '_')}',
          segmentationMask: mask,
        )
      ).toList();
      
      print('🎯 Generated ${markers.length} AI markers');
      
      // Process each segmented object
      for (final marker in markers) {
        print('  - ${marker.label} (confidence: ${marker.confidence?.toStringAsFixed(2)})');
        
        // Check if a point is within this segmented object
        final contains = marker.containsPoint(100, 200, 1024, 768);
        print('    Contains point (100, 200): $contains');
      }
    },
    failure: (error) {
      print('❌ Segmentation failed: $error');
    },
  );
}

// test/unit/features/ai_processing/domain/entities/processing_result_test.dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_result.dart';
import '../../../../../helpers/test_data/ai_test_data.dart';

void main() {
  group('ProcessingResult', () {
    group('constructor', () {
      test('should create instance with required parameters', () {
        // Arrange & Act
        final result = ProcessingResult(
          processedImageData: AITestData.testImageData,
          originalPrompt: 'Test prompt',
          enhancedPrompt: 'Enhanced test prompt',
          processingTime: const Duration(milliseconds: 1500),
        );

        // Assert
        expect(result.processedImageData, equals(AITestData.testImageData));
        expect(result.originalPrompt, equals('Test prompt'));
        expect(result.enhancedPrompt, equals('Enhanced test prompt'));
        expect(result.processingTime, equals(const Duration(milliseconds: 1500)));
        expect(result.jobId, isNull);
        expect(result.imageAnalysis, isNull);
        expect(result.metadata, isNull);
      });

      test('should create instance with optional parameters', () {
        // Arrange
        const jobId = 'test-job-123';
        final imageAnalysis = ImageAnalysis(
          width: 1920,
          height: 1080,
          format: 'PNG',
          fileSize: 1024,
          dominantColors: const ['#FF0000', '#00FF00'],
          detectedObjects: const ['person', 'car'],
          qualityScore: 0.85,
        );
        final metadata = {'test': 'value', 'count': 42};

        // Act
        final result = ProcessingResult(
          processedImageData: AITestData.testImageData,
          originalPrompt: 'Test prompt',
          enhancedPrompt: 'Enhanced test prompt',
          processingTime: const Duration(milliseconds: 1500),
          jobId: jobId,
          imageAnalysis: imageAnalysis,
          metadata: metadata,
        );

        // Assert
        expect(result.jobId, equals(jobId));
        expect(result.imageAnalysis, equals(imageAnalysis));
        expect(result.metadata, equals(metadata));
      });
    });

    group('equality', () {
      test('should be equal when all properties match', () {
        // Arrange
        final result1 = ProcessingResult(
          processedImageData: AITestData.testImageData,
          originalPrompt: 'Test prompt',
          enhancedPrompt: 'Enhanced test prompt',
          processingTime: const Duration(milliseconds: 1500),
          jobId: 'job-123',
        );

        final result2 = ProcessingResult(
          processedImageData: AITestData.testImageData,
          originalPrompt: 'Test prompt',
          enhancedPrompt: 'Enhanced test prompt',
          processingTime: const Duration(milliseconds: 1500),
          jobId: 'job-123',
        );

        // Act & Assert
        expect(result1, equals(result2));
        expect(result1.hashCode, equals(result2.hashCode));
      });

      test('should not be equal when properties differ', () {
        // Arrange
        final result1 = ProcessingResult(
          processedImageData: AITestData.testImageData,
          originalPrompt: 'Test prompt',
          enhancedPrompt: 'Enhanced test prompt',
          processingTime: const Duration(milliseconds: 1500),
        );

        final result2 = ProcessingResult(
          processedImageData: AITestData.testImageData,
          originalPrompt: 'Different prompt',
          enhancedPrompt: 'Enhanced test prompt',
          processingTime: const Duration(milliseconds: 1500),
        );

        // Act & Assert
        expect(result1, isNot(equals(result2)));
      });
    });

    group('validation', () {
      test('should accept valid processing times', () {
        // Arrange & Act
        final result = ProcessingResult(
          processedImageData: AITestData.testImageData,
          originalPrompt: 'Test',
          enhancedPrompt: 'Enhanced',
          processingTime: const Duration(milliseconds: 100),
        );

        // Assert
        expect(result.processingTime, equals(const Duration(milliseconds: 100)));
      });

      test('should accept zero processing time', () {
        // Arrange & Act
        final result = ProcessingResult(
          processedImageData: AITestData.testImageData,
          originalPrompt: 'Test',
          enhancedPrompt: 'Enhanced',
          processingTime: Duration.zero,
        );

        // Assert
        expect(result.processingTime, equals(Duration.zero));
      });

      test('should handle empty image data', () {
        // Arrange & Act
        final result = ProcessingResult(
          processedImageData: Uint8List(0),
          originalPrompt: 'Test',
          enhancedPrompt: 'Enhanced',
          processingTime: const Duration(milliseconds: 100),
        );

        // Assert
        expect(result.processedImageData.length, equals(0));
      });

      test('should handle empty prompts', () {
        // Arrange & Act
        final result = ProcessingResult(
          processedImageData: AITestData.testImageData,
          originalPrompt: '',
          enhancedPrompt: '',
          processingTime: const Duration(milliseconds: 100),
        );

        // Assert
        expect(result.originalPrompt, isEmpty);
        expect(result.enhancedPrompt, isEmpty);
      });
    });

    group('metadata handling', () {
      test('should preserve metadata structure', () {
        // Arrange
        final metadata = {
          'strokeCount': 3,
          'analysisModel': 'gemini-2.0-flash',
          'timestamp': '2025-06-28T10:00:00Z',
          'nested': {
            'key': 'value',
            'number': 42,
          },
        };

        // Act
        final result = ProcessingResult(
          processedImageData: AITestData.testImageData,
          originalPrompt: 'Test',
          enhancedPrompt: 'Enhanced',
          processingTime: const Duration(milliseconds: 100),
          metadata: metadata,
        );

        // Assert
        expect(result.metadata, equals(metadata));
        expect(result.metadata!['strokeCount'], equals(3));
        expect(result.metadata!['nested']['key'], equals('value'));
      });

      test('should handle null metadata', () {
        // Arrange & Act
        final result = ProcessingResult(
          processedImageData: AITestData.testImageData,
          originalPrompt: 'Test',
          enhancedPrompt: 'Enhanced',
          processingTime: const Duration(milliseconds: 100),
          metadata: null,
        );

        // Assert
        expect(result.metadata, isNull);
      });
    });
  });

  group('ImageAnalysis', () {
    group('constructor', () {
      test('should create instance with required parameters', () {
        // Arrange & Act
        const analysis = ImageAnalysis(
          width: 1920,
          height: 1080,
          format: 'JPEG',
          fileSize: 2048576,
        );

        // Assert
        expect(analysis.width, equals(1920));
        expect(analysis.height, equals(1080));
        expect(analysis.format, equals('JPEG'));
        expect(analysis.fileSize, equals(2048576));
        expect(analysis.dominantColors, isEmpty);
        expect(analysis.detectedObjects, isEmpty);
        expect(analysis.qualityScore, isNull);
      });

      test('should create instance with optional parameters', () {
        // Arrange & Act
        const analysis = ImageAnalysis(
          width: 1920,
          height: 1080,
          format: 'PNG',
          fileSize: 1024,
          dominantColors: ['#FF0000', '#00FF00', '#0000FF'],
          detectedObjects: ['person', 'car', 'tree'],
          qualityScore: 0.92,
        );

        // Assert
        expect(analysis.dominantColors.length, equals(3));
        expect(analysis.detectedObjects.length, equals(3));
        expect(analysis.qualityScore, equals(0.92));
      });
    });

    group('validation', () {
      test('should handle valid dimensions', () {
        // Arrange & Act
        const analysis = ImageAnalysis(
          width: 4096,
          height: 2160,
          format: 'WEBP',
          fileSize: 5242880,
        );

        // Assert
        expect(analysis.width, equals(4096));
        expect(analysis.height, equals(2160));
      });

      test('should handle various image formats', () {
        // Arrange
        const formats = ['JPEG', 'PNG', 'WEBP', 'GIF', 'BMP'];

        // Act & Assert
        for (final format in formats) {
          final analysis = ImageAnalysis(
            width: 800,
            height: 600,
            format: format,
            fileSize: 1024,
          );
          expect(analysis.format, equals(format));
        }
      });

      test('should handle quality scores in valid range', () {
        // Arrange
        const validScores = [0.0, 0.5, 0.75, 0.9, 1.0];

        // Act & Assert
        for (final score in validScores) {
          final analysis = ImageAnalysis(
            width: 800,
            height: 600,
            format: 'JPEG',
            fileSize: 1024,
            qualityScore: score,
          );
          expect(analysis.qualityScore, equals(score));
          expect(analysis.qualityScore! >= 0.0, isTrue);
          expect(analysis.qualityScore! <= 1.0, isTrue);
        }
      });
    });

    group('equality', () {
      test('should be equal when all properties match', () {
        // Arrange
        const analysis1 = ImageAnalysis(
          width: 1920,
          height: 1080,
          format: 'JPEG',
          fileSize: 2048,
          dominantColors: ['#FF0000'],
          detectedObjects: ['person'],
          qualityScore: 0.8,
        );

        const analysis2 = ImageAnalysis(
          width: 1920,
          height: 1080,
          format: 'JPEG',
          fileSize: 2048,
          dominantColors: ['#FF0000'],
          detectedObjects: ['person'],
          qualityScore: 0.8,
        );

        // Act & Assert
        expect(analysis1, equals(analysis2));
        expect(analysis1.hashCode, equals(analysis2.hashCode));
      });

      test('should not be equal when properties differ', () {
        // Arrange
        const analysis1 = ImageAnalysis(
          width: 1920,
          height: 1080,
          format: 'JPEG',
          fileSize: 2048,
        );

        const analysis2 = ImageAnalysis(
          width: 1280,
          height: 720,
          format: 'JPEG',
          fileSize: 2048,
        );

        // Act & Assert
        expect(analysis1, isNot(equals(analysis2)));
      });
    });
  });
}

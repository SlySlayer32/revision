import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:revision/features/ai_processing/infrastructure/services/ai_analysis_service.dart';
import 'package:revision/features/image_editing/domain/entities/annotated_image.dart';
import 'package:revision/features/image_editing/domain/entities/annotation_point.dart';
import 'package:revision/features/image_editing/domain/entities/annotation_stroke.dart';
import 'package:revision/features/image_selection/domain/entities/image_source.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';

import 'ai_analysis_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('AiAnalysisService', () {
    late AiAnalysisService aiAnalysisService;
    late MockClient mockHttpClient;
    late AnnotatedImage testAnnotatedImage;

    setUp(() {
      mockHttpClient = MockClient();
      aiAnalysisService = AiAnalysisService(httpClient: mockHttpClient);

      // Create test data
      final testImageData = Uint8List.fromList([1, 2, 3, 4, 5]);
      final selectedImage = SelectedImage(
        bytes: testImageData,
        name: 'test.jpg',
        sizeInBytes: testImageData.length,
        source: ImageSource.gallery,
      );

      final annotationStroke = AnnotationStroke(
        id: 'test-stroke-1',
        points: const [
          AnnotationPoint(x: 10.0, y: 10.0, pressure: 1.0),
          AnnotationPoint(x: 20.0, y: 20.0, pressure: 1.0),
        ],
        color: 0xFFFF0000, // Red color
        strokeWidth: 5.0,
        timestamp: DateTime.now(),
      );

      testAnnotatedImage = AnnotatedImage(
        originalImage: selectedImage,
        annotations: [annotationStroke],
        createdAt: DateTime.now(),
        instructions: 'Remove the marked object',
      );
    });

    tearDown(() {
      aiAnalysisService.dispose();
    });

    test('analyzeAnnotatedImage returns fallback result on HTTP error',
        () async {
      // Arrange
      when(mockHttpClient.send(any)).thenThrow(Exception('Network error'));

      // Act
      final result =
          await aiAnalysisService.analyzeAnnotatedImage(testAnnotatedImage);

      // Assert
      expect(
          result.originalPrompt, contains('User marked 1 objects for removal'));
      expect(result.enhancedPrompt, contains('Remove 1 marked objects'));
      expect(result.enhancedPrompt, contains('content-aware fill'));
      expect(result.enhancedPrompt, contains('inpainting techniques'));
      expect(result.metadata?['strokeCount'], equals(1));
      expect(result.metadata?['analysisModel'], equals('fallback'));
      expect(result.metadata?['fallbackReason'], contains('Network error'));
    });

    test('analyzeAnnotatedImage validates input parameters', () async {
      // Arrange - create annotated image with no strokes
      final emptyAnnotatedImage = AnnotatedImage(
        originalImage: testAnnotatedImage.originalImage,
        annotations: const [], // Empty annotations
        createdAt: DateTime.now(),
      );

      // Act & Assert
      expect(
        () => aiAnalysisService.analyzeAnnotatedImage(emptyAnnotatedImage),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('analyzeAnnotatedImage validates image size', () async {
      // Arrange - create image that's too large
      final largeImageData = Uint8List(15 * 1024 * 1024); // 15MB
      final largeSelectedImage = SelectedImage(
        bytes: largeImageData,
        name: 'large.jpg',
        sizeInBytes: largeImageData.length,
        source: ImageSource.gallery,
      );

      final largeAnnotatedImage = AnnotatedImage(
        originalImage: largeSelectedImage,
        annotations: testAnnotatedImage.annotations,
        createdAt: DateTime.now(),
      );

      // Act & Assert
      expect(
        () => aiAnalysisService.analyzeAnnotatedImage(largeAnnotatedImage),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('analyzeAnnotatedImage creates correct metadata', () async {
      // Arrange
      when(mockHttpClient.send(any)).thenThrow(Exception('Test error'));

      // Act
      final result =
          await aiAnalysisService.analyzeAnnotatedImage(testAnnotatedImage);

      // Assert
      expect(result.metadata, isNotNull);
      expect(result.metadata!['strokeCount'], equals(1));
      expect(
          result.metadata!['fallbackReason'], equals('Exception: Test error'));
      expect(result.metadata!['timestamp'], isNotNull);
      expect(result.processingTime, greaterThan(Duration.zero));
    });

    test('analyzeAnnotatedImage includes image analysis', () async {
      // Arrange
      when(mockHttpClient.send(any)).thenThrow(Exception('Test error'));

      // Act
      final result =
          await aiAnalysisService.analyzeAnnotatedImage(testAnnotatedImage);

      // Assert
      expect(result.imageAnalysis, isNotNull);
      expect(result.imageAnalysis!.format, equals('JPEG'));
      expect(result.imageAnalysis!.fileSize,
          equals(testAnnotatedImage.originalImage.sizeInBytes));
      expect(result.imageAnalysis!.detectedObjects, contains('marked_objects'));
    });
  });
}

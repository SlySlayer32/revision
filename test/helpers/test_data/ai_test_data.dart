// test/helpers/test_data/ai_test_data.dart
import 'dart:typed_data';

import 'package:revision/features/ai_processing/domain/entities/processing_result.dart';
import 'package:revision/features/image_editing/domain/entities/annotated_image.dart';
import 'package:revision/features/image_editing/domain/entities/annotation_stroke.dart';
import 'package:revision/features/image_editing/domain/entities/annotation_point.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';
import 'package:revision/features/image_selection/domain/entities/image_source.dart';
import 'package:revision/core/services/gemini_pipeline_service.dart';

/// Test data factory for AI processing tests
class AITestData {
  /// Test image data (1x1 white pixel PNG)
  static Uint8List get testImageData => Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1 pixel
        0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE,
        0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, 0x54, // IDAT chunk
        0x08, 0x99, 0x01, 0x01, 0x00, 0x00, 0x00, 0xFF,
        0xFF, 0x00, 0x00, 0x00, 0x02, 0x00, 0x01, 0xE5,
        0x27, 0xDE, 0xFC, 0x00, 0x00, 0x00, 0x00, 0x49,
        0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82 // IEND chunk
      ]);

  /// Test image data (larger for size validation tests)
  static Uint8List get largeTestImageData => Uint8List(25 * 1024 * 1024); // 25MB

  /// Valid test user annotations
  static List<AnnotationStroke> get testAnnotations => [
        AnnotationStroke(
          id: 'test-stroke-1',
          points: const [
            AnnotationPoint(x: 0.1, y: 0.1, pressure: 0.5),
            AnnotationPoint(x: 0.15, y: 0.15, pressure: 0.6),
            AnnotationPoint(x: 0.2, y: 0.2, pressure: 0.5),
          ],
          color: 0xFFFF0000, // Red
          strokeWidth: 5.0,
          timestamp: DateTime(2025, 6, 28, 10, 0, 0),
        ),
        AnnotationStroke(
          id: 'test-stroke-2',
          points: const [
            AnnotationPoint(x: 0.3, y: 0.3, pressure: 0.7),
            AnnotationPoint(x: 0.35, y: 0.35, pressure: 0.8),
          ],
          color: 0xFF00FF00, // Green
          strokeWidth: 3.0,
          timestamp: DateTime(2025, 6, 28, 10, 1, 0),
        ),
      ];

  /// Test marked areas data for AI pipeline
  static List<Map<String, dynamic>> get testMarkedAreas => [
        {
          'x': 100.0,
          'y': 100.0,
          'width': 100.0,
          'height': 100.0,
          'description': 'Person in background',
        },
        {
          'x': 300.0,
          'y': 300.0,
          'width': 50.0,
          'height': 50.0,
          'description': 'Unwanted object',
        },
      ];

  /// Test selected image
  static SelectedImage get testSelectedImage => SelectedImage(
        bytes: testImageData,
        name: 'test_image.png',
        sizeInBytes: testImageData.length,
        source: ImageSource.gallery,
      );

  /// Test annotated image
  static AnnotatedImage get testAnnotatedImage => AnnotatedImage(
        originalImage: testSelectedImage,
        annotations: testAnnotations,
        createdAt: DateTime(2025, 6, 28, 10, 0, 0),
        instructions: 'Remove marked objects from the image',
      );

  /// Valid AI analysis response
  static const String validAnalysisResponse = '''
Remove the marked objects using advanced inpainting techniques. Apply content-aware fill to seamlessly reconstruct the background where objects were removed. The first marked area contains a person in the background that should be completely removed while preserving the natural scenery. The second area has an unwanted object that needs careful removal with attention to lighting consistency. Maintain the original image's color palette and ensure smooth transitions between filled areas and existing content.
''';

  /// Mock processing result
  static ProcessingResult get mockProcessingResult => ProcessingResult(
        processedImageData: testImageData,
        originalPrompt: 'User marked 2 objects for removal',
        enhancedPrompt: validAnalysisResponse,
        processingTime: const Duration(milliseconds: 1500),
        metadata: {
          'strokeCount': 2,
          'analysisModel': 'gemini-2.0-flash',
          'timestamp': '2025-06-28T10:00:00.000Z',
        },
      );

  /// Mock pipeline result
  static GeminiPipelineResult get mockPipelineResult => GeminiPipelineResult(
        originalImage: testImageData,
        analysisPrompt: validAnalysisResponse,
        generatedImage: testImageData, // In real scenario, this would be the edited image
        processingTimeMs: DateTime.now().millisecondsSinceEpoch,
        markedAreas: testMarkedAreas,
      );

  /// Error scenarios
  static const String networkErrorMessage = 'Network connection failed';
  static const String authErrorMessage = 'Authentication failed';
  static const String rateLimitErrorMessage = 'Rate limit exceeded';
  static const String invalidImageErrorMessage = 'Invalid image format';

  /// Test environment variables
  static Map<String, String> get testEnvironmentVariables => {
        'FIREBASE_AI_API_KEY': 'test-api-key-12345',
        'GOOGLE_CLOUD_PROJECT_ID': 'test-project-id',
      };
}

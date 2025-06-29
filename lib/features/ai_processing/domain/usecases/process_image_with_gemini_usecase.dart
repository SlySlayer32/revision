import 'dart:typed_data';

import 'package:revision/core/services/gemini_pipeline_service.dart';
import 'package:revision/core/utils/result.dart';

/// Use case for processing images with the Gemini AI Pipeline
///
/// Implements the MVP requirements:
/// 1. Image Analysis using Gemini 2.5 Flash
/// 2. Image Generation using Gemini 2.0 Flash Preview Image Generation
class ProcessImageWithGeminiUseCase {
  const ProcessImageWithGeminiUseCase(this._geminiPipelineService);

  final GeminiPipelineService _geminiPipelineService;

  /// Process an image through the complete Gemini AI Pipeline
  ///
  /// [imageData] - The original image as bytes (max 10MB per MVP)
  ///
  /// Returns [GeminiPipelineResult] with original image, analysis prompt,
  /// and generated image, or [Exception] on failure.
  Future<Result<GeminiPipelineResult>> call(Uint8List imageData) async {
    try {
      // Validate image data
      if (imageData.isEmpty) {
        return const Failure(
          GeminiPipelineException('Image data cannot be empty'),
        );
      }

      // Validate image size (max 10MB per MVP requirements)
      const maxSizeMB = 10;
      final sizeMB = imageData.length / (1024 * 1024);
      if (sizeMB > maxSizeMB) {
        return Failure(
          GeminiPipelineException(
            'Image too large: ${sizeMB.toStringAsFixed(1)}MB (max ${maxSizeMB}MB)',
          ),
        );
      }

      // Execute the complete Gemini AI Pipeline
      final result = await _geminiPipelineService.processImage(imageData);

      return Success(result);
    } catch (e, stackTrace) {
      // Add detailed logging for debugging
      print('🚨 Gemini AI Pipeline Error Details:');
      print('Error: $e');
      print('Error Type: ${e.runtimeType}');
      print('Stack Trace: $stackTrace');
      
      String errorMessage = 'Gemini AI Pipeline failed: ${e.toString()}';
      
      // Provide specific guidance based on error type
      if (e.toString().contains('403') || e.toString().contains('forbidden')) {
        errorMessage = 'Firebase AI access denied. Check project billing and API permissions.';
      } else if (e.toString().contains('404') || e.toString().contains('not found')) {
        errorMessage = 'Gemini model not found. The model might not be available in your region.';
      } else if (e.toString().contains('quota') || e.toString().contains('limit')) {
        errorMessage = 'Gemini API quota exceeded. Check your Firebase billing and usage limits.';
      } else if (e.toString().contains('authentication') || e.toString().contains('unauthorized')) {
        errorMessage = 'Firebase AI authentication failed. Check your Firebase project configuration.';
      }
      
      return Failure(
        GeminiPipelineException(errorMessage),
      );
    }
  }
}

/// Exception thrown during Gemini AI Pipeline processing
class GeminiPipelineException implements Exception {
  const GeminiPipelineException(this.message);

  final String message;

  @override
  String toString() => 'GeminiPipelineException: $message';
}

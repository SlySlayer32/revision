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
    } catch (e) {
      return Failure(
        GeminiPipelineException('Gemini AI Pipeline failed: ${e.toString()}'),
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

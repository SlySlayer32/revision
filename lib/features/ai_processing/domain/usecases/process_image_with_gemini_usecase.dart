import 'dart:typed_data';

import 'package:revision/core/services/gemini_pipeline_service.dart';
import 'package:revision/core/utils/result.dart';
import 'package:revision/core/utils/enhanced_logger.dart';
import 'package:revision/features/ai_processing/domain/constants/ai_processing_constants.dart';
import 'package:revision/features/ai_processing/domain/exceptions/ai_processing_exception.dart';
import 'package:revision/features/ai_processing/domain/validators/image_validator.dart';
import 'package:revision/features/ai_processing/domain/error_handlers/ai_error_handler.dart';

/// Use case for processing images with the Gemini AI Pipeline
///
/// Implements the MVP requirements with improved separation of concerns:
/// 1. Image Analysis using Gemini 2.5 Flash
/// 2. Image Generation using Gemini 2.0 Flash Preview Image Generation
///
/// This implementation addresses identified code smells:
/// - Extracted constants to dedicated file
/// - Created proper exception hierarchy
/// - Separated validation logic
/// - Improved error handling and mapping
class ProcessImageWithGeminiUseCase {
  ProcessImageWithGeminiUseCase(this._geminiPipelineService);

  final GeminiPipelineService _geminiPipelineService;
  final EnhancedLogger _logger = EnhancedLogger();

  /// Process an image through the complete Gemini AI Pipeline
  ///
  /// [imageData] - The original image as bytes (max 10MB per MVP)
  /// [markedAreas] - List of marked areas for object removal
  ///
  /// Returns [GeminiPipelineResult] with original image, analysis prompt,
  /// and generated image, or [AIProcessingException] on failure.
  Future<Result<GeminiPipelineResult>> call(
    Uint8List imageData, {
    List<Map<String, dynamic>> markedAreas = const [],
  }) async {
    try {
      // Step 1: Validate all inputs
      final validationResult = _validateInputs(imageData, markedAreas);
      if (validationResult.isFailure) {
        // Convert validation failure to processing failure
        return Failure<GeminiPipelineResult>(validationResult.error);
      }

      // Step 2: Execute processing
      return await _executeProcessing(imageData, markedAreas);
    } catch (e, stackTrace) {
      return _handleError(e, stackTrace, imageData, markedAreas);
    }
  }

  /// Validates all inputs for processing
  ///
  /// Separates validation concerns for better testability
  Result<void> _validateInputs(
    Uint8List imageData,
    List<Map<String, dynamic>> markedAreas,
  ) {
    // Validate image data
    final imageValidation = ImageValidator.validateImageData(imageData);
    if (imageValidation.isFailure) {
      return imageValidation;
    }

    // Simple validation for marked areas structure
    for (int i = 0; i < markedAreas.length; i++) {
      final area = markedAreas[i];
      if (!area.containsKey('x') || !area.containsKey('y') ||
          !area.containsKey('width') || !area.containsKey('height')) {
        return Failure(
          MarkedAreaValidationException('Marked area $i missing required coordinates'),
        );
      }
    }

    return const Success(null);
  }

  /// Executes the core processing logic
  ///
  /// Delegates to the appropriate service method based on marked areas
  Future<Result<GeminiPipelineResult>> _executeProcessing(
    Uint8List imageData,
    List<Map<String, dynamic>> markedAreas,
  ) async {
    // Generate appropriate prompt based on marked areas
    final prompt = _generatePrompt(markedAreas);

    // Execute processing based on whether we have marked areas
    final result = markedAreas.isNotEmpty
        ? await _geminiPipelineService.processImageWithMarkedObjects(
            imageData: imageData,
            markedAreas: markedAreas,
          )
        : await _geminiPipelineService.processImage(imageData, prompt);

    return Success(result);
  }

  /// Generates appropriate prompt based on marked areas
  String _generatePrompt(List<Map<String, dynamic>> markedAreas) {
    if (markedAreas.isEmpty) {
      return 'Enhance this image by improving quality, lighting, and composition';
    }

    return 'Remove objects in marked areas: ${markedAreas.length} areas marked for removal';
  }

  /// Handles errors with proper logging and exception mapping
  ///
  /// Maps generic exceptions to domain-specific exceptions
  /// Provides structured logging with relevant context
  Result<GeminiPipelineResult> _handleError(
    Object error,
    StackTrace stackTrace,
    Uint8List imageData,
    List<Map<String, dynamic>> markedAreas,
  ) {
    // Map to domain-specific exception
    final mappedException = AIErrorHandler.mapException(error);

    // Log with structured context
    _logger.error(
      'Gemini AI Pipeline Error',
      operation: AIProcessingConstants.operationName,
      error: mappedException,
      stackTrace: stackTrace,
      context: {
        'errorCategory': mappedException.category.toString(),
        'imageSize': imageData.length,
        'markedAreasCount': markedAreas.length,
        'isRetryable': AIErrorHandler.isRetryableException(mappedException),
      },
    );

    return Failure(mappedException);
  }
}

/// Exception thrown during Gemini AI Pipeline processing
class GeminiPipelineException implements Exception {
  const GeminiPipelineException(this.message);

  final String message;

  @override
  String toString() => 'GeminiPipelineException: $message';
}

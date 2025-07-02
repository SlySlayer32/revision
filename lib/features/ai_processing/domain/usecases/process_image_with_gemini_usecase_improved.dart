import 'dart:typed_data';

import 'package:revision/core/services/gemini_pipeline_service.dart';
import 'package:revision/core/utils/result.dart';
import 'package:revision/core/utils/enhanced_logger.dart';
import 'package:revision/features/ai_processing/domain/constants/ai_processing_constants.dart';
import 'package:revision/features/ai_processing/domain/validators/image_validator.dart';
import 'package:revision/features/ai_processing/domain/error_handlers/ai_error_handler.dart';
import 'package:revision/features/ai_processing/domain/value_objects/marked_area.dart';
import 'package:revision/features/ai_processing/domain/exceptions/ai_processing_exception.dart';

/// Use case for processing images with the Gemini AI Pipeline
///
/// Implements the MVP requirements with proper separation of concerns:
/// 1. Image Analysis using Gemini 2.5 Flash
/// 2. Image Generation using Gemini 2.0 Flash Preview Image Generation
///
/// This refactored version addresses code smells:
/// - Extracted validation logic to dedicated validators
/// - Proper exception hierarchy for error handling
/// - Type-safe value objects for marked areas
/// - Separated concerns for better testability
/// - Constants extracted for maintainability
class ProcessImageWithGeminiUseCaseImproved {
  ProcessImageWithGeminiUseCaseImproved(this._geminiPipelineService);

  final GeminiPipelineService _geminiPipelineService;
  final EnhancedLogger _logger = EnhancedLogger();

  /// Process an image through the complete Gemini AI Pipeline
  ///
  /// [imageData] - The original image as bytes (max defined by constants)
  /// [markedAreas] - List of marked areas for object removal (type-safe)
  ///
  /// Returns [GeminiPipelineResult] with original image, analysis prompt,
  /// and generated image, or [AIProcessingException] on failure.
  Future<Result<GeminiPipelineResult>> call(
    Uint8List imageData, {
    List<MarkedArea> markedAreas = const [],
  }) async {
    try {
      // Step 1: Validate all inputs
      final validationResult = _validateInputs(imageData, markedAreas);
      if (validationResult.isFailure) {
        return Failure<GeminiPipelineResult>(
          validationResult.exceptionOrNull ?? 
          const GeminiPipelineException('Validation failed')
        );
      }

      // Step 2: Execute the AI processing pipeline
      return await _executeProcessing(imageData, markedAreas);
    } catch (e, stackTrace) {
      // Step 3: Handle and map errors appropriately
      return _handleError(e, stackTrace, imageData, markedAreas);
    }
  }

  /// Validates all input parameters using dedicated validators
  ///
  /// Returns [Success] if all validations pass, [Failure] otherwise
  Result<void> _validateInputs(
    Uint8List imageData,
    List<MarkedArea> markedAreas,
  ) {
    // Validate image data (size, format, etc.)
    final imageValidation = ImageValidator.validateImageData(imageData);
    if (imageValidation.isFailure) {
      return imageValidation;
    }

    // Validate marked areas structure and content
    final areasValidation = ImageValidator.validateMarkedAreas(markedAreas);
    if (areasValidation.isFailure) {
      return areasValidation;
    }

    return const Success(null);
  }

  /// Executes the core processing logic
  ///
  /// Delegates to the appropriate service method based on marked areas
  Future<Result<GeminiPipelineResult>> _executeProcessing(
    Uint8List imageData,
    List<MarkedArea> markedAreas,
  ) async {
    // TODO: Current service only supports basic processing
    // This is a placeholder until the service supports marked areas
    final prompt = markedAreas.isNotEmpty
        ? 'Remove objects in marked areas: ${markedAreas.map((area) => area.description ?? 'unmarked area').join(', ')}'
        : 'Process and enhance this image';
        
    final result = await _geminiPipelineService.processImage(imageData, prompt);
    return Success(result);
  }

  /// Handles errors with proper logging and exception mapping
  ///
  /// Maps generic exceptions to domain-specific exceptions
  /// Provides structured logging with relevant context
  Result<GeminiPipelineResult> _handleError(
    Object error,
    StackTrace stackTrace,
    Uint8List imageData,
    List<MarkedArea> markedAreas,
  ) {
    // Log error with structured context
    _logger.error(
      'Gemini AI Pipeline processing failed',
      operation: AIProcessingConstants.operationName,
      error: error,
      stackTrace: stackTrace,
      context: {
        'errorType': error.runtimeType.toString(),
        'imageSize': imageData.length,
        'imageSizeMB': (imageData.length / AIProcessingConstants.bytesPerMB)
            .toStringAsFixed(2),
        'markedAreasCount': markedAreas.length,
        'hasMarkedAreas': markedAreas.isNotEmpty,
      },
    );

    // Map to appropriate domain exception
    final mappedException = AIErrorHandler.mapException(error);
    return Failure(mappedException);
  }
}

import 'dart:typed_data';

import 'package:revision/core/services/gemini_ai_service.dart';
import 'package:revision/core/utils/enhanced_logger.dart';
import 'package:revision/core/utils/result.dart';
import 'package:revision/features/ai_processing/domain/constants/ai_processing_constants.dart';
import 'package:revision/features/ai_processing/domain/entities/segmentation_result.dart';
import 'package:revision/features/ai_processing/domain/error_handlers/ai_error_handler.dart';
import 'package:revision/features/ai_processing/domain/exceptions/ai_processing_exception.dart';
import 'package:revision/features/ai_processing/domain/validators/image_validator.dart';

/// Use case for generating segmentation masks using Gemini 2.5
///
/// Implements the latest Gemini 2.5 segmentation capabilities:
/// - Object detection with contour masks
/// - Base64 encoded PNG probability maps
/// - Precise bounding box coordinates
/// - Support for targeted object segmentation
class GenerateSegmentationMasksUseCase {
  GenerateSegmentationMasksUseCase(this._geminiAIService);

  final GeminiAIService _geminiAIService;
  final EnhancedLogger _logger = EnhancedLogger();

  /// Generate segmentation masks for objects in the image
  ///
  /// [imageData] - The image bytes to process (max defined by constants)
  /// [targetObjects] - Optional specific objects to segment (e.g., "wooden and glass items")
  /// [confidenceThreshold] - Minimum confidence score for masks (0.0 to 1.0)
  ///
  /// Returns [SegmentationResult] with detected masks and metadata,
  /// or [AIProcessingException] on failure.
  Future<Result<SegmentationResult>> call(
    Uint8List imageData, {
    String? targetObjects,
    double confidenceThreshold = 0.5,
  }) async {
    try {
      // Step 1: Validate inputs
      final validationResult = _validateInputs(imageData, confidenceThreshold);
      if (validationResult.isFailure) {
        return Failure<SegmentationResult>(validationResult.exceptionOrNull!);
      }

      // Step 2: Execute segmentation
      return await _executeSegmentation(
        imageData,
        targetObjects,
        confidenceThreshold,
      );
    } catch (e, stackTrace) {
      return _handleError(e, stackTrace, imageData, targetObjects);
    }
  }

  /// Validates all inputs for segmentation
  Result<void> _validateInputs(
    Uint8List imageData,
    double confidenceThreshold,
  ) {
    // Validate image data
    final imageValidation = ImageValidator.validateImageData(imageData);
    if (imageValidation.isFailure) {
      return imageValidation;
    }

    // Validate confidence threshold
    if (confidenceThreshold < 0.0 || confidenceThreshold > 1.0) {
      return const Failure(
        ImageValidationException(
            'Confidence threshold must be between 0.0 and 1.0'),
      );
    }

    return const Success(null);
  }

  /// Executes the segmentation operation
  Future<Result<SegmentationResult>> _executeSegmentation(
    Uint8List imageData,
    String? targetObjects,
    double confidenceThreshold,
  ) async {
    _logger.info(
      'Starting Gemini 2.5 segmentation',
      operation: 'GEMINI_SEGMENTATION',
      context: {
        'imageSize': imageData.length,
        'imageSizeMB': (imageData.length / AIProcessingConstants.bytesPerMB)
            .toStringAsFixed(2),
        'targetObjects': targetObjects ?? 'all objects',
        'confidenceThreshold': confidenceThreshold,
      },
    );

    try {
      // Generate segmentation masks using Gemini 2.5
      final result = await _geminiAIService.generateSegmentationMasks(
        imageBytes: imageData,
        targetObjects: targetObjects,
        confidenceThreshold: confidenceThreshold,
      );

      // Filter masks by confidence threshold
      final filteredMasks = result.masks
          .where((mask) => mask.confidence >= confidenceThreshold)
          .toList();

      final filteredResult = SegmentationResult(
        masks: filteredMasks,
        processingTimeMs: result.processingTimeMs,
        imageWidth: result.imageWidth,
        imageHeight: result.imageHeight,
        modelVersion: result.modelVersion,
        confidence: filteredMasks.isNotEmpty
            ? filteredMasks.map((m) => m.confidence).reduce((a, b) => a + b) /
                filteredMasks.length
            : 0.0,
      );

      _logger.info(
        'Segmentation completed successfully',
        operation: 'GEMINI_SEGMENTATION',
        context: {
          'totalMasks': result.masks.length,
          'filteredMasks': filteredMasks.length,
          'averageConfidence': filteredResult.confidence.toStringAsFixed(2),
          'processingTimeMs': result.processingTimeMs,
          'uniqueLabels': filteredResult.stats.uniqueLabels,
        },
      );

      return Success(filteredResult);
    } catch (e) {
      throw GeminiPipelineException('Segmentation failed: ${e.toString()}');
    }
  }

  /// Handles errors with proper logging and exception mapping
  Result<SegmentationResult> _handleError(
    Object error,
    StackTrace stackTrace,
    Uint8List imageData,
    String? targetObjects,
  ) {
    _logger.error(
      'Gemini 2.5 segmentation failed',
      operation: 'GEMINI_SEGMENTATION',
      error: error,
      stackTrace: stackTrace,
      context: {
        'errorType': error.runtimeType.toString(),
        'imageSize': imageData.length,
        'imageSizeMB': (imageData.length / AIProcessingConstants.bytesPerMB)
            .toStringAsFixed(2),
        'targetObjects': targetObjects ?? 'all objects',
      },
    );

    // Map to appropriate domain exception
    final mappedException = AIErrorHandler.mapException(error);
    return Failure(mappedException);
  }
}

/// Use case for detecting objects with bounding boxes using Gemini 2.0+
///
/// Implements the enhanced object detection capabilities in Gemini 2.0
/// and later models with normalized bounding box coordinates.
class DetectObjectsWithBoundingBoxesUseCase {
  DetectObjectsWithBoundingBoxesUseCase(this._geminiAIService);

  final GeminiAIService _geminiAIService;
  final EnhancedLogger _logger = EnhancedLogger();

  /// Detect objects in the image with bounding boxes
  ///
  /// [imageData] - The image bytes to process
  /// [targetObjects] - Optional specific objects to detect
  ///
  /// Returns list of detected objects with normalized bounding boxes,
  /// or [AIProcessingException] on failure.
  Future<Result<List<Map<String, dynamic>>>> call(
    Uint8List imageData, {
    String? targetObjects,
  }) async {
    try {
      // Step 1: Validate inputs
      final validationResult = ImageValidator.validateImageData(imageData);
      if (validationResult.isFailure) {
        return Failure<List<Map<String, dynamic>>>(
            validationResult.exceptionOrNull!);
      }

      // Step 2: Execute object detection
      return await _executeObjectDetection(imageData, targetObjects);
    } catch (e, stackTrace) {
      return _handleError(e, stackTrace, imageData, targetObjects);
    }
  }

  /// Executes the object detection operation
  Future<Result<List<Map<String, dynamic>>>> _executeObjectDetection(
    Uint8List imageData,
    String? targetObjects,
  ) async {
    _logger.info(
      'Starting Gemini 2.0+ object detection',
      operation: 'GEMINI_OBJECT_DETECTION',
      context: {
        'imageSize': imageData.length,
        'targetObjects': targetObjects ?? 'all objects',
      },
    );

    try {
      final result = await _geminiAIService.detectObjectsWithBoundingBoxes(
        imageBytes: imageData,
        targetObjects: targetObjects,
      );

      _logger.info(
        'Object detection completed successfully',
        operation: 'GEMINI_OBJECT_DETECTION',
        context: {
          'detectedObjects': result.length,
          'labels': result
              .map((obj) => obj['label'] ?? obj['name'] ?? 'unknown')
              .toList(),
        },
      );

      return Success(result);
    } catch (e) {
      throw GeminiPipelineException('Object detection failed: ${e.toString()}');
    }
  }

  /// Handles errors with proper logging and exception mapping
  Result<List<Map<String, dynamic>>> _handleError(
    Object error,
    StackTrace stackTrace,
    Uint8List imageData,
    String? targetObjects,
  ) {
    _logger.error(
      'Gemini 2.0+ object detection failed',
      operation: 'GEMINI_OBJECT_DETECTION',
      error: error,
      stackTrace: stackTrace,
      context: {
        'errorType': error.runtimeType.toString(),
        'imageSize': imageData.length,
        'targetObjects': targetObjects ?? 'all objects',
      },
    );

    final mappedException = AIErrorHandler.mapException(error);
    return Failure(mappedException);
  }
}

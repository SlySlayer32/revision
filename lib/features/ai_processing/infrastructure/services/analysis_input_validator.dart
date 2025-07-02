import 'dart:io';

import 'package:revision/features/ai_processing/domain/exceptions/ai_processing_exception.dart';
import 'package:revision/features/ai_processing/infrastructure/config/analysis_service_config.dart';
import 'package:revision/features/image_editing/domain/entities/annotated_image.dart';
import 'package:revision/core/utils/result.dart';

/// Service responsible for validating inputs before AI analysis
/// 
/// Separates validation concerns from analysis logic following
/// Single Responsibility Principle.
class AnalysisInputValidator {
  /// Validates an annotated image for AI analysis
  /// 
  /// Checks image data, size constraints, and annotation requirements.
  /// Returns Success if valid, Failure with specific exception if invalid.
  static Future<Result<void>> validate(AnnotatedImage annotatedImage) async {
    try {
      // Get image data for validation (AnnotatedImage has imageBytes directly)
      final imageData = annotatedImage.imageBytes;
      
      // Validate image data exists
      if (imageData.isEmpty) {
        return const Failure(AnalysisValidationException('Image data cannot be empty'));
      }
      
      // Validate image size constraints
      if (imageData.length > AnalysisServiceConfig.maxImageSizeBytes) {
        return Failure(AnalysisValidationException(
          'Image size ${imageData.length} bytes exceeds maximum ${AnalysisServiceConfig.maxImageSizeBytes} bytes',
        ));
      }
      
      // Validate annotations exist
      if (annotatedImage.annotations.isEmpty) {
        return const Failure(AnalysisValidationException(
          'No annotation strokes found. Please mark objects to remove.',
        ));
      }
      
      // Validate annotation data quality
      final totalPoints = annotatedImage.annotations
          .fold<int>(0, (sum, stroke) => sum + stroke.points.length);
      
      if (totalPoints < 3) {
        return const Failure(AnalysisValidationException(
          'Insufficient annotation data. Please provide more detailed markings.',
        ));
      }
      
      return const Success(null);
    } catch (e) {
      return Failure(AnalysisValidationException(
        'Validation failed: ${e.toString()}',
      ));
    }
  }
}

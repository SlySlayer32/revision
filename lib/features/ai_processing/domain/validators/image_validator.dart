import 'dart:typed_data';

import 'package:revision/core/utils/result.dart';
import 'package:revision/features/ai_processing/domain/constants/ai_processing_constants.dart';
import 'package:revision/features/ai_processing/domain/exceptions/ai_processing_exception.dart';
import 'package:revision/features/ai_processing/domain/value_objects/marked_area.dart';

/// Validator for image data and related parameters
///
/// Centralizes all validation logic to improve testability and reusability
class ImageValidator {
  /// Validates image data for size, format, and basic integrity
  ///
  /// Returns [Success] if validation passes, [Failure] with specific
  /// exception if validation fails
  static Result<void> validateImageData(Uint8List imageData) {
    // Check if image data is empty
    if (imageData.isEmpty) {
      return const Failure(
        ImageValidationException(AIProcessingConstants.imageEmptyMessage),
      );
    }

    // Check image size constraints
    final sizeMB = imageData.length / AIProcessingConstants.bytesPerMB;
    if (sizeMB > AIProcessingConstants.maxImageSizeMB) {
      final message = AIProcessingConstants.imageTooLargeTemplate
          .replaceAll('{size}', sizeMB.toStringAsFixed(1))
          .replaceAll('{max}', AIProcessingConstants.maxImageSizeMB.toString());
      
      return Failure(ImageValidationException(message));
    }

    // Basic format validation (could be extended)
    if (!_isValidImageFormat(imageData)) {
      return const Failure(
        ImageValidationException('Invalid image format detected'),
      );
    }

    return const Success(null);
  }

  /// Validates marked areas for structure and constraints
  ///
  /// Checks individual area validity and overall constraints
  static Result<void> validateMarkedAreas(List<MarkedArea> markedAreas) {
    // Check maximum number of marked areas
    if (markedAreas.length > AIProcessingConstants.maxMarkedAreasCount) {
      final message = AIProcessingConstants.tooManyMarkedAreasTemplate
          .replaceAll('{count}', markedAreas.length.toString())
          .replaceAll('{max}', AIProcessingConstants.maxMarkedAreasCount.toString());
      
      return Failure(MarkedAreaValidationException(message));
    }

    // Validate each marked area
    for (int i = 0; i < markedAreas.length; i++) {
      final area = markedAreas[i];
      
      if (!area.isValid) {
        return Failure(
          MarkedAreaValidationException(
            'Invalid marked area at index $i: coordinates out of bounds',
          ),
        );
      }

      // Check area size constraints
      if (area.areaPercentage < AIProcessingConstants.minMarkedAreaSize) {
        return Failure(
          MarkedAreaValidationException(
            'Marked area at index $i is too small (${(area.areaPercentage * 100).toStringAsFixed(1)}%)',
          ),
        );
      }

      if (area.areaPercentage > AIProcessingConstants.maxMarkedAreaSize) {
        return Failure(
          MarkedAreaValidationException(
            'Marked area at index $i is too large (${(area.areaPercentage * 100).toStringAsFixed(1)}%)',
          ),
        );
      }
    }

    return const Success(null);
  }

  /// Basic image format validation
  ///
  /// Checks for common image file signatures
  static bool _isValidImageFormat(Uint8List imageData) {
    if (imageData.length < 4) return false;

    // Check for common image signatures
    // JPEG: FF D8 FF
    if (imageData[0] == 0xFF && imageData[1] == 0xD8 && imageData[2] == 0xFF) {
      return true;
    }

    // PNG: 89 50 4E 47
    if (imageData.length >= 8 &&
        imageData[0] == 0x89 &&
        imageData[1] == 0x50 &&
        imageData[2] == 0x4E &&
        imageData[3] == 0x47) {
      return true;
    }

    // WebP: "RIFF" followed by "WEBP"
    if (imageData.length >= 12) {
      final riff = String.fromCharCodes(imageData.sublist(0, 4));
      final webp = String.fromCharCodes(imageData.sublist(8, 12));
      if (riff == 'RIFF' && webp == 'WEBP') {
        return true;
      }
    }

    // GIF: "GIF8"
    if (imageData.length >= 6) {
      final gif = String.fromCharCodes(imageData.sublist(0, 4));
      if (gif == 'GIF8') {
        return true;
      }
    }

    return false;
  }
}

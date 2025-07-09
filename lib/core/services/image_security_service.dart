import 'dart:typed_data';
import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:revision/core/constants/app_constants.dart';
import 'package:revision/core/utils/result.dart';
import 'package:revision/core/utils/security_utils.dart';
import 'package:revision/features/ai_processing/domain/validators/image_validator.dart';
import 'package:revision/features/image_selection/domain/exceptions/image_selection_exception.dart';

/// Comprehensive image security service that handles validation, compression, and EXIF stripping.
///
/// This service consolidates all image security operations to ensure safe processing
/// and prevent potential security vulnerabilities in image handling.
class ImageSecurityService {
  /// Validates image data with comprehensive security checks.
  ///
  /// Performs validation for:
  /// - File size limits
  /// - Format validation using magic numbers
  /// - Basic malware scanning through header analysis
  /// - Dimension constraints
  ///
  /// Returns [Success] if all validations pass, [Failure] with specific error if not.
  static Result<void> validateImage(Uint8List imageData, {String? filename}) {
    // Check if image data is empty
    if (imageData.isEmpty) {
      return const Failure(
        ImageSelectionException.invalidFormat('Image data cannot be empty'),
      );
    }

    // Check file size against AppConstants limit
    if (imageData.length > AppConstants.maxImageSize) {
      final sizeMB = AppConstants.bytesToMB(imageData.length);
      final maxSizeMB = AppConstants.bytesToMB(AppConstants.maxImageSize);
      return Failure(
        ImageSelectionException.fileTooLarge(
          'Image is too large: ${sizeMB.toStringAsFixed(1)}MB '
          '(max ${maxSizeMB.toStringAsFixed(1)}MB)',
        ),
      );
    }

    // Use existing ImageValidator for format validation
    final formatValidation = ImageValidator.validateImageData(imageData);
    if (formatValidation.isFailure) {
      return Failure(
        ImageSelectionException.invalidFormat(
          formatValidation.exceptionOrNull.toString(),
        ),
      );
    }

    // Validate filename if provided
    if (filename != null) {
      final filenameValidation = _validateFilename(filename);
      if (filenameValidation.isFailure) {
        return filenameValidation;
      }
    }

    // Enhanced malware scanning through header analysis
    final malwareCheck = _performMalwareScanning(imageData);
    if (malwareCheck.isFailure) {
      return malwareCheck;
    }

    // Validate image dimensions if possible
    final dimensionValidation = _validateImageDimensions(imageData);
    if (dimensionValidation.isFailure) {
      return dimensionValidation;
    }

    return const Success(null);
  }

  /// Compresses image data while maintaining quality.
  ///
  /// Applies compression based on:
  /// - Original file size
  /// - Image format
  /// - Target quality settings from AppConstants
  ///
  /// Returns compressed image data or original if compression fails.
  static Uint8List compressImage(Uint8List imageData) {
    try {
      // Decode the image
      final image = img.decodeImage(imageData);
      if (image == null) {
        return imageData; // Return original if decoding fails
      }

      // Calculate compression ratio based on file size
      final compressionRatio = _calculateCompressionRatio(imageData.length);
      
      // Resize if image is too large
      img.Image processedImage = image;
      if (image.width > AppConstants.maxImageWidth || 
          image.height > AppConstants.maxImageHeight) {
        processedImage = img.copyResize(
          image,
          width: math.min(image.width, AppConstants.maxImageWidth),
          height: math.min(image.height, AppConstants.maxImageHeight),
          interpolation: img.Interpolation.cubic,
        );
      }

      // Apply compression based on format
      final compressedData = img.encodeJpg(
        processedImage,
        quality: (AppConstants.jpegQuality * compressionRatio).round(),
      );

      // Only return compressed data if it's actually smaller
      return compressedData.length < imageData.length
          ? Uint8List.fromList(compressedData)
          : imageData;
    } catch (e) {
      // Return original data if compression fails
      return imageData;
    }
  }

  /// Strips EXIF data from image for privacy protection.
  ///
  /// Removes all metadata including:
  /// - Location data
  /// - Camera information
  /// - Timestamps
  /// - User comments
  ///
  /// Returns image data with EXIF data removed.
  static Uint8List stripExifData(Uint8List imageData) {
    try {
      // Decode the image
      final image = img.decodeImage(imageData);
      if (image == null) {
        return imageData; // Return original if decoding fails
      }

      // Re-encode the image without EXIF data
      // The img library automatically strips EXIF when re-encoding
      final cleanData = img.encodeJpg(image, quality: AppConstants.jpegQuality);
      
      return Uint8List.fromList(cleanData);
    } catch (e) {
      // Return original data if EXIF stripping fails
      return imageData;
    }
  }

  /// Performs comprehensive image processing including validation, compression, and EXIF stripping.
  ///
  /// This is the main entry point for processing images securely.
  /// Combines all security measures in the correct order.
  static Result<Uint8List> processImageSecurely(
    Uint8List imageData, {
    String? filename,
    bool compressImage = true,
    bool stripExif = true,
  }) {
    // First validate the image
    final validation = validateImage(imageData, filename: filename);
    if (validation.isFailure) {
      return Failure(validation.exceptionOrNull!);
    }

    Uint8List processedData = imageData;

    // Strip EXIF data if requested
    if (stripExif) {
      processedData = stripExifData(processedData);
    }

    // Compress image if requested
    if (compressImage) {
      processedData = compressImage(processedData);
    }

    return Success(processedData);
  }

  /// Validates filename for security concerns.
  static Result<void> _validateFilename(String filename) {
    if (filename.isEmpty) {
      return const Failure(
        ImageSelectionException.invalidFormat('Filename cannot be empty'),
      );
    }

    // Check for dangerous characters
    if (filename.contains('../') || filename.contains('..\\')) {
      return const Failure(
        ImageSelectionException.invalidFormat('Filename contains dangerous path traversal'),
      );
    }

    // Validate extension
    final extension = filename.toLowerCase().split('.').last;
    if (!AppConstants.supportedImageFormats.contains(extension)) {
      return Failure(
        ImageSelectionException.invalidFormat(
          'Unsupported image format: $extension',
        ),
      );
    }

    return const Success(null);
  }

  /// Enhanced malware scanning through header analysis.
  static Result<void> _performMalwareScanning(Uint8List imageData) {
    // Use existing SecurityUtils for basic file upload safety
    if (!SecurityUtils.isSafeFileUpload('image.jpg', imageData)) {
      return const Failure(
        ImageSelectionException.invalidFormat('File failed security validation'),
      );
    }

    // Additional checks for suspicious patterns
    if (_containsSuspiciousPatterns(imageData)) {
      return const Failure(
        ImageSelectionException.invalidFormat('File contains suspicious patterns'),
      );
    }

    return const Success(null);
  }

  /// Validates image dimensions to prevent resource exhaustion.
  static Result<void> _validateImageDimensions(Uint8List imageData) {
    try {
      final image = img.decodeImage(imageData);
      if (image == null) {
        return const Failure(
          ImageSelectionException.invalidFormat('Invalid image format'),
        );
      }

      // Check maximum resolution
      final totalPixels = image.width * image.height;
      if (totalPixels > AppConstants.maxImageResolution) {
        return const Failure(
          ImageSelectionException.fileTooLarge(
            'Image resolution too high: ${image.width}x${image.height} '
            '(max ${AppConstants.maxImageWidth}x${AppConstants.maxImageHeight})',
          ),
        );
      }

      // Check for suspicious dimensions (very wide/tall images)
      const maxAspectRatio = 20.0;
      final aspectRatio = math.max(image.width / image.height, image.height / image.width);
      if (aspectRatio > maxAspectRatio) {
        return Failure(
          ImageSelectionException.invalidFormat(
            'Image aspect ratio too extreme: ${aspectRatio.toStringAsFixed(1)}:1',
          ),
        );
      }

      return const Success(null);
    } catch (e) {
      return const Failure(
        ImageSelectionException.invalidFormat('Failed to validate image dimensions'),
      );
    }
  }

  /// Calculates compression ratio based on file size.
  static double _calculateCompressionRatio(int fileSize) {
    // More aggressive compression for larger files
    if (fileSize > 2 * 1024 * 1024) { // > 2MB
      return 0.7; // 70% of original quality
    } else if (fileSize > 1 * 1024 * 1024) { // > 1MB
      return 0.8; // 80% of original quality
    } else {
      return 1.0; // Full quality for smaller files
    }
  }

  /// Checks for suspicious patterns in image data.
  static bool _containsSuspiciousPatterns(Uint8List imageData) {
    // Check for embedded executable patterns
    final suspiciousPatterns = [
      [0x4D, 0x5A], // MZ (DOS/Windows executable)
      [0x50, 0x4B], // PK (ZIP archive)
      [0x7F, 0x45, 0x4C, 0x46], // ELF (Linux executable)
    ];

    for (final pattern in suspiciousPatterns) {
      if (_containsPattern(imageData, pattern)) {
        return true;
      }
    }

    return false;
  }

  /// Checks if image data contains a specific byte pattern.
  static bool _containsPattern(Uint8List data, List<int> pattern) {
    for (int i = 0; i <= data.length - pattern.length; i++) {
      bool found = true;
      for (int j = 0; j < pattern.length; j++) {
        if (data[i + j] != pattern[j]) {
          found = false;
          break;
        }
      }
      if (found) return true;
    }
    return false;
  }
}

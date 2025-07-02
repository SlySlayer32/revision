/// Constants for AI processing operations
///
/// Centralizes magic numbers and configuration values to improve maintainability
abstract class AIProcessingConstants {
  // Image size constraints
  static const int maxImageSizeMB = 10;
  static const int bytesPerMB = 1024 * 1024;
  static const int maxImageSizeBytes = maxImageSizeMB * bytesPerMB;

  // Logging and operation identification
  static const String operationName = 'GEMINI_PIPELINE_PROCESSING';

  // Validation constraints
  static const double minMarkedAreaSize = 0.01; // 1% of image
  static const double maxMarkedAreaSize = 0.9;  // 90% of image
  static const int maxMarkedAreasCount = 10;

  // HTTP status codes for error mapping
  static const int httpForbidden = 403;
  static const int httpNotFound = 404;
  static const int httpUnauthorized = 401;

  // Error message templates
  static const String imageTooLargeTemplate = 
      'Image too large: {size}MB (max {max}MB)';
  static const String imageEmptyMessage = 'Image data cannot be empty';
  static const String tooManyMarkedAreasTemplate = 
      'Too many marked areas: {count} (max {max})';
}

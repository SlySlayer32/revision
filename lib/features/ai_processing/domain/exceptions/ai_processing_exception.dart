/// Base exception for AI processing operations
///
/// Provides a common base for all AI-related exceptions with categorization
abstract class AIProcessingException implements Exception {
  const AIProcessingException(
    this.message, [
    this.category = ExceptionCategory.general,
  ]);

  final String message;
  final ExceptionCategory category;

  @override
  String toString() => 'AIProcessingException: $message';
}

/// Categories for different types of AI processing exceptions
enum ExceptionCategory {
  validation,
  network,
  apiLimit,
  authentication,
  modelError,
  general,
}

/// Exception thrown when image validation fails
class ImageValidationException extends AIProcessingException {
  const ImageValidationException(String message)
    : super(message, ExceptionCategory.validation);
}

/// Exception thrown when marked areas validation fails
class MarkedAreaValidationException extends AIProcessingException {
  const MarkedAreaValidationException(String message)
    : super(message, ExceptionCategory.validation);
}

/// Exception thrown when API quota is exceeded
class APIQuotaExceededException extends AIProcessingException {
  const APIQuotaExceededException(String message)
    : super(message, ExceptionCategory.apiLimit);
}

/// Exception thrown when API authentication fails
class APIAuthenticationException extends AIProcessingException {
  const APIAuthenticationException(String message)
    : super(message, ExceptionCategory.authentication);
}

/// Exception thrown when the AI model is not found or unavailable
class ModelNotFoundException extends AIProcessingException {
  const ModelNotFoundException(String message)
    : super(message, ExceptionCategory.modelError);
}

/// Exception thrown when API permissions are insufficient
class APIPermissionException extends AIProcessingException {
  const APIPermissionException(String message)
    : super(message, ExceptionCategory.authentication);
}

/// Exception thrown for general network-related issues
class NetworkException extends AIProcessingException {
  const NetworkException(String message)
    : super(message, ExceptionCategory.network);
}

/// Exception thrown when analysis validation fails
class AnalysisValidationException extends AIProcessingException {
  const AnalysisValidationException(String message)
    : super(message, ExceptionCategory.validation);
}

/// Exception thrown when analysis network operations fail
class AnalysisNetworkException extends AIProcessingException {
  const AnalysisNetworkException(String message)
    : super(message, ExceptionCategory.network);
}

/// Original exception from the current implementation for backward compatibility
class GeminiPipelineException extends AIProcessingException {
  const GeminiPipelineException(super.message);

  @override
  String toString() => 'GeminiPipelineException: $message';
}

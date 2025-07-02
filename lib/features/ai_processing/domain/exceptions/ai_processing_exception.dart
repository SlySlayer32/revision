/// Base exception for AI processing operations
///
/// Provides a common base for all AI-related exceptions with categorization
abstract class AIProcessingException implements Exception {
  const AIProcessingException(this.message, [this.category = ExceptionCategory.general]);
  
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
  const ImageValidationException(super.message) 
      : super(ExceptionCategory.validation);
}

/// Exception thrown when marked areas validation fails
class MarkedAreaValidationException extends AIProcessingException {
  const MarkedAreaValidationException(super.message) 
      : super(ExceptionCategory.validation);
}

/// Exception thrown when API quota is exceeded
class APIQuotaExceededException extends AIProcessingException {
  const APIQuotaExceededException(super.message) 
      : super(ExceptionCategory.apiLimit);
}

/// Exception thrown when API authentication fails
class APIAuthenticationException extends AIProcessingException {
  const APIAuthenticationException(super.message) 
      : super(ExceptionCategory.authentication);
}

/// Exception thrown when the AI model is not found or unavailable
class ModelNotFoundException extends AIProcessingException {
  const ModelNotFoundException(super.message) 
      : super(ExceptionCategory.modelError);
}

/// Exception thrown when API permissions are insufficient
class APIPermissionException extends AIProcessingException {
  const APIPermissionException(super.message) 
      : super(ExceptionCategory.authentication);
}

/// Exception thrown for general network-related issues
class NetworkException extends AIProcessingException {
  const NetworkException(super.message) 
      : super(ExceptionCategory.network);
}

/// Original exception from the current implementation for backward compatibility
class GeminiPipelineException extends AIProcessingException {
  const GeminiPipelineException(super.message);

  @override
  String toString() => 'GeminiPipelineException: $message';
}

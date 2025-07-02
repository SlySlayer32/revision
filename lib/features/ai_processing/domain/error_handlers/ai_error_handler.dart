import 'package:revision/features/ai_processing/domain/constants/ai_processing_constants.dart';
import 'package:revision/features/ai_processing/domain/exceptions/ai_processing_exception.dart';

/// Handles error mapping and classification for AI processing operations
///
/// Centralizes error handling logic to improve maintainability and consistency
class AIErrorHandler {
  /// Maps generic exceptions to domain-specific exceptions
  ///
  /// Analyzes error messages and types to provide appropriate
  /// domain exceptions with user-friendly messages
  static AIProcessingException mapException(Object error) {
    final errorString = error.toString().toLowerCase();
    
    // HTTP status code based mapping
    if (_containsHttpStatus(errorString, AIProcessingConstants.httpForbidden) ||
        errorString.contains('forbidden')) {
      return const APIPermissionException(
        'Firebase AI access denied. Check project billing and API permissions.',
      );
    }
    
    if (_containsHttpStatus(errorString, AIProcessingConstants.httpNotFound) ||
        errorString.contains('not found')) {
      return const ModelNotFoundException(
        'Gemini model not found. The model might not be available in your region.',
      );
    }
    
    if (_containsHttpStatus(errorString, AIProcessingConstants.httpUnauthorized) ||
        errorString.contains('authentication') ||
        errorString.contains('unauthorized')) {
      return const APIAuthenticationException(
        'Firebase AI authentication failed. Check your Firebase project configuration.',
      );
    }
    
    // Quota and limit detection
    if (errorString.contains('quota') ||
        errorString.contains('limit') ||
        errorString.contains('rate limit') ||
        errorString.contains('too many requests')) {
      return const APIQuotaExceededException(
        'Gemini API quota exceeded. Check your Firebase billing and usage limits.',
      );
    }
    
    // Network-related errors
    if (errorString.contains('timeout') ||
        errorString.contains('connection') ||
        errorString.contains('network') ||
        errorString.contains('socket')) {
      return NetworkException(
        'Network error occurred: ${_extractRelevantErrorMessage(errorString)}',
      );
    }
    
    // Model-specific errors
    if (errorString.contains('model') ||
        errorString.contains('invalid request') ||
        errorString.contains('bad request')) {
      return ModelNotFoundException(
        'Model error: ${_extractRelevantErrorMessage(errorString)}',
      );
    }
    
    // Validation errors (if they escape the validators)
    if (errorString.contains('validation') ||
        errorString.contains('invalid') ||
        errorString.contains('malformed')) {
      return ImageValidationException(
        'Validation error: ${_extractRelevantErrorMessage(errorString)}',
      );
    }
    
    // Default mapping for unknown errors
    return GeminiPipelineException(
      'Unexpected error occurred: ${_extractRelevantErrorMessage(errorString)}',
    );
  }

  /// Checks if error string contains a specific HTTP status code
  static bool _containsHttpStatus(String errorString, int statusCode) {
    return errorString.contains(statusCode.toString()) ||
           errorString.contains('$statusCode ') ||
           errorString.contains(' $statusCode');
  }

  /// Extracts relevant parts of error message for user display
  static String _extractRelevantErrorMessage(String errorString) {
    // Remove common prefixes and stack trace information
    final cleanedMessage = errorString
        .replaceAll(RegExp(r'exception:\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'error:\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'failure:\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'#\d+.*'), '') // Remove stack trace lines
        .trim();

    // Limit message length and take first sentence
    final sentences = cleanedMessage.split('.');
    if (sentences.isNotEmpty && sentences.first.trim().isNotEmpty) {
      return sentences.first.trim().length > 200
          ? '${sentences.first.trim().substring(0, 200)}...'
          : sentences.first.trim();
    }

    return cleanedMessage.length > 200
        ? '${cleanedMessage.substring(0, 200)}...'
        : cleanedMessage;
  }

  /// Checks if an exception is retryable based on its type
  static bool isRetryableException(AIProcessingException exception) {
    switch (exception.category) {
      case ExceptionCategory.network:
      case ExceptionCategory.apiLimit:
        return true;
      case ExceptionCategory.validation:
      case ExceptionCategory.authentication:
      case ExceptionCategory.modelError:
      case ExceptionCategory.general:
        return false;
    }
  }

  /// Gets recommended retry delay for retryable exceptions
  static Duration getRetryDelay(AIProcessingException exception, int attemptNumber) {
    if (!isRetryableException(exception)) {
      return Duration.zero;
    }

    // Exponential backoff with jitter
    final baseDelay = Duration(seconds: 2 << attemptNumber); // 2, 4, 8, 16 seconds
    final jitter = Duration(milliseconds: (baseDelay.inMilliseconds * 0.1).round());
    
    return baseDelay + jitter;
  }
}

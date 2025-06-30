import 'package:revision/core/error/exceptions.dart';
import 'error_enums.dart';

/// Handles error classification and analysis
class ErrorClassifier {
  const ErrorClassifier();

  /// Categorize an error into its appropriate category
  ErrorCategory categorizeError(Object error) {
    if (error is NetworkException) return ErrorCategory.network;
    if (error is AuthenticationException) return ErrorCategory.authentication;
    if (error is AIServiceException || error is AIProcessingException) {
      return ErrorCategory.aiService;
    }
    if (error is ValidationException) return ErrorCategory.validation;
    if (error is PermissionException) return ErrorCategory.permission;
    if (error is CircuitBreakerOpenException) return ErrorCategory.circuitBreaker;
    if (error is StorageException) return ErrorCategory.storage;
    if (error is FirebaseInitializationException || error is FirebaseAIException) {
      return ErrorCategory.firebase;
    }
    return ErrorCategory.unknown;
  }

  /// Determine if an error is recoverable by the user
  bool isUserRecoverable(Object error) {
    switch (categorizeError(error)) {
      case ErrorCategory.validation:
      case ErrorCategory.network:
      case ErrorCategory.circuitBreaker:
      case ErrorCategory.permission:
        return true;
      case ErrorCategory.authentication:
      case ErrorCategory.aiService:
      case ErrorCategory.storage:
      case ErrorCategory.firebase:
      case ErrorCategory.unknown:
        return false;
    }
  }

  /// Get the severity level of an error
  ErrorSeverity getErrorSeverity(Object error) {
    if (error is CircuitBreakerOpenException) return ErrorSeverity.high;
    if (error is FirebaseInitializationException) return ErrorSeverity.critical;
    
    switch (categorizeError(error)) {
      case ErrorCategory.authentication:
      case ErrorCategory.network:
      case ErrorCategory.aiService:
        return ErrorSeverity.medium;
      case ErrorCategory.validation:
        return ErrorSeverity.low;
      case ErrorCategory.permission:
      case ErrorCategory.circuitBreaker:
        return ErrorSeverity.high;
      case ErrorCategory.storage:
      case ErrorCategory.firebase:
        return ErrorSeverity.critical;
      case ErrorCategory.unknown:
        return ErrorSeverity.unknown;
    }
  }

  /// Generate a unique key for error grouping
  String generateErrorKey(Object error) {
    if (error is AppException) {
      return '${error.runtimeType}:${error.code ?? "no_code"}';
    }
    return error.runtimeType.toString();
  }

  /// Check if error should trigger immediate alert
  bool shouldTriggerImmediateAlert(Object error) {
    final severity = getErrorSeverity(error);
    return severity == ErrorSeverity.critical;
  }

  /// Get human-readable error description
  String getErrorDescription(Object error) {
    final category = categorizeError(error);
    final severity = getErrorSeverity(error);
    
    return 'Error in ${category.value} (${severity.value}): ${error.runtimeType}';
  }
}

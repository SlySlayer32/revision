/// Base exception class for the application following VGV patterns
abstract class AppException implements Exception {
  const AppException(this.message, [this.code]);

  final String message;
  final String? code;

  @override
  String toString() =>
      'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException(super.message, [super.code]);

  @override
  String toString() => 'NetworkException: $message';
}

/// Authentication-related exceptions
class AuthenticationException extends AppException {
  const AuthenticationException(super.message, [super.code]);

  @override
  String toString() => 'AuthenticationException: $message';
}

/// AI service-related exceptions
class AIServiceException extends AppException {
  const AIServiceException(super.message, [super.code]);

  @override
  String toString() => 'AIServiceException: $message';
}

/// Advanced AI processing exceptions
class AIProcessingException extends AppException {
  const AIProcessingException(super.message, [super.code]);

  @override
  String toString() => 'AIProcessingException: $message';
}

/// Image processing-related exceptions
class ImageProcessingException extends AppException {
  const ImageProcessingException(super.message, [super.code]);

  @override
  String toString() => 'ImageProcessingException: $message';
}

/// Storage-related exceptions
class StorageException extends AppException {
  const StorageException(super.message, [super.code]);

  @override
  String toString() => 'StorageException: $message';
}

/// Firebase-specific initialization exceptions
class FirebaseInitializationException extends AppException {
  const FirebaseInitializationException(super.message, [super.code]);

  @override
  String toString() => 'FirebaseInitializationException: $message';
}

/// Firebase AI Logic-specific exceptions
class FirebaseAIException extends AppException {
  const FirebaseAIException(super.message, [super.code]);

  @override
  String toString() => 'FirebaseAIException: $message';
}

/// Quota exceeded exceptions for AI services
class QuotaExceededException extends AppException {
  const QuotaExceededException(super.message, [super.code]);

  @override
  String toString() => 'QuotaExceededException: $message';
}

/// Circuit breaker open exception
class CircuitBreakerOpenException extends AppException {
  const CircuitBreakerOpenException([
    super.message = 'Circuit breaker is open',
    super.code,
  ]);

  @override
  String toString() => 'CircuitBreakerOpenException: $message';
}

/// Validation-related exceptions
class ValidationException extends AppException {
  const ValidationException(super.message, [super.code]);

  @override
  String toString() => 'ValidationException: $message';
}

/// Permission-related exceptions
class PermissionException extends AppException {
  const PermissionException(super.message, [super.code]);

  @override
  String toString() => 'PermissionException: $message';
}

/// Cache-related exceptions
class CacheException extends AppException {
  const CacheException(super.message, [super.code]);

  @override
  String toString() => 'CacheException: $message';
}

/// Server-related exceptions (Firestore, Firebase functions, etc.)
class ServerException extends AppException {
  const ServerException(super.message, [super.code]);

  @override
  String toString() => 'ServerException: $message';
}

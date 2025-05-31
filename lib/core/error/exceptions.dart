/// Base exception class for the application following VGV patterns
abstract class AppException implements Exception {
  const AppException(this.message, [this.code]);

  final String message;
  final String? code;

  @override
  String toString() => 'AppException: $message';
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

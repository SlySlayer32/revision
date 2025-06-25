import 'package:equatable/equatable.dart';

/// Base exception for AI processing operations
abstract class AiProcessingException extends Equatable implements Exception {
  const AiProcessingException(this.message, [this.details]);

  /// Human-readable error message
  final String message;

  /// Additional error details for debugging
  final String? details;

  @override
  List<Object?> get props => [message, details];

  @override
  String toString() =>
      'AiProcessingException: $message${details != null ? ' ($details)' : ''}';
}

/// Exception thrown when AI analysis fails
class AiAnalysisException extends AiProcessingException {
  const AiAnalysisException(super.message, [super.details]);

  @override
  String toString() =>
      'AiAnalysisException: $message${details != null ? ' ($details)' : ''}';
}

/// Exception thrown when AI editing fails
class AiEditingException extends AiProcessingException {
  const AiEditingException(super.message, [super.details]);

  @override
  String toString() =>
      'AiEditingException: $message${details != null ? ' ($details)' : ''}';
}

/// Exception thrown when network operations fail
class AiNetworkException extends AiProcessingException {
  const AiNetworkException(super.message, [super.details]);

  @override
  String toString() =>
      'AiNetworkException: $message${details != null ? ' ($details)' : ''}';
}

/// Exception thrown when input validation fails
class AiValidationException extends AiProcessingException {
  const AiValidationException(super.message, [super.details]);

  @override
  String toString() =>
      'AiValidationException: $message${details != null ? ' ($details)' : ''}';
}

/// Exception thrown when API quota is exceeded
class AiQuotaExceededException extends AiProcessingException {
  const AiQuotaExceededException(super.message, [super.details]);

  @override
  String toString() =>
      'AiQuotaExceededException: $message${details != null ? ' ($details)' : ''}';
}

/// Exception thrown when content is flagged by safety filters
class AiSafetyException extends AiProcessingException {
  const AiSafetyException(super.message, [super.details]);

  @override
  String toString() =>
      'AiSafetyException: $message${details != null ? ' ($details)' : ''}';
}

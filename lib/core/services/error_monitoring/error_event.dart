import 'error_enums.dart';

/// Immutable error event data class with rich metadata
class ErrorEvent {
  const ErrorEvent({
    required this.error,
    required this.stackTrace,
    required this.context,
    required this.timestamp,
    required this.metadata,
    required this.category,
    required this.severity,
    required this.isUserRecoverable,
    required this.errorKey,
  });

  final Object error;
  final StackTrace stackTrace;
  final String context;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final ErrorCategory category;
  final ErrorSeverity severity;
  final bool isUserRecoverable;
  final String errorKey;

  /// Create a copy with updated metadata
  ErrorEvent copyWith({
    Object? error,
    StackTrace? stackTrace,
    String? context,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    ErrorCategory? category,
    ErrorSeverity? severity,
    bool? isUserRecoverable,
    String? errorKey,
  }) {
    return ErrorEvent(
      error: error ?? this.error,
      stackTrace: stackTrace ?? this.stackTrace,
      context: context ?? this.context,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      isUserRecoverable: isUserRecoverable ?? this.isUserRecoverable,
      errorKey: errorKey ?? this.errorKey,
    );
  }

  /// Convert to a map for serialization
  Map<String, dynamic> toMap() {
    return {
      'error_type': error.runtimeType.toString(),
      'context': context,
      'timestamp': timestamp.toIso8601String(),
      'category': category.value,
      'severity': severity.value,
      'is_user_recoverable': isUserRecoverable,
      'error_key': errorKey,
      'metadata': metadata,
    };
  }

  /// Check if this error occurred recently
  bool isRecent(Duration window) {
    final cutoff = DateTime.now().subtract(window);
    return timestamp.isAfter(cutoff);
  }

  /// Get age of this error
  Duration get age => DateTime.now().difference(timestamp);

  @override
  String toString() {
    return 'ErrorEvent(${category.value}/${severity.value}): $error at $context';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ErrorEvent &&
        other.errorKey == errorKey &&
        other.timestamp == timestamp &&
        other.context == context;
  }

  @override
  int get hashCode => Object.hash(errorKey, timestamp, context);
}

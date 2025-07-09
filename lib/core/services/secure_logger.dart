import 'dart:convert';
import 'dart:developer' as developer;

/// Secure logging utility that prevents sensitive information exposure.
class SecureLogger {
  static const List<String> _sensitivePatterns = [
    'api_key',
    'apikey',
    'key=',
    'token',
    'password',
    'secret',
    'authorization',
    'bearer',
    'AIza',
  ];

  static final List<RegExp> _sensitiveRegexes = [
    RegExp(r'AIza[A-Za-z0-9_-]{35}'), // Google API keys
    RegExp(r'(?i)api[_-]?key\s*[:=]\s*([\w-]+)'),
    RegExp(r'(?i)token\s*[:=]\s*([\w-]+)'),
    RegExp(r'[Bb]earer\s+[A-Za-z0-9._-]+'),
    RegExp(r'[?&]key=[^&\s]+'),
  ];

  /// Log message with automatic sensitive data masking.
  static void log(
    String message, {
    String? operation,
    Map<String, dynamic>? context,
    bool isError = false,
  }) {
    final sanitizedMessage = _sanitizeMessage(message);
    final sanitizedContext = context != null ? _sanitizeContext(context) : null;

    final logEntry = _buildLogEntry(
      sanitizedMessage,
      operation: operation,
      context: sanitizedContext,
      isError: isError,
    );

    // Use dart:developer log for consistent logging
    developer.log(
      logEntry,
      name: isError ? 'GEMINI_ERROR' : 'GEMINI',
      level: isError ? 1000 : 800,
    );
  }

  /// Log error with secure error details.
  static void logError(
    String message, {
    String? operation,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    final secureContext = <String, dynamic>{
      if (context != null) ...context,
      if (error != null) 'errorType': error.runtimeType.toString(),
      if (error != null) 'errorMessage': _sanitizeMessage(error.toString()),
    };

    log(
      message,
      operation: operation,
      context: secureContext,
      isError: true,
    );

    // Log stack trace separately if provided
    if (stackTrace != null) {
      developer.log('Stack trace: ${stackTrace.toString()}', name: 'GEMINI_STACK');
    }
  }

  /// Log API operation with secure details.
  static void logApiOperation(
    String operation, {
    required String method,
    required String endpoint,
    int? statusCode,
    int? requestSizeBytes,
    int? responseSizeBytes,
    int? durationMs,
    Map<String, dynamic>? metadata,
  }) {
    final context = {
      'method': method,
      'endpoint': _sanitizeUrl(endpoint),
      if (statusCode != null) 'statusCode': statusCode,
      if (requestSizeBytes != null) 'requestSize': requestSizeBytes,
      if (responseSizeBytes != null) 'responseSize': responseSizeBytes,
      if (durationMs != null) 'duration': durationMs,
      if (metadata != null) ...metadata,
    };

    log(
      'API $operation completed',
      operation: operation,
      context: context,
    );
  }

  /// Log audit event for security monitoring.
  static void logAuditEvent(
    String event, {
    required String operation,
    Map<String, dynamic>? details,
  }) {
    final auditContext = {
      'timestamp': DateTime.now().toIso8601String(),
      'event': event,
      'operation': operation,
      if (details != null) ...details,
    };

    log(
      'AUDIT: $event',
      operation: 'SECURITY_AUDIT',
      context: auditContext,
    );
  }

  /// Sanitize message to remove sensitive information.
  static String _sanitizeMessage(String message) {
    String sanitized = message;
    for (final regex in _sensitiveRegexes) {
      sanitized = sanitized.replaceAll(regex, '[SENSITIVE]');
    }
    // Also mask patterns not caught by regex
    for (final pattern in _sensitivePatterns) {
      sanitized = sanitized.replaceAll(
        RegExp('$pattern[=:]?\\s*[^\\s&]+', caseSensitive: false),
        '$pattern=HIDDEN',
      );
    }
    return sanitized;
  }

  /// Sanitize URL to hide sensitive query parameters.
  static String _sanitizeUrl(String url) {
    return url.replaceAll(RegExp(r'[?&]key=[^&\s]+'), '?key=HIDDEN');
  }

  /// Sanitize context map to remove sensitive values.
  static Map<String, dynamic> _sanitizeContext(Map<String, dynamic> context) {
    final sanitized = <String, dynamic>{};
    for (final entry in context.entries) {
      final key = entry.key.toLowerCase();

      if (_sensitivePatterns.any((pattern) => key.contains(pattern))) {
        sanitized[entry.key] = 'HIDDEN';
      } else if (entry.value is String) {
        sanitized[entry.key] = _sanitizeMessage(entry.value as String);
      } else if (entry.value is Map<String, dynamic>) {
        sanitized[entry.key] = _sanitizeContext(entry.value as Map<String, dynamic>);
      } else {
        sanitized[entry.key] = entry.value;
      }
    }
    return sanitized;
  }

  /// Build structured log entry.
  static String _buildLogEntry(
    String message, {
    String? operation,
    Map<String, dynamic>? context,
    bool isError = false,
  }) {
    final entry = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'message': message,
      if (operation != null) 'operation': operation,
      if (context != null && context.isNotEmpty) 'context': context,
      'level': isError ? 'ERROR' : 'INFO',
    };
    return jsonEncode(entry);
  }
}
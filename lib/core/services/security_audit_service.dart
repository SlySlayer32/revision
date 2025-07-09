import 'dart:convert';
import 'package:revision/core/services/secure_logger.dart';

/// Security audit service for tracking security-sensitive operations.
class SecurityAuditService {
  static final SecurityAuditService _instance = SecurityAuditService._internal();
  static SecurityAuditService get instance => _instance;

  SecurityAuditService._internal();

  /// Log API key validation event.
  static void logApiKeyValidation({
    required bool success,
    String? reason,
    Map<String, dynamic>? metadata,
  }) {
    SecureLogger.logAuditEvent(
      'API key validation',
      operation: 'API_KEY_VALIDATION',
      details: {
        'success': success,
        'timestamp': DateTime.now().toIso8601String(),
        if (reason != null) 'reason': reason,
        if (metadata != null) ...metadata,
      },
    );
  }

  /// Log API request attempt.
  static void logApiRequest({
    required String operation,
    required String endpoint,
    required String method,
    Map<String, dynamic>? metadata,
  }) {
    SecureLogger.logAuditEvent(
      'API request initiated',
      operation: operation,
      details: {
        'endpoint': _sanitizeEndpoint(endpoint),
        'method': method,
        'timestamp': DateTime.now().toIso8601String(),
        if (metadata != null) ...metadata,
      },
    );
  }

  /// Log API response received.
  static void logApiResponse({
    required String operation,
    required int statusCode,
    required int responseSize,
    required int duration,
    Map<String, dynamic>? metadata,
  }) {
    SecureLogger.logAuditEvent(
      'API response received',
      operation: operation,
      details: {
        'statusCode': statusCode,
        'responseSize': responseSize,
        'duration': duration,
        'timestamp': DateTime.now().toIso8601String(),
        if (metadata != null) ...metadata,
      },
    );
  }

  /// Log rate limiting event.
  static void logRateLimit({
    required String operation,
    required bool blocked,
    Map<String, dynamic>? metadata,
  }) {
    SecureLogger.logAuditEvent(
      'Rate limit check',
      operation: operation,
      details: {
        'blocked': blocked,
        'timestamp': DateTime.now().toIso8601String(),
        if (metadata != null) ...metadata,
      },
    );
  }

  /// Log circuit breaker event.
  static void logCircuitBreaker({
    required String service,
    required String state,
    required String event,
    Map<String, dynamic>? metadata,
  }) {
    SecureLogger.logAuditEvent(
      'Circuit breaker event',
      operation: 'CIRCUIT_BREAKER',
      details: {
        'service': service,
        'state': state,
        'event': event,
        'timestamp': DateTime.now().toIso8601String(),
        if (metadata != null) ...metadata,
      },
    );
  }

  /// Log security exception.
  static void logSecurityException({
    required String operation,
    required String exception,
    String? message,
    Map<String, dynamic>? metadata,
  }) {
    SecureLogger.logAuditEvent(
      'Security exception',
      operation: operation,
      details: {
        'exception': exception,
        'severity': 'HIGH',
        'timestamp': DateTime.now().toIso8601String(),
        if (message != null) 'message': message,
        if (metadata != null) ...metadata,
      },
    );
  }

  /// Log service initialization.
  static void logServiceInitialization({
    required String service,
    required bool success,
    String? version,
    Map<String, dynamic>? metadata,
  }) {
    SecureLogger.logAuditEvent(
      'Service initialization',
      operation: 'SERVICE_INIT',
      details: {
        'service': service,
        'success': success,
        'timestamp': DateTime.now().toIso8601String(),
        if (version != null) 'version': version,
        if (metadata != null) ...metadata,
      },
    );
  }

  /// Log configuration change.
  static void logConfigurationChange({
    required String component,
    required String property,
    String? oldValue,
    String? newValue,
    Map<String, dynamic>? metadata,
  }) {
    SecureLogger.logAuditEvent(
      'Configuration change',
      operation: 'CONFIG_CHANGE',
      details: {
        'component': component,
        'property': property,
        'timestamp': DateTime.now().toIso8601String(),
        if (oldValue != null) 'oldValue': _sanitizeValue(oldValue),
        if (newValue != null) 'newValue': _sanitizeValue(newValue),
        if (metadata != null) ...metadata,
      },
    );
  }

  /// Log authentication event.
  static void logAuthentication({
    required String operation,
    required bool success,
    String? userId,
    String? reason,
    Map<String, dynamic>? metadata,
  }) {
    SecureLogger.logAuditEvent(
      'Authentication event',
      operation: operation,
      details: {
        'success': success,
        'timestamp': DateTime.now().toIso8601String(),
        if (userId != null) 'userId': _hashUserId(userId),
        if (reason != null) 'reason': reason,
        if (metadata != null) ...metadata,
      },
    );
  }

  /// Log data processing event.
  static void logDataProcessing({
    required String operation,
    required String dataType,
    required int dataSize,
    Map<String, dynamic>? metadata,
  }) {
    SecureLogger.logAuditEvent(
      'Data processing',
      operation: operation,
      details: {
        'dataType': dataType,
        'dataSize': dataSize,
        'timestamp': DateTime.now().toIso8601String(),
        if (metadata != null) ...metadata,
      },
    );
  }

  /// Sanitize endpoint for logging.
  static String _sanitizeEndpoint(String endpoint) {
    return endpoint.replaceAll(RegExp(r'[?&]key=[^&\s]+'), '?key=HIDDEN');
  }

  /// Sanitize configuration value.
  static String _sanitizeValue(String value) {
    if (value.contains('key') || value.contains('token') || value.contains('secret')) {
      return 'HIDDEN';
    }
    return value.length > 100 ? '${value.substring(0, 100)}...' : value;
  }

  /// Hash user ID for privacy.
  static String _hashUserId(String userId) {
    final hash = userId.hashCode.abs().toString();
    return 'user_${hash.substring(0, 8)}';
  }
}
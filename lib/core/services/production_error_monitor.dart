import 'dart:async';
import 'dart:collection';

import 'package:revision/core/error/exceptions.dart';
import 'package:revision/core/utils/enhanced_logger.dart';

/// Legacy production error monitoring service
/// @deprecated Use ProductionErrorMonitorV2 for new implementations
class ProductionErrorMonitor {
  ProductionErrorMonitor._();
  static final ProductionErrorMonitor _instance = ProductionErrorMonitor._();
  static ProductionErrorMonitor get instance => _instance;

  final Queue<ErrorEvent> _errorHistory = Queue();
  final Map<String, int> _errorCounts = {};
  final Map<String, DateTime> _lastErrorTimes = {};

  // Configuration
  static const int _maxHistorySize = 1000;
  static const int _criticalErrorThreshold = 5;
  static const Duration _errorWindowDuration = Duration(minutes: 5);
  static const Duration _circuitBreakerCooldown = Duration(minutes: 15);

  Timer? _alertTimer;
  bool _isAlertActive = false;

  /// Record an error event
  void recordError({
    required Object error,
    required StackTrace stackTrace,
    required String context,
    Map<String, dynamic>? metadata,
  }) {
    final errorEvent = ErrorEvent(
      error: error,
      stackTrace: stackTrace,
      context: context,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );

    _addToHistory(errorEvent);
    _updateErrorCounts(errorEvent);
    _checkForCriticalPatterns(errorEvent);
    _logErrorMetrics(errorEvent);
  }

  void _addToHistory(ErrorEvent event) {
    _errorHistory.addLast(event);

    // Keep history size manageable
    while (_errorHistory.length > _maxHistorySize) {
      _errorHistory.removeFirst();
    }
  }

  void _updateErrorCounts(ErrorEvent event) {
    final errorKey = _getErrorKey(event.error);
    _errorCounts[errorKey] = (_errorCounts[errorKey] ?? 0) + 1;
    _lastErrorTimes[errorKey] = event.timestamp;
  }

  void _checkForCriticalPatterns(ErrorEvent event) {
    final errorKey = _getErrorKey(event.error);
    final errorCount = _errorCounts[errorKey] ?? 0;

    // Check for error frequency patterns
    if (errorCount >= _criticalErrorThreshold) {
      final lastErrorTime = _lastErrorTimes[errorKey];
      if (lastErrorTime != null) {
        final timeSinceFirst = event.timestamp.difference(lastErrorTime);

        if (timeSinceFirst <= _errorWindowDuration) {
          _triggerCriticalAlert(errorKey, errorCount, event);
        }
      }
    }

    // Check for cascading failures
    _detectCascadingFailures();
  }

  void _detectCascadingFailures() {
    final recentErrors = _getRecentErrors(const Duration(minutes: 2));
    final uniqueErrorTypes = recentErrors
        .map((e) => _getErrorKey(e.error))
        .toSet();

    if (uniqueErrorTypes.length >= 3 && recentErrors.length >= 8) {
      logger.error(
        '🚨 CASCADING FAILURE DETECTED: ${uniqueErrorTypes.length} error types, ${recentErrors.length} errors in 2 minutes',
        operation: 'CASCADING_FAILURE',
      );
    }
  }

  void _triggerCriticalAlert(String errorKey, int count, ErrorEvent event) {
    if (_isAlertActive) return;

    _isAlertActive = true;
    logger.error(
      '🚨 CRITICAL ERROR PATTERN: $errorKey occurred $count times in ${_errorWindowDuration.inMinutes} minutes',
      operation: 'CRITICAL_ALERT',
      error: event.error,
      stackTrace: event.stackTrace,
    );

    // Auto-reset alert after cooldown
    _alertTimer?.cancel();
    _alertTimer = Timer(_circuitBreakerCooldown, () {
      _isAlertActive = false;
      logger.info('Critical error alert reset', operation: 'ALERT_RESET');
    });
  }

  void _logErrorMetrics(ErrorEvent event) {
    final errorCategory = _categorizeError(event.error);
    final metadata = {
      'error_category': errorCategory,
      'error_type': event.error.runtimeType.toString(),
      'context': event.context,
      'is_user_recoverable': _isUserRecoverable(event.error),
      'severity': _getErrorSeverity(event.error),
      ...event.metadata,
    };

    logger.error(
      'Error recorded: ${event.error}',
      operation: 'ERROR_MONITORING',
      error: event.error,
      stackTrace: event.stackTrace,
      context: metadata,
    );
  }

  String _getErrorKey(Object error) {
    if (error is AppException) {
      return '${error.runtimeType}:${error.code ?? "no_code"}';
    }
    return error.runtimeType.toString();
  }

  String _categorizeError(Object error) {
    if (error is NetworkException) return 'network';
    if (error is AuthenticationException) return 'authentication';
    if (error is AIServiceException || error is AIProcessingException)
      return 'ai_service';
    if (error is ValidationException) return 'validation';
    if (error is PermissionException) return 'permission';
    if (error is CircuitBreakerOpenException) return 'circuit_breaker';
    if (error is StorageException) return 'storage';
    if (error is FirebaseInitializationException ||
        error is FirebaseAIException)
      return 'firebase';
    return 'unknown';
  }

  bool _isUserRecoverable(Object error) {
    if (error is ValidationException) return true;
    if (error is NetworkException) return true;
    if (error is CircuitBreakerOpenException) return true;
    if (error is PermissionException) return true;
    return false;
  }

  String _getErrorSeverity(Object error) {
    if (error is CircuitBreakerOpenException) return 'high';
    if (error is FirebaseInitializationException) return 'critical';
    if (error is AuthenticationException) return 'medium';
    if (error is ValidationException) return 'low';
    if (error is NetworkException) return 'medium';
    if (error is AIServiceException) return 'medium';
    return 'unknown';
  }

  /// Get recent errors within a time window
  List<ErrorEvent> _getRecentErrors(Duration timeWindow) {
    final cutoff = DateTime.now().subtract(timeWindow);
    return _errorHistory
        .where((event) => event.timestamp.isAfter(cutoff))
        .toList();
  }

  /// Get error statistics
  Map<String, dynamic> getErrorStats() {
    final now = DateTime.now();
    final last24h = _getRecentErrors(const Duration(hours: 24));
    final lastHour = _getRecentErrors(const Duration(hours: 1));

    final errorsByCategory = <String, int>{};
    for (final event in last24h) {
      final category = _categorizeError(event.error);
      errorsByCategory[category] = (errorsByCategory[category] ?? 0) + 1;
    }

    return {
      'total_errors_24h': last24h.length,
      'total_errors_1h': lastHour.length,
      'errors_by_category': errorsByCategory,
      'unique_error_types': _errorCounts.length,
      'most_frequent_errors': _getMostFrequentErrors(),
      'is_alert_active': _isAlertActive,
      'last_alert_time': _alertTimer != null ? now.toIso8601String() : null,
    };
  }

  List<Map<String, dynamic>> _getMostFrequentErrors() {
    final sorted = _errorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted
        .take(5)
        .map(
          (entry) => {
            'error_key': entry.key,
            'count': entry.value,
            'last_occurrence': _lastErrorTimes[entry.key]?.toIso8601String(),
          },
        )
        .toList();
  }

  /// Check if system is in a healthy state
  bool isSystemHealthy() {
    final recentErrors = _getRecentErrors(const Duration(minutes: 5));
    final criticalErrors = recentErrors
        .where((e) => _getErrorSeverity(e.error) == 'critical')
        .length;

    return !_isAlertActive && criticalErrors == 0 && recentErrors.length < 10;
  }

  /// Get health score (0-100)
  int getHealthScore() {
    final recentErrors = _getRecentErrors(const Duration(hours: 1));

    if (_isAlertActive) return 0;
    if (recentErrors.isEmpty) return 100;

    final maxErrors = 20;
    final score =
        ((maxErrors - recentErrors.length.clamp(0, maxErrors)) /
                maxErrors *
                100)
            .round();
    return score.clamp(0, 100);
  }

  /// Reset error monitoring state
  void reset() {
    _errorHistory.clear();
    _errorCounts.clear();
    _lastErrorTimes.clear();
    _alertTimer?.cancel();
    _alertTimer = null;
    _isAlertActive = false;

    logger.info('Error monitoring state reset', operation: 'MONITOR_RESET');
  }

  /// Dispose resources
  void dispose() {
    _alertTimer?.cancel();
  }
}

/// Error event data class
class ErrorEvent {
  const ErrorEvent({
    required this.error,
    required this.stackTrace,
    required this.context,
    required this.timestamp,
    required this.metadata,
  });

  final Object error;
  final StackTrace stackTrace;
  final String context;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
}

/// Extension to easily record errors
extension ErrorRecording on Object {
  void recordError(
    String context, {
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    ProductionErrorMonitor.instance.recordError(
      error: this,
      stackTrace: stackTrace ?? StackTrace.current,
      context: context,
      metadata: metadata,
    );
  }
}

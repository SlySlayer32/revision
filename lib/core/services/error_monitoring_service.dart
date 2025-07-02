import 'dart:developer';
import 'dart:convert';

import 'package:revision/core/services/ai_error_handler.dart';

/// Comprehensive error monitoring and diagnostics system
/// Tracks AI errors, performance metrics, and system health
class ErrorMonitoringService {
  static final ErrorMonitoringService _instance =
      ErrorMonitoringService._internal();
  factory ErrorMonitoringService() => _instance;
  ErrorMonitoringService._internal();

  // Error tracking
  final List<ErrorReport> _errorHistory = [];
  final Map<String, int> _errorCounts = {};
  final Map<String, Duration> _averageResponseTimes = {};
  final Map<String, DateTime> _lastErrorTimes = {};

  // Performance metrics
  final Map<String, List<Duration>> _responseTimeHistory = {};
  final Map<String, double> _successRates = {};

  // System health
  bool _isHealthy = true;
  DateTime _lastHealthCheck = DateTime.now();

  /// Report an error from AI operations
  void reportError(
    String operation,
    dynamic error, {
    StackTrace? stackTrace,
    Duration? responseTime,
    Map<String, dynamic>? context,
  }) {
    final errorReport = ErrorReport(
      operation: operation,
      error: error.toString(),
      stackTrace: stackTrace?.toString(),
      timestamp: DateTime.now(),
      responseTime: responseTime,
      context: context ?? {},
    );

    _errorHistory.add(errorReport);
    _errorCounts[operation] = (_errorCounts[operation] ?? 0) + 1;
    _lastErrorTimes[operation] = DateTime.now();

    // Keep only last 100 errors to prevent memory issues
    if (_errorHistory.length > 100) {
      _errorHistory.removeAt(0);
    }

    _updateHealthStatus();

    log('🚨 Error reported: $operation - $error');

    // Log critical errors with more details
    if (_isCriticalError(error)) {
      log('🔴 CRITICAL ERROR in $operation: $error', stackTrace: stackTrace);
    }
  }

  /// Report successful operation
  void reportSuccess(
    String operation,
    Duration responseTime, {
    Map<String, dynamic>? context,
  }) {
    // Track response times
    _responseTimeHistory.putIfAbsent(operation, () => []);
    _responseTimeHistory[operation]!.add(responseTime);

    // Keep only last 50 response times per operation
    if (_responseTimeHistory[operation]!.length > 50) {
      _responseTimeHistory[operation]!.removeAt(0);
    }

    // Calculate average response time
    final times = _responseTimeHistory[operation]!;
    final avgMs = times.map((t) => t.inMilliseconds).reduce((a, b) => a + b) /
        times.length;
    _averageResponseTimes[operation] = Duration(milliseconds: avgMs.round());

    // Update success rates
    _updateSuccessRate(operation);

    log('✅ Success reported: $operation (${responseTime.inMilliseconds}ms)');
  }

  /// Get comprehensive error diagnostics
  Map<String, dynamic> getDiagnostics() {
    final now = DateTime.now();
    final last24h = now.subtract(const Duration(hours: 24));

    // Filter recent errors
    final recentErrors =
        _errorHistory.where((e) => e.timestamp.isAfter(last24h)).toList();

    // Group errors by type
    final errorsByType = <String, List<ErrorReport>>{};
    for (final error in recentErrors) {
      errorsByType.putIfAbsent(error.operation, () => []);
      errorsByType[error.operation]!.add(error);
    }

    return {
      'systemHealth': {
        'isHealthy': _isHealthy,
        'lastHealthCheck': _lastHealthCheck.toIso8601String(),
        'totalErrors24h': recentErrors.length,
        'criticalErrors24h':
            recentErrors.where((e) => _isCriticalError(e.error)).length,
      },
      'errorCounts': Map<String, dynamic>.from(_errorCounts),
      'lastErrorTimes':
          _lastErrorTimes.map((k, v) => MapEntry(k, v.toIso8601String())),
      'averageResponseTimes': _averageResponseTimes
          .map((k, v) => MapEntry(k, '${v.inMilliseconds}ms')),
      'successRates': Map<String, dynamic>.from(_successRates),
      'errorsByOperation': errorsByType.map((k, v) => MapEntry(k, {
            'count': v.length,
            'lastError':
                v.isNotEmpty ? v.last.timestamp.toIso8601String() : null,
            'commonErrors': _getCommonErrors(v),
          })),
      'performanceMetrics': _getPerformanceMetrics(),
      'circuitBreakerStatus': _getCircuitBreakerStatus(),
    };
  }

  /// Get recent error history
  List<ErrorReport> getRecentErrors({int limit = 20}) {
    final sorted = List<ErrorReport>.from(_errorHistory)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.take(limit).toList();
  }

  /// Get error trends and patterns
  Map<String, dynamic> getErrorTrends() {
    final now = DateTime.now();
    final last24h = now.subtract(const Duration(hours: 24));
    final last1h = now.subtract(const Duration(hours: 1));

    final errors24h =
        _errorHistory.where((e) => e.timestamp.isAfter(last24h)).length;
    final errors1h =
        _errorHistory.where((e) => e.timestamp.isAfter(last1h)).length;

    return {
      'trend': errors1h > (errors24h / 24) * 2 ? 'increasing' : 'stable',
      'errors_last_hour': errors1h,
      'errors_last_24h': errors24h,
      'error_rate_per_hour': errors24h / 24,
      'most_frequent_operations': _getMostFrequentErrors(),
      'critical_operations': _getCriticalOperations(),
    };
  }

  /// Check if system should enter maintenance mode
  bool shouldEnterMaintenanceMode() {
    final now = DateTime.now();
    final last1h = now.subtract(const Duration(hours: 1));

    final recentErrors =
        _errorHistory.where((e) => e.timestamp.isAfter(last1h)).length;

    // Enter maintenance if more than 10 errors in last hour
    return recentErrors > 10;
  }

  /// Export diagnostics for support
  String exportDiagnostics() {
    final diagnostics = getDiagnostics();
    final trends = getErrorTrends();
    final recentErrors = getRecentErrors(limit: 10);

    final export = {
      'timestamp': DateTime.now().toIso8601String(),
      'diagnostics': diagnostics,
      'trends': trends,
      'recent_errors': recentErrors.map((e) => e.toMap()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(export);
  }

  /// Clear old error data
  void clearOldErrors({Duration? olderThan}) {
    final cutoff =
        DateTime.now().subtract(olderThan ?? const Duration(days: 7));
    _errorHistory.removeWhere((e) => e.timestamp.isBefore(cutoff));

    // Reset counters for operations that haven't had errors recently
    final activeOperations = _errorHistory.map((e) => e.operation).toSet();
    _errorCounts
        .removeWhere((operation, _) => !activeOperations.contains(operation));
    _lastErrorTimes
        .removeWhere((operation, _) => !activeOperations.contains(operation));

    log('🧹 Cleared error data older than ${olderThan?.inDays ?? 7} days');
  }

  // Private helper methods

  void _updateHealthStatus() {
    final now = DateTime.now();
    final last5min = now.subtract(const Duration(minutes: 5));

    final recentErrors =
        _errorHistory.where((e) => e.timestamp.isAfter(last5min)).length;

    _isHealthy =
        recentErrors < 5; // Unhealthy if more than 5 errors in 5 minutes
    _lastHealthCheck = now;
  }

  void _updateSuccessRate(String operation) {
    final now = DateTime.now();
    final last1h = now.subtract(const Duration(hours: 1));

    final recentErrors = _errorHistory
        .where((e) => e.operation == operation && e.timestamp.isAfter(last1h))
        .length;

    final responseCount = _responseTimeHistory[operation]?.length ?? 0;
    final totalOperations = recentErrors + responseCount;

    if (totalOperations > 0) {
      _successRates[operation] = (responseCount / totalOperations) * 100;
    }
  }

  bool _isCriticalError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('critical') ||
        errorStr.contains('fatal') ||
        errorStr.contains('circuit breaker') ||
        errorStr.contains('max retries exceeded');
  }

  List<String> _getCommonErrors(List<ErrorReport> errors) {
    final errorMessages = <String, int>{};
    for (final error in errors) {
      final key = error.error.length > 100
          ? '${error.error.substring(0, 100)}...'
          : error.error;
      errorMessages[key] = (errorMessages[key] ?? 0) + 1;
    }

    final sorted = errorMessages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(3).map((e) => '${e.key} (${e.value}x)').toList();
  }

  Map<String, dynamic> _getPerformanceMetrics() {
    final metrics = <String, dynamic>{};

    for (final entry in _responseTimeHistory.entries) {
      final times = entry.value;
      if (times.isNotEmpty) {
        times.sort((a, b) => a.compareTo(b));

        metrics[entry.key] = {
          'average_ms': _averageResponseTimes[entry.key]?.inMilliseconds ?? 0,
          'median_ms': times[times.length ~/ 2].inMilliseconds,
          'p95_ms': times[(times.length * 0.95).round() - 1].inMilliseconds,
          'min_ms': times.first.inMilliseconds,
          'max_ms': times.last.inMilliseconds,
          'sample_count': times.length,
        };
      }
    }

    return metrics;
  }

  Map<String, dynamic> _getCircuitBreakerStatus() {
    // This would integrate with AIErrorHandler instances
    // For now, return a placeholder
    return {
      'status': 'Available in AIErrorHandler instances',
      'note': 'Each service has its own circuit breaker state',
    };
  }

  List<String> _getMostFrequentErrors() {
    final sorted = _errorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(5).map((e) => '${e.key}: ${e.value}').toList();
  }

  List<String> _getCriticalOperations() {
    final now = DateTime.now();
    final last1h = now.subtract(const Duration(hours: 1));

    final criticalOps = <String>[];

    for (final entry in _lastErrorTimes.entries) {
      if (entry.value.isAfter(last1h) && (_errorCounts[entry.key] ?? 0) > 3) {
        criticalOps.add(entry.key);
      }
    }

    return criticalOps;
  }
}

/// Individual error report
class ErrorReport {
  const ErrorReport({
    required this.operation,
    required this.error,
    required this.timestamp,
    this.stackTrace,
    this.responseTime,
    this.context = const {},
  });

  final String operation;
  final String error;
  final String? stackTrace;
  final DateTime timestamp;
  final Duration? responseTime;
  final Map<String, dynamic> context;

  Map<String, dynamic> toMap() {
    return {
      'operation': operation,
      'error': error,
      'stackTrace': stackTrace,
      'timestamp': timestamp.toIso8601String(),
      'responseTime_ms': responseTime?.inMilliseconds,
      'context': context,
    };
  }
}

/// Integration extension for AIErrorHandler
extension ErrorMonitoringIntegration on AIErrorHandler {
  void reportToMonitoring(
    String operation,
    dynamic error, {
    StackTrace? stackTrace,
    Duration? responseTime,
    Map<String, dynamic>? context,
  }) {
    ErrorMonitoringService().reportError(
      operation,
      error,
      stackTrace: stackTrace,
      responseTime: responseTime,
      context: context,
    );
  }

  void reportSuccessToMonitoring(
    String operation,
    Duration responseTime, {
    Map<String, dynamic>? context,
  }) {
    ErrorMonitoringService().reportSuccess(
      operation,
      responseTime,
      context: context,
    );
  }
}

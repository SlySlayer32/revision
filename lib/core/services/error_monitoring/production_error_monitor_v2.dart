import 'dart:collection';

import 'package:revision/core/utils/enhanced_logger.dart';
import 'error_alert_manager.dart';
import 'error_classifier.dart';
import 'error_enums.dart';
import 'error_event.dart';
import 'error_monitoring_config.dart';
import 'system_health_monitor.dart';

/// Production-grade error monitoring service with improved architecture
class ProductionErrorMonitorV2 {
  ProductionErrorMonitorV2._({
    required ErrorMonitoringConfig config,
    required EnhancedLogger logger,
  }) : _config = config,
       _logger = logger,
       _classifier = const ErrorClassifier(),
       _alertManager = ErrorAlertManager(logger: logger),
       _healthMonitor = const SystemHealthMonitor();

  static ProductionErrorMonitorV2? _instance;

  static ProductionErrorMonitorV2 get instance {
    if (_instance == null) {
      throw StateError(
        'ProductionErrorMonitorV2 not initialized. Call initialize() first.',
      );
    }
    return _instance!;
  }

  /// Initialize the error monitor with configuration
  static void initialize({
    ErrorMonitoringConfig? config,
    EnhancedLogger? logger,
  }) {
    _instance = ProductionErrorMonitorV2._(
      config: config ?? const DefaultErrorMonitoringConfig(),
      logger: logger ?? EnhancedLogger(),
    );
  }

  final ErrorMonitoringConfig _config;
  final EnhancedLogger _logger;
  final ErrorClassifier _classifier;
  final ErrorAlertManager _alertManager;
  final SystemHealthMonitor _healthMonitor;

  final Queue<ErrorEvent> _errorHistory = Queue();
  final Map<String, int> _errorCounts = {};
  final Map<String, DateTime> _lastErrorTimes = {};

  /// Record an error event with comprehensive analysis
  void recordError({
    required Object error,
    required StackTrace stackTrace,
    required String context,
    Map<String, dynamic>? metadata,
  }) {
    try {
      final errorEvent = _createErrorEvent(
        error: error,
        stackTrace: stackTrace,
        context: context,
        metadata: metadata ?? {},
      );

      _addToHistory(errorEvent);
      _updateErrorCounts(errorEvent);

      if (_config.enableRealTimeAlerting) {
        _checkForCriticalPatterns(errorEvent);
      }

      _logErrorEvent(errorEvent);
    } catch (e, stack) {
      // Prevent recursive error logging
      _logger.error(
        'Failed to record error: $e',
        operation: 'ERROR_RECORDING_FAILURE',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Get comprehensive error statistics
  ErrorStatistics getErrorStatistics() {
    final now = DateTime.now();
    final errors24h = _getRecentErrors(_config.statsWindow24h);
    final errors1h = _getRecentErrors(_config.statsWindow1h);

    final errorsByCategory = <ErrorCategory, int>{};
    for (final event in errors24h) {
      errorsByCategory[event.category] =
          (errorsByCategory[event.category] ?? 0) + 1;
    }

    return ErrorStatistics(
      totalErrors24h: errors24h.length,
      totalErrors1h: errors1h.length,
      errorsByCategory: errorsByCategory,
      uniqueErrorTypes: _errorCounts.length,
      mostFrequentErrors: _getMostFrequentErrors(),
      alertStats: _alertManager.getAlertStats(),
      timestamp: now,
    );
  }

  /// Get system health report
  SystemHealthReport getHealthReport() {
    if (!_config.enableHealthMonitoring) {
      throw StateError('Health monitoring is disabled');
    }

    final recentErrors = _getRecentErrors(_config.healthCheckWindow);
    return _healthMonitor.generateHealthReport(
      recentErrors,
      _alertManager.hasActiveAlerts,
    );
  }

  /// Check if system is healthy
  bool isSystemHealthy() {
    if (!_config.enableHealthMonitoring) return true;

    final recentErrors = _getRecentErrors(_config.healthCheckWindow);
    return _healthMonitor.isSystemHealthy(
      recentErrors,
      _alertManager.hasActiveAlerts,
    );
  }

  /// Get health score (0-100)
  int getHealthScore() {
    if (!_config.enableHealthMonitoring) return 100;

    final recentErrors = _getRecentErrors(_config.statsWindow1h);
    return _healthMonitor.calculateHealthScore(recentErrors);
  }

  /// Reset monitoring state
  void reset() {
    _errorHistory.clear();
    _errorCounts.clear();
    _lastErrorTimes.clear();
    _alertManager.resetAllAlerts();

    _logger.info('Error monitoring state reset', operation: 'MONITOR_RESET');
  }

  /// Dispose resources
  void dispose() {
    _alertManager.dispose();
    _errorHistory.clear();
    _errorCounts.clear();
    _lastErrorTimes.clear();
  }

  ErrorEvent _createErrorEvent({
    required Object error,
    required StackTrace stackTrace,
    required String context,
    required Map<String, dynamic> metadata,
  }) {
    final category = _classifier.categorizeError(error);
    final severity = _classifier.getErrorSeverity(error);
    final isUserRecoverable = _classifier.isUserRecoverable(error);
    final errorKey = _classifier.generateErrorKey(error);

    return ErrorEvent(
      error: error,
      stackTrace: stackTrace,
      context: context,
      timestamp: DateTime.now(),
      metadata: metadata,
      category: category,
      severity: severity,
      isUserRecoverable: isUserRecoverable,
      errorKey: errorKey,
    );
  }

  void _addToHistory(ErrorEvent event) {
    _errorHistory.addLast(event);

    while (_errorHistory.length > _config.maxHistorySize) {
      _errorHistory.removeFirst();
    }
  }

  void _updateErrorCounts(ErrorEvent event) {
    _errorCounts[event.errorKey] = (_errorCounts[event.errorKey] ?? 0) + 1;
    _lastErrorTimes[event.errorKey] = event.timestamp;
  }

  void _checkForCriticalPatterns(ErrorEvent event) {
    _checkCriticalErrorThreshold(event);
    _checkCascadingFailures();
  }

  void _checkCriticalErrorThreshold(ErrorEvent event) {
    final errorCount = _errorCounts[event.errorKey] ?? 0;

    if (errorCount >= _config.criticalErrorThreshold) {
      final recentSameErrors = _errorHistory
          .where((e) => e.errorKey == event.errorKey)
          .where((e) => e.isRecent(_config.errorWindowDuration))
          .length;

      if (recentSameErrors >= _config.criticalErrorThreshold) {
        _alertManager.triggerCriticalErrorAlert(
          errorKey: event.errorKey,
          count: recentSameErrors,
          event: event,
        );
      }
    }
  }

  void _checkCascadingFailures() {
    final recentErrors = _getRecentErrors(_config.cascadingFailureWindow);
    final analysis = _healthMonitor.analyzeCascadingFailures(recentErrors);

    if (analysis.isCascadingFailure) {
      _alertManager.triggerCascadingFailureAlert(
        uniqueErrorTypes: analysis.uniqueErrorTypes,
        totalErrors: analysis.totalErrors,
        timeWindow: analysis.timeWindow,
      );
    }
  }

  void _logErrorEvent(ErrorEvent event) {
    final enhancedMetadata = {
      'error_category': event.category.value,
      'error_type': event.error.runtimeType.toString(),
      'context': event.context,
      'is_user_recoverable': event.isUserRecoverable,
      'severity': event.severity.value,
      'error_key': event.errorKey,
      ...event.metadata,
    };

    _logger.error(
      'Error recorded: ${event.error}',
      operation: 'ERROR_MONITORING',
      error: event.error,
      stackTrace: event.stackTrace,
      context: enhancedMetadata,
    );
  }

  List<ErrorEvent> _getRecentErrors(Duration timeWindow) {
    final cutoff = DateTime.now().subtract(timeWindow);
    return _errorHistory
        .where((event) => event.timestamp.isAfter(cutoff))
        .toList();
  }

  List<Map<String, dynamic>> _getMostFrequentErrors() {
    final sorted = _errorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted
        .take(_config.maxFrequentErrorsToShow)
        .map(
          (entry) => {
            'error_key': entry.key,
            'count': entry.value,
            'last_occurrence': _lastErrorTimes[entry.key]?.toIso8601String(),
          },
        )
        .toList();
  }
}

/// Comprehensive error statistics
class ErrorStatistics {
  const ErrorStatistics({
    required this.totalErrors24h,
    required this.totalErrors1h,
    required this.errorsByCategory,
    required this.uniqueErrorTypes,
    required this.mostFrequentErrors,
    required this.alertStats,
    required this.timestamp,
  });

  final int totalErrors24h;
  final int totalErrors1h;
  final Map<ErrorCategory, int> errorsByCategory;
  final int uniqueErrorTypes;
  final List<Map<String, dynamic>> mostFrequentErrors;
  final Map<String, dynamic> alertStats;
  final DateTime timestamp;

  Map<String, dynamic> toMap() {
    return {
      'total_errors_24h': totalErrors24h,
      'total_errors_1h': totalErrors1h,
      'errors_by_category': errorsByCategory.map(
        (key, value) => MapEntry(key.value, value),
      ),
      'unique_error_types': uniqueErrorTypes,
      'most_frequent_errors': mostFrequentErrors,
      'alert_stats': alertStats,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Extension for easy error recording
extension ErrorRecordingV2 on Object {
  void recordError(
    String context, {
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    ProductionErrorMonitorV2.instance.recordError(
      error: this,
      stackTrace: stackTrace ?? StackTrace.current,
      context: context,
      metadata: metadata,
    );
  }
}

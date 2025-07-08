import 'dart:async';

import 'package:revision/core/utils/enhanced_logger.dart';
import 'error_enums.dart';
import 'error_event.dart';
import 'error_monitoring_constants.dart';

/// Manages error alerting and notification logic
class ErrorAlertManager {
  ErrorAlertManager({required EnhancedLogger logger}) : _logger = logger;

  final EnhancedLogger _logger;
  final Map<AlertType, DateTime> _lastAlertTimes = {};
  final Map<AlertType, Timer> _alertTimers = {};
  final Set<AlertType> _activeAlerts = {};

  /// Check if an alert type is currently active
  bool isAlertActive(AlertType alertType) {
    return _activeAlerts.contains(alertType);
  }

  /// Check if any alert is currently active
  bool get hasActiveAlerts => _activeAlerts.isNotEmpty;

  /// Trigger a critical error pattern alert
  void triggerCriticalErrorAlert({
    required String errorKey,
    required int count,
    required ErrorEvent event,
  }) {
    if (isAlertActive(AlertType.criticalErrorPattern)) return;

    _activateAlert(AlertType.criticalErrorPattern);

    _logger.error(
      '🚨 CRITICAL ERROR PATTERN: $errorKey occurred $count times in ${ErrorMonitoringConstants.errorWindowDuration.inMinutes} minutes',
      operation: AlertType.criticalErrorPattern.value,
      error: event.error,
      stackTrace: event.stackTrace,
      context: {
        'error_key': errorKey,
        'count': count,
        'severity': event.severity.value,
        'category': event.category.value,
      },
    );

    _scheduleAlertReset(AlertType.criticalErrorPattern);
  }

  /// Trigger a cascading failure alert
  void triggerCascadingFailureAlert({
    required int uniqueErrorTypes,
    required int totalErrors,
    required Duration timeWindow,
  }) {
    if (isAlertActive(AlertType.cascadingFailure)) return;

    _activateAlert(AlertType.cascadingFailure);

    _logger.error(
      '🚨 CASCADING FAILURE DETECTED: $uniqueErrorTypes error types, $totalErrors errors in ${timeWindow.inMinutes} minutes',
      operation: AlertType.cascadingFailure.value,
      context: {
        'unique_error_types': uniqueErrorTypes,
        'total_errors': totalErrors,
        'time_window_minutes': timeWindow.inMinutes,
      },
    );

    _scheduleAlertReset(AlertType.cascadingFailure);
  }

  /// Trigger a system health degraded alert
  void triggerSystemHealthAlert({
    required int healthScore,
    required int recentErrorCount,
  }) {
    if (isAlertActive(AlertType.systemHealthDegraded)) return;

    _activateAlert(AlertType.systemHealthDegraded);

    _logger.error(
      '🚨 SYSTEM HEALTH DEGRADED: Health score $healthScore, $recentErrorCount recent errors',
      operation: AlertType.systemHealthDegraded.value,
      context: {
        'health_score': healthScore,
        'recent_error_count': recentErrorCount,
      },
    );

    _scheduleAlertReset(AlertType.systemHealthDegraded);
  }

  /// Check if enough time has passed since last alert of this type
  bool canTriggerAlert(AlertType alertType, {Duration? minInterval}) {
    final interval =
        minInterval ?? ErrorMonitoringConstants.circuitBreakerCooldown;
    final lastAlert = _lastAlertTimes[alertType];

    if (lastAlert == null) return true;

    return DateTime.now().difference(lastAlert) >= interval;
  }

  /// Manually reset a specific alert
  void resetAlert(AlertType alertType) {
    _activeAlerts.remove(alertType);
    _alertTimers[alertType]?.cancel();
    _alertTimers.remove(alertType);

    _logger.info(
      'Alert reset: ${alertType.value}',
      operation: 'ALERT_RESET',
      context: {'alert_type': alertType.value},
    );
  }

  /// Reset all active alerts
  void resetAllAlerts() {
    final activeTypes = List.from(_activeAlerts);
    for (final alertType in activeTypes) {
      resetAlert(alertType);
    }
  }

  /// Get alert statistics
  Map<String, dynamic> getAlertStats() {
    return {
      'active_alerts': _activeAlerts.map((e) => e.value).toList(),
      'active_alert_count': _activeAlerts.length,
      'last_alert_times': _lastAlertTimes.map(
        (key, value) => MapEntry(key.value, value.toIso8601String()),
      ),
    };
  }

  void _activateAlert(AlertType alertType) {
    _activeAlerts.add(alertType);
    _lastAlertTimes[alertType] = DateTime.now();
  }

  void _scheduleAlertReset(AlertType alertType) {
    _alertTimers[alertType]?.cancel();
    _alertTimers[alertType] = Timer(
      ErrorMonitoringConstants.circuitBreakerCooldown,
      () => resetAlert(alertType),
    );
  }

  /// Dispose all timers
  void dispose() {
    for (final timer in _alertTimers.values) {
      timer.cancel();
    }
    _alertTimers.clear();
    _activeAlerts.clear();
  }
}

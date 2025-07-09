import 'package:flutter/foundation.dart';
import 'package:revision/core/utils/enhanced_logger.dart';
import 'package:revision/core/services/logging_service.dart';

/// Service for tracking navigation patterns and analytics
class NavigationAnalyticsService {
  static final NavigationAnalyticsService _instance = NavigationAnalyticsService._internal();
  factory NavigationAnalyticsService() => _instance;
  NavigationAnalyticsService._internal();

  final EnhancedLogger _logger = EnhancedLogger();
  final LoggingService _loggingService = LoggingService.instance;

  /// Tracks successful navigation events
  void trackNavigation({
    required String fromRoute,
    required String toRoute,
    Map<String, dynamic>? arguments,
    Duration? duration,
  }) {
    final analyticsData = {
      'event': 'navigation_success',
      'from_route': fromRoute,
      'to_route': toRoute,
      'has_arguments': arguments != null,
      'arguments_count': arguments?.length ?? 0,
      'duration_ms': duration?.inMilliseconds,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _logger.info(
      'Navigation: $fromRoute → $toRoute',
      operation: 'NAVIGATION',
      context: analyticsData,
    );

    _loggingService.userAction('navigation', data: analyticsData);
  }

  /// Tracks navigation failures
  void trackNavigationFailure({
    required String fromRoute,
    required String attemptedRoute,
    required String error,
    Map<String, dynamic>? arguments,
    String? fallbackRoute,
  }) {
    final analyticsData = {
      'event': 'navigation_failure',
      'from_route': fromRoute,
      'attempted_route': attemptedRoute,
      'error': error,
      'has_arguments': arguments != null,
      'arguments_count': arguments?.length ?? 0,
      'fallback_route': fallbackRoute,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _logger.error(
      'Navigation failed: $fromRoute → $attemptedRoute ($error)',
      operation: 'NAVIGATION_FAILURE',
      context: analyticsData,
      error: error,
    );

    _loggingService.error('Navigation failure', data: analyticsData);
  }

  /// Tracks deep link access attempts
  void trackDeepLink({
    required String deepLink,
    required bool isValid,
    String? error,
    Map<String, dynamic>? extractedData,
  }) {
    final analyticsData = {
      'event': 'deep_link_access',
      'deep_link': deepLink,
      'is_valid': isValid,
      'error': error,
      'extracted_data': extractedData,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (isValid) {
      _logger.info(
        'Valid deep link accessed: $deepLink',
        operation: 'DEEP_LINK',
        context: analyticsData,
      );
    } else {
      _logger.warning(
        'Invalid deep link attempted: $deepLink',
        operation: 'DEEP_LINK_INVALID',
        context: analyticsData,
        error: error,
      );
    }

    _loggingService.userAction('deep_link', data: analyticsData);
  }

  /// Tracks argument validation issues
  void trackArgumentValidation({
    required String route,
    required String argumentKey,
    required String expectedType,
    required String actualType,
    required bool isValid,
  }) {
    final analyticsData = {
      'event': 'argument_validation',
      'route': route,
      'argument_key': argumentKey,
      'expected_type': expectedType,
      'actual_type': actualType,
      'is_valid': isValid,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (!isValid) {
      _logger.warning(
        'Argument validation failed: $route[$argumentKey] expected $expectedType, got $actualType',
        operation: 'ARGUMENT_VALIDATION',
        context: analyticsData,
      );
    }

    _loggingService.userAction('argument_validation', data: analyticsData);
  }

  /// Tracks navigation performance metrics
  void trackNavigationPerformance({
    required String route,
    required Duration renderTime,
    Map<String, dynamic>? additionalMetrics,
  }) {
    final analyticsData = {
      'event': 'navigation_performance',
      'route': route,
      'render_time_ms': renderTime.inMilliseconds,
      'is_slow': renderTime.inMilliseconds > 1000,
      ...?additionalMetrics,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _logger.performanceMetric(
      'navigation_render_time',
      renderTime.inMilliseconds,
      unit: 'ms',
      context: analyticsData,
    );

    _loggingService.performance('navigation_render', renderTime, data: analyticsData);
  }

  /// Gets navigation analytics summary (for debugging)
  Map<String, dynamic> getAnalyticsSummary() {
    final recentLogs = _logger.getRecentLogs(limit: 100);
    final navigationLogs = recentLogs.where((log) => 
      log.operation?.contains('NAVIGATION') == true ||
      log.operation?.contains('DEEP_LINK') == true
    ).toList();

    final successCount = navigationLogs.where((log) => 
      log.context['event'] == 'navigation_success'
    ).length;

    final failureCount = navigationLogs.where((log) => 
      log.context['event'] == 'navigation_failure'
    ).length;

    final deepLinkCount = navigationLogs.where((log) => 
      log.context['event'] == 'deep_link_access'
    ).length;

    return {
      'total_events': navigationLogs.length,
      'successful_navigations': successCount,
      'failed_navigations': failureCount,
      'deep_link_attempts': deepLinkCount,
      'success_rate': successCount / (successCount + failureCount + 1) * 100,
      'last_updated': DateTime.now().toIso8601String(),
    };
  }
}
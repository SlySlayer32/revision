import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:revision/core/utils/enhanced_logger.dart';
import 'package:revision/core/services/error_monitoring/production_error_monitor_v2.dart';
import 'package:revision/core/services/error_monitoring/system_health_monitor.dart';
import 'service_locator_validator.dart';

/// Monitors service health and provides recovery mechanisms
class ServiceHealthMonitor {
  ServiceHealthMonitor._({
    required GetIt getIt,
    required EnhancedLogger logger,
  }) : _getIt = getIt,
       _logger = logger;
  
  static ServiceHealthMonitor? _instance;
  
  static ServiceHealthMonitor get instance {
    if (_instance == null) {
      throw StateError('ServiceHealthMonitor not initialized. Call initialize() first.');
    }
    return _instance!;
  }
  
  /// Initialize the service health monitor
  static void initialize({
    required GetIt getIt,
    EnhancedLogger? logger,
  }) {
    _instance = ServiceHealthMonitor._(
      getIt: getIt,
      logger: logger ?? EnhancedLogger(),
    );
  }
  
  final GetIt _getIt;
  final EnhancedLogger _logger;
  final SystemHealthMonitor _systemHealthMonitor = const SystemHealthMonitor();
  
  Timer? _healthCheckTimer;
  final Map<Type, ServiceHealthResult> _lastHealthResults = {};
  final Map<Type, int> _failureCounts = {};
  final Map<Type, DateTime> _lastFailureTimes = {};
  
  // Health check configuration
  static const Duration _healthCheckInterval = Duration(minutes: 5);
  static const int _maxFailureCount = 3;
  static const Duration _failureResetTime = Duration(minutes: 15);
  
  /// Start continuous health monitoring
  void startHealthMonitoring() {
    _logger.info('Starting service health monitoring', operation: 'HEALTH_MONITORING');
    
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(_healthCheckInterval, (_) {
      _performHealthCheck();
    });
  }
  
  /// Stop health monitoring
  void stopHealthMonitoring() {
    _logger.info('Stopping service health monitoring', operation: 'HEALTH_MONITORING');
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
  }
  
  /// Perform immediate health check on all services
  Future<ServiceHealthReport> performHealthCheck() async {
    _logger.debug('Performing immediate health check', operation: 'HEALTH_CHECK');
    
    final startTime = DateTime.now();
    final healthResults = <ServiceHealthResult>[];
    
    try {
      // Get all registered services - simplified approach
      // In a real implementation, you'd maintain a registry of services to check
      final serviceTypes = _getRegisteredServiceTypes();
      
      for (final serviceType in serviceTypes) {
        final result = await ServiceLocatorValidator.checkServiceHealth(
          _getIt,
        );
        healthResults.add(result);
        _lastHealthResults[serviceType] = result;
        
        // Update failure tracking
        if (!result.isHealthy) {
          _failureCounts[serviceType] = (_failureCounts[serviceType] ?? 0) + 1;
          _lastFailureTimes[serviceType] = DateTime.now();
          
          // Log service failure
          _logger.warning(
            'Service health check failed: ${result.serviceName}',
            operation: 'SERVICE_HEALTH_FAILURE',
            context: {
              'service_type': result.serviceName,
              'health_score': result.healthScore,
              'issues': result.issues,
              'failure_count': _failureCounts[serviceType],
            },
          );
          
          // Record error in monitoring system
          ProductionErrorMonitorV2.instance.recordError(
            error: ServiceHealthException(
              'Service health check failed: ${result.serviceName}',
              result.issues,
            ),
            stackTrace: StackTrace.current,
            context: 'ServiceHealthMonitor.performHealthCheck',
            metadata: {
              'service_type': result.serviceName,
              'health_score': result.healthScore,
              'issues': result.issues,
            },
          );
        } else {
          // Reset failure count on successful health check
          _failureCounts[serviceType] = 0;
        }
      }
      
      final duration = DateTime.now().difference(startTime);
      final overallHealthScore = _calculateOverallHealthScore(healthResults);
      final isHealthy = _isSystemHealthy(healthResults);
      
      final report = ServiceHealthReport(
        isHealthy: isHealthy,
        overallHealthScore: overallHealthScore,
        serviceResults: healthResults,
        unhealthyServices: healthResults.where((r) => !r.isHealthy).toList(),
        checkDuration: duration,
        timestamp: DateTime.now(),
      );
      
      _logger.info(
        'Health check completed: ${isHealthy ? 'HEALTHY' : 'UNHEALTHY'} '
        '(score: $overallHealthScore, duration: ${duration.inMilliseconds}ms)',
        operation: 'HEALTH_CHECK',
        context: {
          'overall_health_score': overallHealthScore,
          'is_healthy': isHealthy,
          'total_services': healthResults.length,
          'unhealthy_services': healthResults.where((r) => !r.isHealthy).length,
          'check_duration_ms': duration.inMilliseconds,
        },
      );
      
      return report;
    } catch (e, stackTrace) {
      _logger.error(
        'Health check failed with exception: $e',
        operation: 'HEALTH_CHECK',
        error: e,
        stackTrace: stackTrace,
      );
      
      ProductionErrorMonitorV2.instance.recordError(
        error: e,
        stackTrace: stackTrace,
        context: 'ServiceHealthMonitor.performHealthCheck',
      );
      
      return ServiceHealthReport(
        isHealthy: false,
        overallHealthScore: 0,
        serviceResults: healthResults,
        unhealthyServices: healthResults,
        checkDuration: DateTime.now().difference(startTime),
        timestamp: DateTime.now(),
        error: e.toString(),
      );
    }
  }
  
  /// Get health status for a specific service
  ServiceHealthResult? getServiceHealth<T extends Object>() {
    return _lastHealthResults[T];
  }
  
  /// Check if a service is considered failed based on failure count
  bool isServiceFailed<T extends Object>() {
    final failureCount = _failureCounts[T] ?? 0;
    final lastFailure = _lastFailureTimes[T];
    
    if (failureCount >= _maxFailureCount) {
      // Check if failure reset time has passed
      if (lastFailure != null) {
        final timeSinceFailure = DateTime.now().difference(lastFailure);
        return timeSinceFailure < _failureResetTime;
      }
      return true;
    }
    
    return false;
  }
  
  /// Reset failure count for a service
  void resetServiceFailures<T extends Object>() {
    _failureCounts[T] = 0;
    _lastFailureTimes.remove(T);
    _logger.info(
      'Reset failure count for service: ${T.toString()}',
      operation: 'SERVICE_FAILURE_RESET',
    );
  }
  
  /// Get services with high failure rates
  List<Type> getFailingServices() {
    final failingServices = <Type>[];
    
    for (final entry in _failureCounts.entries) {
      if (entry.value >= _maxFailureCount) {
        final lastFailure = _lastFailureTimes[entry.key];
        if (lastFailure != null) {
          final timeSinceFailure = DateTime.now().difference(lastFailure);
          if (timeSinceFailure < _failureResetTime) {
            failingServices.add(entry.key);
          }
        }
      }
    }
    
    return failingServices;
  }
  
  /// Dispose resources
  void dispose() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
    _lastHealthResults.clear();
    _failureCounts.clear();
    _lastFailureTimes.clear();
  }
  
  // Private methods
  
  void _performHealthCheck() {
    performHealthCheck().then((report) {
      if (!report.isHealthy) {
        _logger.warning(
          'Scheduled health check detected unhealthy services',
          operation: 'SCHEDULED_HEALTH_CHECK',
          context: {
            'unhealthy_count': report.unhealthyServices.length,
            'overall_score': report.overallHealthScore,
          },
        );
      }
    }).catchError((error, stackTrace) {
      _logger.error(
        'Scheduled health check failed: $error',
        operation: 'SCHEDULED_HEALTH_CHECK',
        error: error,
        stackTrace: stackTrace,
      );
    });
  }
  
  List<Type> _getRegisteredServiceTypes() {
    // Simplified - in a real implementation, you'd maintain a registry
    // For now, return empty list as we don't have access to GetIt's internal registry
    return [];
  }
  
  int _calculateOverallHealthScore(List<ServiceHealthResult> results) {
    if (results.isEmpty) return 100;
    
    final totalScore = results.fold<int>(0, (sum, result) => sum + result.healthScore);
    return (totalScore / results.length).round();
  }
  
  bool _isSystemHealthy(List<ServiceHealthResult> results) {
    if (results.isEmpty) return true;
    
    final unhealthyCount = results.where((r) => !r.isHealthy).length;
    final unhealthyPercentage = (unhealthyCount / results.length) * 100;
    
    // Consider system healthy if less than 20% of services are unhealthy
    return unhealthyPercentage < 20;
  }
}

/// Service health report
class ServiceHealthReport {
  const ServiceHealthReport({
    required this.isHealthy,
    required this.overallHealthScore,
    required this.serviceResults,
    required this.unhealthyServices,
    required this.checkDuration,
    required this.timestamp,
    this.error,
  });
  
  final bool isHealthy;
  final int overallHealthScore;
  final List<ServiceHealthResult> serviceResults;
  final List<ServiceHealthResult> unhealthyServices;
  final Duration checkDuration;
  final DateTime timestamp;
  final String? error;
  
  /// Convert to map for logging/serialization
  Map<String, dynamic> toMap() {
    return {
      'is_healthy': isHealthy,
      'overall_health_score': overallHealthScore,
      'total_services': serviceResults.length,
      'unhealthy_services': unhealthyServices.length,
      'check_duration_ms': checkDuration.inMilliseconds,
      'timestamp': timestamp.toIso8601String(),
      'error': error,
      'unhealthy_service_details': unhealthyServices.map((s) => {
        'service_name': s.serviceName,
        'health_score': s.healthScore,
        'issues': s.issues,
      }).toList(),
    };
  }
}

/// Exception for service health issues
class ServiceHealthException implements Exception {
  const ServiceHealthException(this.message, this.issues);
  
  final String message;
  final List<String> issues;
  
  @override
  String toString() => 'ServiceHealthException: $message (Issues: ${issues.join(', ')})';
}
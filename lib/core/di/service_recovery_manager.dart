import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:revision/core/utils/enhanced_logger.dart';
import 'package:revision/core/services/error_monitoring/production_error_monitor_v2.dart';
import 'service_locator_validator.dart';
import 'service_health_monitor.dart';

/// Service recovery and fallback mechanisms
class ServiceRecoveryManager {
  ServiceRecoveryManager._({
    required GetIt getIt,
    required EnhancedLogger logger,
  }) : _getIt = getIt,
       _logger = logger;
  
  static ServiceRecoveryManager? _instance;
  
  static ServiceRecoveryManager get instance {
    if (_instance == null) {
      throw StateError('ServiceRecoveryManager not initialized. Call initialize() first.');
    }
    return _instance!;
  }
  
  /// Initialize the service recovery manager
  static void initialize({
    required GetIt getIt,
    EnhancedLogger? logger,
  }) {
    _instance = ServiceRecoveryManager._(
      getIt: getIt,
      logger: logger ?? EnhancedLogger(),
    );
  }
  
  final GetIt _getIt;
  final EnhancedLogger _logger;
  final Map<Type, ServiceRecoveryStrategy> _recoveryStrategies = {};
  final Map<Type, DateTime> _lastRecoveryAttempts = {};
  final Map<Type, int> _recoveryAttemptCounts = {};
  
  // Recovery configuration
  static const Duration _recoveryAttemptDelay = Duration(seconds: 30);
  static const int _maxRecoveryAttempts = 3;
  static const Duration _recoveryResetTime = Duration(minutes: 15);
  
  /// Register a recovery strategy for a service type
  void registerRecoveryStrategy<T extends Object>(
    ServiceRecoveryStrategy strategy,
  ) {
    _recoveryStrategies[T] = strategy;
    _logger.info(
      'Registered recovery strategy for service: ${T.toString()}',
      operation: 'RECOVERY_STRATEGY_REGISTRATION',
    );
  }
  
  /// Attempt to recover a failed service
  Future<RecoveryResult> attemptServiceRecovery<T extends Object>() async {
    final serviceType = T;
    final serviceName = serviceType.toString();
    
    _logger.info(
      'Attempting service recovery for: $serviceName',
      operation: 'SERVICE_RECOVERY',
    );
    
    try {
      // Check if we've exceeded max recovery attempts
      if (_hasExceededMaxRecoveryAttempts(serviceType)) {
        return RecoveryResult(
          serviceType: serviceType,
          serviceName: serviceName,
          isSuccessful: false,
          recoveryStrategy: RecoveryStrategy.none,
          error: 'Max recovery attempts exceeded',
          timestamp: DateTime.now(),
        );
      }
      
      // Check if enough time has passed since last recovery attempt
      if (!_canAttemptRecovery(serviceType)) {
        return RecoveryResult(
          serviceType: serviceType,
          serviceName: serviceName,
          isSuccessful: false,
          recoveryStrategy: RecoveryStrategy.none,
          error: 'Recovery attempt too soon',
          timestamp: DateTime.now(),
        );
      }
      
      // Update recovery attempt tracking
      _lastRecoveryAttempts[serviceType] = DateTime.now();
      _recoveryAttemptCounts[serviceType] = (_recoveryAttemptCounts[serviceType] ?? 0) + 1;
      
      // Get recovery strategy
      final strategy = _recoveryStrategies[serviceType];
      if (strategy == null) {
        return await _attemptDefaultRecovery<T>();
      }
      
      // Execute recovery strategy
      final result = await _executeRecoveryStrategy<T>(strategy);
      
      if (result.isSuccessful) {
        _logger.info(
          'Service recovery successful for: $serviceName',
          operation: 'SERVICE_RECOVERY_SUCCESS',
          context: {
            'recovery_strategy': result.recoveryStrategy.name,
            'attempt_count': _recoveryAttemptCounts[serviceType],
          },
        );
        
        // Reset recovery attempts on success
        _recoveryAttemptCounts[serviceType] = 0;
        _lastRecoveryAttempts.remove(serviceType);
        
        // Reset service failure tracking in health monitor
        if (ServiceHealthMonitor._instance != null) {
          ServiceHealthMonitor.instance.resetServiceFailures<T>();
        }
      } else {
        _logger.warning(
          'Service recovery failed for: $serviceName',
          operation: 'SERVICE_RECOVERY_FAILURE',
          context: {
            'recovery_strategy': result.recoveryStrategy.name,
            'attempt_count': _recoveryAttemptCounts[serviceType],
            'error': result.error,
          },
        );
        
        // Record recovery failure in monitoring system
        ProductionErrorMonitorV2.instance.recordError(
          error: ServiceRecoveryException(
            'Service recovery failed: $serviceName',
            result.error ?? 'Unknown error',
          ),
          stackTrace: StackTrace.current,
          context: 'ServiceRecoveryManager.attemptServiceRecovery',
          metadata: {
            'service_type': serviceName,
            'recovery_strategy': result.recoveryStrategy.name,
            'attempt_count': _recoveryAttemptCounts[serviceType],
          },
        );
      }
      
      return result;
    } catch (e, stackTrace) {
      _logger.error(
        'Service recovery failed with exception for: $serviceName',
        operation: 'SERVICE_RECOVERY',
        error: e,
        stackTrace: stackTrace,
      );
      
      ProductionErrorMonitorV2.instance.recordError(
        error: e,
        stackTrace: stackTrace,
        context: 'ServiceRecoveryManager.attemptServiceRecovery',
        metadata: {'service_type': serviceName},
      );
      
      return RecoveryResult(
        serviceType: serviceType,
        serviceName: serviceName,
        isSuccessful: false,
        recoveryStrategy: RecoveryStrategy.none,
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }
  
  /// Get a service with automatic recovery on failure
  Future<T?> getServiceWithRecovery<T extends Object>() async {
    try {
      // First try to get the service normally
      final service = _getIt<T>();
      
      // Validate the service
      if (service == null) {
        throw ServiceNotFoundException('Service ${T.toString()} is null');
      }
      
      return service;
    } catch (e) {
      _logger.warning(
        'Failed to get service ${T.toString()}, attempting recovery: $e',
        operation: 'SERVICE_GET_WITH_RECOVERY',
      );
      
      // Attempt recovery
      final recoveryResult = await attemptServiceRecovery<T>();
      
      if (recoveryResult.isSuccessful) {
        try {
          return _getIt<T>();
        } catch (e2) {
          _logger.error(
            'Service still unavailable after recovery: ${T.toString()}',
            operation: 'SERVICE_GET_POST_RECOVERY',
            error: e2,
          );
          return null;
        }
      }
      
      return null;
    }
  }
  
  /// Execute a function with automatic service recovery
  Future<R?> executeWithRecovery<T extends Object, R>(
    Future<R> Function(T service) operation,
  ) async {
    final service = await getServiceWithRecovery<T>();
    if (service == null) {
      return null;
    }
    
    try {
      return await operation(service);
    } catch (e, stackTrace) {
      _logger.warning(
        'Operation failed with service ${T.toString()}: $e',
        operation: 'EXECUTE_WITH_RECOVERY',
        error: e,
        stackTrace: stackTrace,
      );
      
      // Attempt recovery and retry once
      final recoveryResult = await attemptServiceRecovery<T>();
      if (recoveryResult.isSuccessful) {
        final recoveredService = await getServiceWithRecovery<T>();
        if (recoveredService != null) {
          try {
            return await operation(recoveredService);
          } catch (e2) {
            _logger.error(
              'Operation still failed after recovery: ${T.toString()}',
              operation: 'EXECUTE_POST_RECOVERY',
              error: e2,
            );
          }
        }
      }
      
      return null;
    }
  }
  
  /// Get recovery statistics
  Map<String, dynamic> getRecoveryStatistics() {
    return {
      'registered_strategies': _recoveryStrategies.length,
      'recovery_attempts': _recoveryAttemptCounts.entries.map((e) => {
        'service_type': e.key.toString(),
        'attempt_count': e.value,
        'last_attempt': _lastRecoveryAttempts[e.key]?.toIso8601String(),
      }).toList(),
      'failed_services': _recoveryAttemptCounts.entries
          .where((e) => e.value >= _maxRecoveryAttempts)
          .map((e) => e.key.toString())
          .toList(),
    };
  }
  
  /// Reset recovery statistics
  void resetRecoveryStatistics() {
    _recoveryAttemptCounts.clear();
    _lastRecoveryAttempts.clear();
    _logger.info('Recovery statistics reset', operation: 'RECOVERY_STATS_RESET');
  }
  
  /// Dispose resources
  void dispose() {
    _recoveryStrategies.clear();
    _lastRecoveryAttempts.clear();
    _recoveryAttemptCounts.clear();
  }
  
  // Private methods
  
  bool _hasExceededMaxRecoveryAttempts(Type serviceType) {
    final attemptCount = _recoveryAttemptCounts[serviceType] ?? 0;
    return attemptCount >= _maxRecoveryAttempts;
  }
  
  bool _canAttemptRecovery(Type serviceType) {
    final lastAttempt = _lastRecoveryAttempts[serviceType];
    if (lastAttempt == null) return true;
    
    final timeSinceLastAttempt = DateTime.now().difference(lastAttempt);
    return timeSinceLastAttempt >= _recoveryAttemptDelay;
  }
  
  Future<RecoveryResult> _attemptDefaultRecovery<T extends Object>() async {
    final serviceType = T;
    final serviceName = serviceType.toString();
    
    try {
      // Default recovery strategy: try to re-register the service
      _logger.info(
        'Attempting default recovery for: $serviceName',
        operation: 'DEFAULT_RECOVERY',
      );
      
      // Check if service is registered
      if (!_getIt.isRegistered<T>()) {
        return RecoveryResult(
          serviceType: serviceType,
          serviceName: serviceName,
          isSuccessful: false,
          recoveryStrategy: RecoveryStrategy.reregister,
          error: 'Service not registered and no recovery strategy available',
          timestamp: DateTime.now(),
        );
      }
      
      // Try to get the service to see if it's working
      final service = _getIt<T>();
      if (service != null) {
        return RecoveryResult(
          serviceType: serviceType,
          serviceName: serviceName,
          isSuccessful: true,
          recoveryStrategy: RecoveryStrategy.retry,
          timestamp: DateTime.now(),
        );
      }
      
      return RecoveryResult(
        serviceType: serviceType,
        serviceName: serviceName,
        isSuccessful: false,
        recoveryStrategy: RecoveryStrategy.retry,
        error: 'Service instance is null',
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return RecoveryResult(
        serviceType: serviceType,
        serviceName: serviceName,
        isSuccessful: false,
        recoveryStrategy: RecoveryStrategy.retry,
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }
  
  Future<RecoveryResult> _executeRecoveryStrategy<T extends Object>(
    ServiceRecoveryStrategy strategy,
  ) async {
    final serviceType = T;
    final serviceName = serviceType.toString();
    
    try {
      final isSuccessful = await strategy.recover(_getIt, serviceType);
      
      return RecoveryResult(
        serviceType: serviceType,
        serviceName: serviceName,
        isSuccessful: isSuccessful,
        recoveryStrategy: strategy.strategyType,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return RecoveryResult(
        serviceType: serviceType,
        serviceName: serviceName,
        isSuccessful: false,
        recoveryStrategy: strategy.strategyType,
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }
}

/// Abstract base class for service recovery strategies
abstract class ServiceRecoveryStrategy {
  const ServiceRecoveryStrategy();
  
  /// The type of recovery strategy
  RecoveryStrategy get strategyType;
  
  /// Attempt to recover the service
  Future<bool> recover(GetIt getIt, Type serviceType);
}

/// Recovery strategy that re-registers a service
class ReregisterRecoveryStrategy extends ServiceRecoveryStrategy {
  const ReregisterRecoveryStrategy(this.registrationFunction);
  
  final Future<void> Function(GetIt getIt) registrationFunction;
  
  @override
  RecoveryStrategy get strategyType => RecoveryStrategy.reregister;
  
  @override
  Future<bool> recover(GetIt getIt, Type serviceType) async {
    try {
      await registrationFunction(getIt);
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Recovery strategy that provides a fallback service
class FallbackRecoveryStrategy<T extends Object> extends ServiceRecoveryStrategy {
  const FallbackRecoveryStrategy(this.fallbackProvider);
  
  final T Function() fallbackProvider;
  
  @override
  RecoveryStrategy get strategyType => RecoveryStrategy.fallback;
  
  @override
  Future<bool> recover(GetIt getIt, Type serviceType) async {
    try {
      final fallback = fallbackProvider();
      getIt.registerSingleton<T>(fallback);
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Recovery strategy that resets a service
class ResetRecoveryStrategy extends ServiceRecoveryStrategy {
  const ResetRecoveryStrategy(this.resetFunction);
  
  final Future<void> Function(GetIt getIt, Type serviceType) resetFunction;
  
  @override
  RecoveryStrategy get strategyType => RecoveryStrategy.reset;
  
  @override
  Future<bool> recover(GetIt getIt, Type serviceType) async {
    try {
      await resetFunction(getIt, serviceType);
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Types of recovery strategies
enum RecoveryStrategy {
  none,
  retry,
  reregister,
  fallback,
  reset,
}

/// Result of a recovery attempt
class RecoveryResult {
  const RecoveryResult({
    required this.serviceType,
    required this.serviceName,
    required this.isSuccessful,
    required this.recoveryStrategy,
    required this.timestamp,
    this.error,
    this.recoveryDuration,
  });
  
  final Type serviceType;
  final String serviceName;
  final bool isSuccessful;
  final RecoveryStrategy recoveryStrategy;
  final String? error;
  final Duration? recoveryDuration;
  final DateTime timestamp;
  
  Map<String, dynamic> toMap() {
    return {
      'service_type': serviceName,
      'is_successful': isSuccessful,
      'recovery_strategy': recoveryStrategy.name,
      'error': error,
      'recovery_duration_ms': recoveryDuration?.inMilliseconds,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Exception for service recovery failures
class ServiceRecoveryException implements Exception {
  const ServiceRecoveryException(this.message, this.details);
  
  final String message;
  final String details;
  
  @override
  String toString() => 'ServiceRecoveryException: $message ($details)';
}

/// Exception for service not found
class ServiceNotFoundException implements Exception {
  const ServiceNotFoundException(this.message);
  
  final String message;
  
  @override
  String toString() => 'ServiceNotFoundException: $message';
}
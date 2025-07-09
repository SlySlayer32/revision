import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:revision/core/utils/enhanced_logger.dart';
import 'package:revision/core/services/error_monitoring/production_error_monitor_v2.dart';
import 'service_locator_validator.dart';
import 'service_health_monitor.dart';
import 'service_recovery_manager.dart';

/// Enhanced service locator with validation, health monitoring, and recovery
class EnhancedServiceLocator {
  EnhancedServiceLocator._({
    required GetIt getIt,
    required EnhancedLogger logger,
  }) : _getIt = getIt,
       _logger = logger;
  
  static EnhancedServiceLocator? _instance;
  
  static EnhancedServiceLocator get instance {
    if (_instance == null) {
      throw StateError('EnhancedServiceLocator not initialized. Call initialize() first.');
    }
    return _instance!;
  }
  
  /// Initialize the enhanced service locator
  static Future<void> initialize({
    required GetIt getIt,
    EnhancedLogger? logger,
  }) async {
    final effectiveLogger = logger ?? EnhancedLogger();
    
    _instance = EnhancedServiceLocator._(
      getIt: getIt,
      logger: effectiveLogger,
    );
    
    // Initialize subsystems
    ServiceHealthMonitor.initialize(getIt: getIt, logger: effectiveLogger);
    ServiceRecoveryManager.initialize(getIt: getIt, logger: effectiveLogger);
    
    effectiveLogger.info('EnhancedServiceLocator initialized', operation: 'ENHANCED_SERVICE_LOCATOR_INIT');
  }
  
  final GetIt _getIt;
  final EnhancedLogger _logger;
  
  /// Validate all dependencies and start monitoring
  Future<ServiceLocatorInitResult> initializeWithValidation() async {
    _logger.info('Starting service locator initialization with validation', operation: 'SERVICE_LOCATOR_INIT');
    
    final startTime = DateTime.now();
    
    try {
      // Step 1: Validate all dependencies
      final validationResult = await ServiceLocatorValidator.validateDependencies(_getIt);
      
      if (!validationResult.isValid) {
        _logger.error(
          'Service locator validation failed',
          operation: 'SERVICE_LOCATOR_VALIDATION',
          context: validationResult.getSummary(),
        );
        
        return ServiceLocatorInitResult(
          isSuccessful: false,
          validationResult: validationResult,
          initializationDuration: DateTime.now().difference(startTime),
          timestamp: DateTime.now(),
          error: 'Dependency validation failed',
        );
      }
      
      // Step 2: Start health monitoring
      ServiceHealthMonitor.instance.startHealthMonitoring();
      
      // Step 3: Perform initial health check
      final healthReport = await ServiceHealthMonitor.instance.performHealthCheck();
      
      // Step 4: Register default recovery strategies
      _registerDefaultRecoveryStrategies();
      
      final initResult = ServiceLocatorInitResult(
        isSuccessful: true,
        validationResult: validationResult,
        healthReport: healthReport,
        initializationDuration: DateTime.now().difference(startTime),
        timestamp: DateTime.now(),
      );
      
      _logger.info(
        'Service locator initialization completed successfully',
        operation: 'SERVICE_LOCATOR_INIT',
        context: {
          'initialization_duration_ms': initResult.initializationDuration.inMilliseconds,
          'validation_passed': validationResult.isValid,
          'health_score': healthReport.overallHealthScore,
          'total_services': validationResult.validationResults.length,
        },
      );
      
      return initResult;
    } catch (e, stackTrace) {
      _logger.error(
        'Service locator initialization failed: $e',
        operation: 'SERVICE_LOCATOR_INIT',
        error: e,
        stackTrace: stackTrace,
      );
      
      ProductionErrorMonitorV2.instance.recordError(
        error: e,
        stackTrace: stackTrace,
        context: 'EnhancedServiceLocator.initializeWithValidation',
      );
      
      return ServiceLocatorInitResult(
        isSuccessful: false,
        initializationDuration: DateTime.now().difference(startTime),
        timestamp: DateTime.now(),
        error: e.toString(),
      );
    }
  }
  
  /// Get a service with automatic recovery on failure
  Future<T?> getServiceSafely<T extends Object>() async {
    try {
      return await ServiceRecoveryManager.instance.getServiceWithRecovery<T>();
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to get service safely: ${T.toString()}',
        operation: 'GET_SERVICE_SAFELY',
        error: e,
        stackTrace: stackTrace,
      );
      
      ProductionErrorMonitorV2.instance.recordError(
        error: e,
        stackTrace: stackTrace,
        context: 'EnhancedServiceLocator.getServiceSafely',
        metadata: {'service_type': T.toString()},
      );
      
      return null;
    }
  }
  
  /// Execute an operation with automatic service recovery
  Future<R?> executeWithServiceRecovery<T extends Object, R>(
    Future<R> Function(T service) operation,
  ) async {
    try {
      return await ServiceRecoveryManager.instance.executeWithRecovery<T, R>(operation);
    } catch (e, stackTrace) {
      _logger.error(
        'Operation failed with service recovery: ${T.toString()}',
        operation: 'EXECUTE_WITH_SERVICE_RECOVERY',
        error: e,
        stackTrace: stackTrace,
      );
      
      ProductionErrorMonitorV2.instance.recordError(
        error: e,
        stackTrace: stackTrace,
        context: 'EnhancedServiceLocator.executeWithServiceRecovery',
        metadata: {'service_type': T.toString()},
      );
      
      return null;
    }
  }
  
  /// Register a recovery strategy for a service
  void registerRecoveryStrategy<T extends Object>(ServiceRecoveryStrategy strategy) {
    ServiceRecoveryManager.instance.registerRecoveryStrategy<T>(strategy);
  }
  
  /// Get current system health status
  Future<ServiceHealthReport> getSystemHealth() async {
    return ServiceHealthMonitor.instance.performHealthCheck();
  }
  
  /// Get health status for a specific service
  ServiceHealthResult? getServiceHealth<T extends Object>() {
    return ServiceHealthMonitor.instance.getServiceHealth<T>();
  }
  
  /// Check if a service is currently failing
  bool isServiceFailing<T extends Object>() {
    return ServiceHealthMonitor.instance.isServiceFailed<T>();
  }
  
  /// Get comprehensive service locator statistics
  Map<String, dynamic> getStatistics() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'health_monitoring': ServiceHealthMonitor.instance._lastHealthResults.length,
      'recovery_statistics': ServiceRecoveryManager.instance.getRecoveryStatistics(),
      'failing_services': ServiceHealthMonitor.instance.getFailingServices()
          .map((t) => t.toString()).toList(),
    };
  }
  
  /// Shutdown the enhanced service locator
  void shutdown() {
    _logger.info('Shutting down enhanced service locator', operation: 'SERVICE_LOCATOR_SHUTDOWN');
    
    try {
      // Stop health monitoring
      ServiceHealthMonitor.instance.stopHealthMonitoring();
      
      // Dispose resources
      ServiceHealthMonitor.instance.dispose();
      ServiceRecoveryManager.instance.dispose();
      
      _logger.info('Enhanced service locator shutdown completed', operation: 'SERVICE_LOCATOR_SHUTDOWN');
    } catch (e, stackTrace) {
      _logger.error(
        'Error during service locator shutdown: $e',
        operation: 'SERVICE_LOCATOR_SHUTDOWN',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
  
  // Private methods
  
  void _registerDefaultRecoveryStrategies() {
    _logger.debug('Registering default recovery strategies', operation: 'REGISTER_RECOVERY_STRATEGIES');
    
    // Add default recovery strategies for common service types
    // This is where you would register specific recovery strategies for your services
    
    // Example: Add recovery strategies for critical services
    // ServiceRecoveryManager.instance.registerRecoveryStrategy<AuthRepository>(
    //   ReregisterRecoveryStrategy(() async => _registerAuthRepository()),
    // );
  }
}

/// Result of service locator initialization
class ServiceLocatorInitResult {
  const ServiceLocatorInitResult({
    required this.isSuccessful,
    required this.initializationDuration,
    required this.timestamp,
    this.validationResult,
    this.healthReport,
    this.error,
  });
  
  final bool isSuccessful;
  final ValidationResult? validationResult;
  final ServiceHealthReport? healthReport;
  final Duration initializationDuration;
  final DateTime timestamp;
  final String? error;
  
  /// Get summary of initialization results
  Map<String, dynamic> getSummary() {
    return {
      'is_successful': isSuccessful,
      'initialization_duration_ms': initializationDuration.inMilliseconds,
      'timestamp': timestamp.toIso8601String(),
      'error': error,
      'validation_summary': validationResult?.getSummary(),
      'health_summary': healthReport?.toMap(),
    };
  }
}

/// Extension methods for enhanced service locator
extension EnhancedServiceLocatorExtensions on GetIt {
  /// Get a service with automatic recovery
  Future<T?> getSafely<T extends Object>() async {
    return EnhancedServiceLocator.instance.getServiceSafely<T>();
  }
  
  /// Execute an operation with automatic service recovery
  Future<R?> executeWithRecovery<T extends Object, R>(
    Future<R> Function(T service) operation,
  ) async {
    return EnhancedServiceLocator.instance.executeWithServiceRecovery<T, R>(operation);
  }
  
  /// Check if a service is currently healthy
  bool isServiceHealthy<T extends Object>() {
    final health = EnhancedServiceLocator.instance.getServiceHealth<T>();
    return health?.isHealthy ?? false;
  }
}
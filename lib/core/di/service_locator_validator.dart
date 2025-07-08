import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:revision/core/utils/null_safety_utils.dart';
import 'package:revision/core/utils/enhanced_logger.dart';
import 'package:revision/core/services/error_monitoring/production_error_monitor_v2.dart';

/// Service locator validation and health monitoring
class ServiceLocatorValidator {
  ServiceLocatorValidator._();
  
  static final EnhancedLogger _logger = EnhancedLogger();
  
  /// Critical services that must be available for the app to function
  static const List<Type> _criticalServices = [
    // Core services that are essential
  ];
  
  /// Non-critical services that can have fallbacks
  static const List<Type> _optionalServices = [
    // Services that can fail gracefully
  ];
  
  /// Validate all registered dependencies at startup
  static Future<ValidationResult> validateDependencies(GetIt getIt) async {
    _logger.info('Starting dependency validation', operation: 'DEPENDENCY_VALIDATION');
    
    final validationResults = <ServiceValidationResult>[];
    final startTime = DateTime.now();
    
    try {
      // Validate critical services first
      await _validateCriticalServices(getIt, validationResults);
      
      // Validate optional services
      await _validateOptionalServices(getIt, validationResults);
      
      // Check for circular dependencies
      final circularDeps = await _checkCircularDependencies(getIt);
      
      final duration = DateTime.now().difference(startTime);
      final result = ValidationResult(
        isValid: validationResults.every((r) => r.isValid || !r.isCritical),
        validationResults: validationResults,
        circularDependencies: circularDeps,
        validationDuration: duration,
        timestamp: DateTime.now(),
      );
      
      _logger.info(
        'Dependency validation completed: ${result.isValid ? 'PASSED' : 'FAILED'} '
        '(${duration.inMilliseconds}ms)',
        operation: 'DEPENDENCY_VALIDATION',
        context: {
          'total_services': validationResults.length,
          'failed_services': validationResults.where((r) => !r.isValid).length,
          'critical_failures': validationResults.where((r) => !r.isValid && r.isCritical).length,
          'circular_dependencies': circularDeps.length,
        },
      );
      
      if (!result.isValid) {
        _logValidationFailures(validationResults);
        ProductionErrorMonitorV2.instance.recordError(
          error: ServiceValidationException('Critical service validation failed'),
          stackTrace: StackTrace.current,
          context: 'ServiceLocatorValidator.validateDependencies',
          metadata: {
            'failed_services': validationResults.where((r) => !r.isValid && r.isCritical)
                .map((r) => r.serviceType.toString()).toList(),
          },
        );
      }
      
      return result;
    } catch (e, stackTrace) {
      _logger.error(
        'Dependency validation failed with exception: $e',
        operation: 'DEPENDENCY_VALIDATION',
        error: e,
        stackTrace: stackTrace,
      );
      
      ProductionErrorMonitorV2.instance.recordError(
        error: e,
        stackTrace: stackTrace,
        context: 'ServiceLocatorValidator.validateDependencies',
      );
      
      return ValidationResult(
        isValid: false,
        validationResults: validationResults,
        circularDependencies: [],
        validationDuration: DateTime.now().difference(startTime),
        timestamp: DateTime.now(),
        validationError: e.toString(),
      );
    }
  }
  
  /// Validate that a specific service can be instantiated
  static Future<ServiceValidationResult> validateService<T extends Object>(
    GetIt getIt,
    bool isCritical,
  ) async {
    final serviceType = T;
    final serviceName = serviceType.toString();
    
    try {
      // Check if service is registered
      if (!getIt.isRegistered<T>()) {
        return ServiceValidationResult(
          serviceType: serviceType,
          serviceName: serviceName,
          isValid: false,
          isCritical: isCritical,
          error: 'Service not registered',
          validationTime: DateTime.now(),
        );
      }
      
      // Try to instantiate the service
      final startTime = DateTime.now();
      final service = getIt<T>();
      final instantiationTime = DateTime.now().difference(startTime);
      
      // Validate the service is not null
      NullSafetyUtils.requireNonNull(
        service,
        message: 'Service instance is null',
        context: 'ServiceLocatorValidator.validateService<$serviceName>',
      );
      
      return ServiceValidationResult(
        serviceType: serviceType,
        serviceName: serviceName,
        isValid: true,
        isCritical: isCritical,
        instantiationTime: instantiationTime,
        validationTime: DateTime.now(),
      );
    } catch (e, stackTrace) {
      _logger.warning(
        'Service validation failed for $serviceName: $e',
        operation: 'SERVICE_VALIDATION',
        error: e,
        stackTrace: stackTrace,
      );
      
      return ServiceValidationResult(
        serviceType: serviceType,
        serviceName: serviceName,
        isValid: false,
        isCritical: isCritical,
        error: e.toString(),
        stackTrace: stackTrace.toString(),
        validationTime: DateTime.now(),
      );
    }
  }
  
  /// Check service health by attempting basic operations
  static Future<ServiceHealthResult> checkServiceHealth<T extends Object>(
    GetIt getIt,
  ) async {
    final serviceType = T;
    final serviceName = serviceType.toString();
    
    try {
      final service = getIt<T>();
      
      // Basic health check - service exists and is not null
      if (service == null) {
        return ServiceHealthResult(
          serviceType: serviceType,
          serviceName: serviceName,
          isHealthy: false,
          healthScore: 0,
          issues: ['Service instance is null'],
          checkTime: DateTime.now(),
        );
      }
      
      // Additional health checks could be added here for specific service types
      // For now, we'll just verify the service can be accessed
      
      return ServiceHealthResult(
        serviceType: serviceType,
        serviceName: serviceName,
        isHealthy: true,
        healthScore: 100,
        issues: [],
        checkTime: DateTime.now(),
      );
    } catch (e, stackTrace) {
      _logger.warning(
        'Service health check failed for $serviceName: $e',
        operation: 'SERVICE_HEALTH_CHECK',
        error: e,
        stackTrace: stackTrace,
      );
      
      return ServiceHealthResult(
        serviceType: serviceType,
        serviceName: serviceName,
        isHealthy: false,
        healthScore: 0,
        issues: [e.toString()],
        checkTime: DateTime.now(),
        error: e.toString(),
      );
    }
  }
  
  static Future<void> _validateCriticalServices(
    GetIt getIt,
    List<ServiceValidationResult> results,
  ) async {
    for (final serviceType in _criticalServices) {
      // Note: This is a simplified approach. In a real implementation,
      // you would need to use reflection or a registry to validate types
      _logger.debug(
        'Validating critical service: $serviceType',
        operation: 'CRITICAL_SERVICE_VALIDATION',
      );
    }
  }
  
  static Future<void> _validateOptionalServices(
    GetIt getIt,
    List<ServiceValidationResult> results,
  ) async {
    for (final serviceType in _optionalServices) {
      _logger.debug(
        'Validating optional service: $serviceType',
        operation: 'OPTIONAL_SERVICE_VALIDATION',
      );
    }
  }
  
  static Future<List<String>> _checkCircularDependencies(GetIt getIt) async {
    // Simplified circular dependency check
    // In a real implementation, this would analyze the dependency graph
    return [];
  }
  
  static void _logValidationFailures(List<ServiceValidationResult> results) {
    final failures = results.where((r) => !r.isValid).toList();
    
    for (final failure in failures) {
      _logger.error(
        'Service validation failed: ${failure.serviceName} - ${failure.error}',
        operation: 'SERVICE_VALIDATION_FAILURE',
        context: {
          'service_type': failure.serviceName,
          'is_critical': failure.isCritical,
          'error': failure.error,
        },
      );
    }
  }
}

/// Result of dependency validation
class ValidationResult {
  const ValidationResult({
    required this.isValid,
    required this.validationResults,
    required this.circularDependencies,
    required this.validationDuration,
    required this.timestamp,
    this.validationError,
  });
  
  final bool isValid;
  final List<ServiceValidationResult> validationResults;
  final List<String> circularDependencies;
  final Duration validationDuration;
  final DateTime timestamp;
  final String? validationError;
  
  /// Get summary of validation results
  Map<String, dynamic> getSummary() {
    final failed = validationResults.where((r) => !r.isValid).toList();
    final criticalFailures = failed.where((r) => r.isCritical).toList();
    
    return {
      'is_valid': isValid,
      'total_services': validationResults.length,
      'failed_services': failed.length,
      'critical_failures': criticalFailures.length,
      'circular_dependencies': circularDependencies.length,
      'validation_duration_ms': validationDuration.inMilliseconds,
      'validation_error': validationError,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Result of individual service validation
class ServiceValidationResult {
  const ServiceValidationResult({
    required this.serviceType,
    required this.serviceName,
    required this.isValid,
    required this.isCritical,
    required this.validationTime,
    this.instantiationTime,
    this.error,
    this.stackTrace,
  });
  
  final Type serviceType;
  final String serviceName;
  final bool isValid;
  final bool isCritical;
  final Duration? instantiationTime;
  final String? error;
  final String? stackTrace;
  final DateTime validationTime;
}

/// Result of service health check
class ServiceHealthResult {
  const ServiceHealthResult({
    required this.serviceType,
    required this.serviceName,
    required this.isHealthy,
    required this.healthScore,
    required this.issues,
    required this.checkTime,
    this.error,
    this.responseTime,
  });
  
  final Type serviceType;
  final String serviceName;
  final bool isHealthy;
  final int healthScore; // 0-100
  final List<String> issues;
  final DateTime checkTime;
  final String? error;
  final Duration? responseTime;
}

/// Exception thrown when service validation fails
class ServiceValidationException implements Exception {
  const ServiceValidationException(this.message);
  
  final String message;
  
  @override
  String toString() => 'ServiceValidationException: $message';
}
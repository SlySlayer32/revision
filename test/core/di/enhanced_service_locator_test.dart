import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:revision/core/di/service_locator_validator.dart';
import 'package:revision/core/di/service_health_monitor.dart';
import 'package:revision/core/di/service_recovery_manager.dart';
import 'package:revision/core/di/enhanced_service_locator.dart';
import 'package:revision/core/utils/enhanced_logger.dart';
import 'package:revision/core/services/error_monitoring/production_error_monitor_v2.dart';
import 'package:revision/core/services/error_monitoring/error_monitoring_config.dart';

void main() {
  group('Enhanced Service Locator Tests', () {
    late GetIt testGetIt;
    late EnhancedLogger testLogger;

    setUp(() {
      testGetIt = GetIt.instance;
      testLogger = EnhancedLogger();
      
      // Reset GetIt for each test
      testGetIt.reset();
      
      // Initialize error monitoring
      ProductionErrorMonitorV2.initialize(
        config: const TestErrorMonitoringConfig(),
        logger: testLogger,
      );
    });

    tearDown(() {
      testGetIt.reset();
    });

    group('ServiceLocatorValidator', () {
      test('should validate empty service locator', () async {
        // Act
        final result = await ServiceLocatorValidator.validateDependencies(testGetIt);

        // Assert
        expect(result.isValid, isTrue);
        expect(result.validationResults, isEmpty);
        expect(result.circularDependencies, isEmpty);
        expect(result.validationError, isNull);
      });

      test('should validate service registration', () async {
        // Arrange
        testGetIt.registerSingleton<String>('test_service');

        // Act
        final result = await ServiceLocatorValidator.validateService<String>(testGetIt, true);

        // Assert
        expect(result.isValid, isTrue);
        expect(result.serviceName, equals('String'));
        expect(result.isCritical, isTrue);
        expect(result.error, isNull);
      });

      test('should detect unregistered service', () async {
        // Act
        final result = await ServiceLocatorValidator.validateService<String>(testGetIt, false);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.serviceName, equals('String'));
        expect(result.isCritical, isFalse);
        expect(result.error, equals('Service not registered'));
      });
    });

    group('ServiceHealthMonitor', () {
      test('should initialize health monitor', () async {
        // Act
        ServiceHealthMonitor.initialize(getIt: testGetIt, logger: testLogger);

        // Assert
        expect(ServiceHealthMonitor.instance, isNotNull);
      });

      test('should perform health check', () async {
        // Arrange
        ServiceHealthMonitor.initialize(getIt: testGetIt, logger: testLogger);
        testGetIt.registerSingleton<String>('healthy_service');

        // Act
        final report = await ServiceHealthMonitor.instance.performHealthCheck();

        // Assert
        expect(report, isNotNull);
        expect(report.isHealthy, isTrue);
        expect(report.overallHealthScore, greaterThan(0));
        expect(report.error, isNull);
      });

      test('should track service failures', () async {
        // Arrange
        ServiceHealthMonitor.initialize(getIt: testGetIt, logger: testLogger);

        // Act
        final isFailedBefore = ServiceHealthMonitor.instance.isServiceFailed<String>();
        
        // Simulate failure - in a real test, you'd trigger an actual failure
        // For now, we'll just test the API
        
        // Assert
        expect(isFailedBefore, isFalse);
      });
    });

    group('ServiceRecoveryManager', () {
      test('should initialize recovery manager', () async {
        // Act
        ServiceRecoveryManager.initialize(getIt: testGetIt, logger: testLogger);

        // Assert
        expect(ServiceRecoveryManager.instance, isNotNull);
      });

      test('should register recovery strategy', () async {
        // Arrange
        ServiceRecoveryManager.initialize(getIt: testGetIt, logger: testLogger);
        final strategy = TestRecoveryStrategy();

        // Act
        ServiceRecoveryManager.instance.registerRecoveryStrategy<String>(strategy);

        // Assert
        final stats = ServiceRecoveryManager.instance.getRecoveryStatistics();
        expect(stats['registered_strategies'], equals(1));
      });

      test('should get service safely', () async {
        // Arrange
        ServiceRecoveryManager.initialize(getIt: testGetIt, logger: testLogger);
        testGetIt.registerSingleton<String>('safe_service');

        // Act
        final service = await ServiceRecoveryManager.instance.getServiceWithRecovery<String>();

        // Assert
        expect(service, equals('safe_service'));
      });

      test('should handle missing service gracefully', () async {
        // Arrange
        ServiceRecoveryManager.initialize(getIt: testGetIt, logger: testLogger);

        // Act
        final service = await ServiceRecoveryManager.instance.getServiceWithRecovery<String>();

        // Assert
        expect(service, isNull);
      });
    });

    group('EnhancedServiceLocator', () {
      test('should initialize enhanced service locator', () async {
        // Act
        await EnhancedServiceLocator.initialize(getIt: testGetIt, logger: testLogger);

        // Assert
        expect(EnhancedServiceLocator.instance, isNotNull);
      });

      test('should initialize with validation', () async {
        // Arrange
        await EnhancedServiceLocator.initialize(getIt: testGetIt, logger: testLogger);
        testGetIt.registerSingleton<String>('test_service');

        // Act
        final result = await EnhancedServiceLocator.instance.initializeWithValidation();

        // Assert
        expect(result.isSuccessful, isTrue);
        expect(result.error, isNull);
        expect(result.validationResult, isNotNull);
      });

      test('should get service safely', () async {
        // Arrange
        await EnhancedServiceLocator.initialize(getIt: testGetIt, logger: testLogger);
        testGetIt.registerSingleton<String>('safe_service');

        // Act
        final service = await EnhancedServiceLocator.instance.getServiceSafely<String>();

        // Assert
        expect(service, equals('safe_service'));
      });

      test('should handle missing service gracefully', () async {
        // Arrange
        await EnhancedServiceLocator.initialize(getIt: testGetIt, logger: testLogger);

        // Act
        final service = await EnhancedServiceLocator.instance.getServiceSafely<String>();

        // Assert
        expect(service, isNull);
      });

      test('should get system health', () async {
        // Arrange
        await EnhancedServiceLocator.initialize(getIt: testGetIt, logger: testLogger);
        testGetIt.registerSingleton<String>('healthy_service');

        // Act
        final health = await EnhancedServiceLocator.instance.getSystemHealth();

        // Assert
        expect(health, isNotNull);
        expect(health.isHealthy, isTrue);
        expect(health.overallHealthScore, greaterThan(0));
      });

      test('should shutdown gracefully', () async {
        // Arrange
        await EnhancedServiceLocator.initialize(getIt: testGetIt, logger: testLogger);

        // Act & Assert - should not throw
        expect(() => EnhancedServiceLocator.instance.shutdown(), returnsNormally);
      });
    });
  });
}

/// Test recovery strategy for testing purposes
class TestRecoveryStrategy extends ServiceRecoveryStrategy {
  @override
  RecoveryStrategy get strategyType => RecoveryStrategy.retry;

  @override
  Future<bool> recover(GetIt getIt, Type serviceType) async {
    // Simple test recovery - just return true
    return true;
  }
}
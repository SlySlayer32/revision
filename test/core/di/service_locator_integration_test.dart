import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:revision/core/di/service_locator.dart';
import 'package:revision/core/di/enhanced_service_locator.dart';

/// Integration test to demonstrate the enhanced service locator functionality
void main() {
  group('Service Locator Integration Test', () {
    setUp(() {
      // Reset GetIt before each test
      GetIt.instance.reset();
    });

    tearDown(() {
      // Clean shutdown after each test
      shutdownServiceLocator();
    });

    test('should setup service locator and initialize with validation', () async {
      // Act
      await setupServiceLocator();
      await EnhancedServiceLocator.initialize(getIt: GetIt.instance);
      final initResult = await EnhancedServiceLocator.instance.initializeWithValidation();

      // Assert
      expect(initResult.isSuccessful, isTrue);
      expect(initResult.validationResult?.isValid, isTrue);
      expect(initResult.healthReport?.isHealthy, isTrue);
    });

    test('should demonstrate health monitoring', () async {
      // Arrange
      await setupServiceLocator();
      await EnhancedServiceLocator.initialize(getIt: GetIt.instance);
      await EnhancedServiceLocator.instance.initializeWithValidation();

      // Act
      final healthReport = await EnhancedServiceLocator.instance.getSystemHealth();

      // Assert
      expect(healthReport, isNotNull);
      expect(healthReport.isHealthy, isTrue);
      expect(healthReport.overallHealthScore, greaterThan(0));
    });

    test('should demonstrate service recovery', () async {
      // Arrange
      await setupServiceLocator();
      await EnhancedServiceLocator.initialize(getIt: GetIt.instance);
      await EnhancedServiceLocator.instance.initializeWithValidation();

      // Act - try to get a service that doesn't exist
      final service = await EnhancedServiceLocator.instance.getServiceSafely<String>();

      // Assert - should handle gracefully
      expect(service, isNull);
    });

    test('should demonstrate statistics collection', () async {
      // Arrange
      await setupServiceLocator();
      await EnhancedServiceLocator.initialize(getIt: GetIt.instance);
      await EnhancedServiceLocator.instance.initializeWithValidation();

      // Act
      final stats = EnhancedServiceLocator.instance.getStatistics();

      // Assert
      expect(stats, isNotNull);
      expect(stats['timestamp'], isNotNull);
      expect(stats['recovery_statistics'], isNotNull);
      expect(stats['health_monitoring'], isNotNull);
    });

    test('should demonstrate graceful shutdown', () async {
      // Arrange
      await setupServiceLocator();
      await EnhancedServiceLocator.initialize(getIt: GetIt.instance);
      await EnhancedServiceLocator.instance.initializeWithValidation();

      // Act & Assert - should not throw
      expect(() => shutdownServiceLocator(), returnsNormally);
    });
  });
}

/// Example of how to use the enhanced service locator in production
class ServiceLocatorExample {
  static Future<void> demonstrateUsage() async {
    // Initialize with validation and monitoring
    await setupServiceLocator();
    await EnhancedServiceLocator.initialize(getIt: GetIt.instance);
    final initResult = await EnhancedServiceLocator.instance.initializeWithValidation();

    if (!initResult.isSuccessful) {
      print('Service locator initialization failed');
      return;
    }

    // Get a service safely with automatic recovery
    final service = await EnhancedServiceLocator.instance.getServiceSafely<String>();
    
    if (service != null) {
      print('Service retrieved successfully: $service');
    } else {
      print('Service not available or recovery failed');
    }

    // Check system health
    final healthReport = await EnhancedServiceLocator.instance.getSystemHealth();
    print('System health score: ${healthReport.overallHealthScore}');
    
    if (!healthReport.isHealthy) {
      print('Unhealthy services: ${healthReport.unhealthyServices.length}');
    }

    // Get statistics
    final stats = EnhancedServiceLocator.instance.getStatistics();
    print('Service locator statistics: $stats');

    // Shutdown gracefully
    shutdownServiceLocator();
  }
}

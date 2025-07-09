# Enhanced Service Locator Usage Guide

## Overview

The enhanced service locator provides comprehensive dependency validation, health monitoring, and automatic recovery mechanisms for the Revision app. This guide shows how to use the new features.

## Key Features

✅ **Dependency Validation** - Validates all services at startup
✅ **Health Monitoring** - Continuous service health checks
✅ **Automatic Recovery** - Fallback mechanisms for failed services
✅ **Enhanced Logging** - Detailed logging and error tracking
✅ **Lifecycle Management** - Proper disposal and cleanup

## Basic Usage

### 1. Initialize Service Locator

```dart
import 'package:revision/core/di/service_locator.dart';

// Initialize with validation and monitoring (recommended)
await setupServiceLocator(enableValidation: true);

// Or initialize without enhanced features
await setupServiceLocator(enableValidation: false);
```

### 2. Get Services Safely

```dart
import 'package:revision/core/di/enhanced_service_locator.dart';

// Get a service with automatic recovery
final authService = await EnhancedServiceLocator.instance.getServiceSafely<AuthRepository>();

if (authService != null) {
  // Use the service
  final user = await authService.getCurrentUser();
} else {
  // Handle service unavailability
  print('Auth service is not available');
}
```

### 3. Execute Operations with Recovery

```dart
// Execute an operation with automatic service recovery
final result = await EnhancedServiceLocator.instance.executeWithServiceRecovery<AuthRepository, User>(
  (authService) async {
    return await authService.signIn(email, password);
  },
);

if (result != null) {
  // Operation succeeded
  print('User signed in: ${result.email}');
} else {
  // Operation failed even with recovery
  print('Sign in failed');
}
```

### 4. Monitor System Health

```dart
// Get current system health
final healthReport = await EnhancedServiceLocator.instance.getSystemHealth();

print('System health score: ${healthReport.overallHealthScore}');
print('Is healthy: ${healthReport.isHealthy}');

if (!healthReport.isHealthy) {
  print('Unhealthy services: ${healthReport.unhealthyServices.length}');
  for (final service in healthReport.unhealthyServices) {
    print('- ${service.serviceName}: ${service.issues.join(', ')}');
  }
}
```

### 5. Check Individual Service Health

```dart
// Check if a specific service is healthy
final isHealthy = EnhancedServiceLocator.instance.isServiceHealthy<AuthRepository>();

if (!isHealthy) {
  print('AuthRepository is not healthy');
  
  // Get detailed health information
  final health = EnhancedServiceLocator.instance.getServiceHealth<AuthRepository>();
  if (health != null) {
    print('Health score: ${health.healthScore}');
    print('Issues: ${health.issues.join(', ')}');
  }
}
```

### 6. Register Recovery Strategies

```dart
// Register a custom recovery strategy
EnhancedServiceLocator.instance.registerRecoveryStrategy<AuthRepository>(
  ReregisterRecoveryStrategy((getIt) async {
    // Custom recovery logic
    if (getIt.isRegistered<AuthRepository>()) {
      getIt.unregister<AuthRepository>();
    }
    
    getIt.registerLazySingleton<AuthRepository>(() {
      return FirebaseAuthenticationRepository(
        firebaseAuthDataSource: getIt<FirebaseAuthDataSource>(),
      );
    });
  }),
);
```

### 7. Get Statistics and Monitoring Data

```dart
// Get comprehensive statistics
final stats = EnhancedServiceLocator.instance.getStatistics();

print('Health monitoring active: ${stats['health_monitoring']}');
print('Recovery statistics: ${stats['recovery_statistics']}');
print('Failing services: ${stats['failing_services']}');
```

### 8. Proper Shutdown

```dart
// Always shutdown gracefully
shutdownServiceLocator();
```

## Recovery Strategies

### Built-in Recovery Strategies

1. **ReregisterRecoveryStrategy** - Re-registers a service with a fresh instance
2. **FallbackRecoveryStrategy** - Provides a fallback implementation
3. **ResetRecoveryStrategy** - Resets a service to its initial state

### Example: Custom Recovery Strategy

```dart
class CustomAuthRecoveryStrategy extends ServiceRecoveryStrategy {
  @override
  RecoveryStrategy get strategyType => RecoveryStrategy.reset;

  @override
  Future<bool> recover(GetIt getIt, Type serviceType) async {
    try {
      // Custom recovery logic for AuthRepository
      final authDataSource = getIt<FirebaseAuthDataSource>();
      
      // Reset any cached state
      await authDataSource.signOut();
      
      // Re-initialize the service
      if (getIt.isRegistered<AuthRepository>()) {
        getIt.unregister<AuthRepository>();
      }
      
      getIt.registerLazySingleton<AuthRepository>(() {
        return FirebaseAuthenticationRepository(
          firebaseAuthDataSource: authDataSource,
        );
      });
      
      return true;
    } catch (e) {
      return false;
    }
  }
}

// Register the custom strategy
EnhancedServiceLocator.instance.registerRecoveryStrategy<AuthRepository>(
  CustomAuthRecoveryStrategy(),
);
```

## Error Handling

### Automatic Error Recording

All service failures are automatically recorded in the error monitoring system:

```dart
// Service failures are automatically tracked
final service = await EnhancedServiceLocator.instance.getServiceSafely<GeminiAIService>();

// If this fails, it's automatically recorded with:
// - Error details
// - Stack trace
// - Service context
// - Recovery attempts
```

### Manual Error Handling

```dart
try {
  final result = await someOperation();
} catch (e, stackTrace) {
  // Errors are automatically recorded by the enhanced service locator
  // But you can also record additional context
  ProductionErrorMonitorV2.instance.recordError(
    error: e,
    stackTrace: stackTrace,
    context: 'CustomOperation',
    metadata: {'additional_context': 'value'},
  );
}
```

## Best Practices

### 1. Always Use Enhanced Features in Production

```dart
// ✅ Good - Enable validation and monitoring
await setupServiceLocator(enableValidation: true);

// ❌ Avoid - Only for testing or development
await setupServiceLocator(enableValidation: false);
```

### 2. Use Safe Service Access

```dart
// ✅ Good - Automatic recovery
final service = await EnhancedServiceLocator.instance.getServiceSafely<AuthRepository>();

// ❌ Avoid - Direct GetIt access (no recovery)
final service = GetIt.instance<AuthRepository>();
```

### 3. Register Recovery Strategies for Critical Services

```dart
// Register recovery strategies for all critical services
EnhancedServiceLocator.instance.registerRecoveryStrategy<AuthRepository>(strategy);
EnhancedServiceLocator.instance.registerRecoveryStrategy<GeminiAIService>(strategy);
EnhancedServiceLocator.instance.registerRecoveryStrategy<FirebaseAuthDataSource>(strategy);
```

### 4. Monitor Health Regularly

```dart
// Check system health before critical operations
final healthReport = await EnhancedServiceLocator.instance.getSystemHealth();

if (healthReport.isHealthy) {
  // Proceed with operation
} else {
  // Show user-friendly error or wait for recovery
}
```

### 5. Always Shutdown Gracefully

```dart
// In your app's dispose method
@override
void dispose() {
  shutdownServiceLocator();
  super.dispose();
}
```

## Configuration Options

The enhanced service locator uses the existing error monitoring configuration:

```dart
// Production configuration (default)
ProductionErrorMonitorV2.initialize(
  config: const DefaultErrorMonitoringConfig(),
);

// Test configuration (shorter intervals)
ProductionErrorMonitorV2.initialize(
  config: const TestErrorMonitoringConfig(),
);
```

## Integration with Existing Code

The enhanced service locator is backward compatible. Existing code will continue to work without changes:

```dart
// Existing code still works
final authRepository = GetIt.instance<AuthRepository>();

// But new code should use enhanced features
final authRepository = await EnhancedServiceLocator.instance.getServiceSafely<AuthRepository>();
```

## Troubleshooting

### Common Issues

1. **Service Not Available**: Check if the service is registered and healthy
2. **Recovery Failures**: Verify recovery strategies are properly registered
3. **Health Check Failures**: Review service dependencies and initialization

### Debug Information

```dart
// Get detailed statistics for debugging
final stats = EnhancedServiceLocator.instance.getStatistics();
print('Debug info: ${stats}');

// Check health report for specific issues
final health = await EnhancedServiceLocator.instance.getSystemHealth();
print('Health report: ${health.toMap()}');
```

This enhanced service locator provides a robust foundation for managing dependencies in the Revision app with comprehensive error handling, monitoring, and recovery capabilities.
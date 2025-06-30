# Error Monitoring System

A production-grade error monitoring and alerting system built with SOLID principles and testability in mind.

## Architecture

The system is composed of several focused components:

### Core Components

- **ProductionErrorMonitorV2**: Main orchestrator that coordinates error recording and analysis
- **ErrorClassifier**: Handles error categorization, severity assessment, and recovery analysis
- **ErrorAlertManager**: Manages alert triggering, cooldowns, and alert state
- **SystemHealthMonitor**: Monitors system health, detects patterns, and calculates health scores
- **ErrorEvent**: Immutable data structure representing error events with rich metadata

### Configuration

- **ErrorMonitoringConfig**: Interface for configurable thresholds and behaviors
- **DefaultErrorMonitoringConfig**: Production configuration
- **TestErrorMonitoringConfig**: Test-friendly configuration with shorter intervals

## Usage

### Basic Setup

```dart
import 'package:revision/core/services/error_monitoring/error_monitoring.dart';

// Initialize with default configuration
ProductionErrorMonitorV2.initialize();

// Or with custom configuration
ProductionErrorMonitorV2.initialize(
  config: const DefaultErrorMonitoringConfig(),
  logger: customLogger,
);
```

### Recording Errors

```dart
// Using the monitor directly
ProductionErrorMonitorV2.instance.recordError(
  error: exception,
  stackTrace: stackTrace,
  context: 'user_authentication',
  metadata: {'user_id': '123', 'action': 'login'},
);

// Using the extension method
exception.recordError(
  'payment_processing',
  stackTrace: stackTrace,
  metadata: {'amount': 100.0, 'currency': 'USD'},
);
```

### Monitoring System Health

```dart
// Get current health score (0-100)
final healthScore = ProductionErrorMonitorV2.instance.getHealthScore();

// Check if system is healthy
final isHealthy = ProductionErrorMonitorV2.instance.isSystemHealthy();

// Get comprehensive health report
final healthReport = ProductionErrorMonitorV2.instance.getHealthReport();
print(healthReport.toMap());
```

### Getting Error Statistics

```dart
final stats = ProductionErrorMonitorV2.instance.getErrorStatistics();
print('Errors in last 24h: ${stats.totalErrors24h}');
print('Most frequent errors: ${stats.mostFrequentErrors}');
```

## Features

### Error Classification

Errors are automatically categorized into:
- Network errors
- Authentication errors  
- AI service errors
- Validation errors
- Permission errors
- Circuit breaker errors
- Storage errors
- Firebase errors

### Severity Levels

- **Critical**: System-breaking errors requiring immediate attention
- **High**: Important errors that impact functionality
- **Medium**: Moderate errors that may impact user experience
- **Low**: Minor errors that don't significantly impact functionality

### Alert Types

- **Critical Error Pattern**: Same error occurring frequently
- **Cascading Failure**: Multiple error types occurring simultaneously
- **System Health Degraded**: Overall system health below threshold
- **Circuit Breaker Tripped**: Circuit breaker protection activated

### Health Monitoring

- Real-time health score calculation (0-100)
- System health status determination
- Cascading failure detection
- Error pattern analysis
- Comprehensive health reporting

## Configuration Options

```dart
class CustomConfig implements ErrorMonitoringConfig {
  @override
  int get criticalErrorThreshold => 3; // Errors before alert
  
  @override
  Duration get errorWindowDuration => const Duration(minutes: 2);
  
  @override
  bool get enableRealTimeAlerting => true;
  
  // ... other configuration options
}
```

## Testing

The system is designed for testability:

```dart
// Use test configuration for faster testing
ProductionErrorMonitorV2.initialize(
  config: const TestErrorMonitoringConfig(),
);

// Reset state between tests
ProductionErrorMonitorV2.instance.reset();
```

## Migration from Legacy System

The legacy `ProductionErrorMonitor` is still available for backward compatibility but is deprecated. To migrate:

1. Replace `ProductionErrorMonitor.instance` with `ProductionErrorMonitorV2.instance`
2. Add initialization call: `ProductionErrorMonitorV2.initialize()`
3. Update method calls as needed (most are compatible)

## Best Practices

1. **Initialize Early**: Call `initialize()` during app startup
2. **Provide Context**: Always include meaningful context when recording errors
3. **Use Metadata**: Add relevant metadata for better error analysis
4. **Monitor Health**: Regularly check system health in production
5. **Configure Appropriately**: Use different configs for dev/test/prod environments
6. **Handle Failures**: The system includes safeguards against recursive error logging

## Error Recovery

The system includes built-in error recovery:
- Prevents recursive error logging
- Gracefully handles monitor failures
- Maintains state consistency
- Provides fallback behavior

## Performance Considerations

- Error history is bounded (configurable limit)
- Efficient in-memory storage
- Minimal overhead for error recording
- Configurable alert cooldowns prevent spam

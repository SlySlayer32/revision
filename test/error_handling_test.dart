import 'package:flutter_test/flutter_test.dart';

import 'package:revision/core/services/ai_error_handler.dart';
import 'package:revision/core/services/error_monitoring_service.dart';
import 'package:revision/core/utils/enhanced_logger.dart';

void main() {
  group('AIErrorHandler Tests', () {
    late AIErrorHandler errorHandler;
    
    setUp(() {
      errorHandler = AIErrorHandler();
    });

    test('should retry on retryable errors', () async {
      int attemptCount = 0;
      
      final result = await errorHandler.executeWithRetry<String>(
        () async {
          attemptCount++;
          if (attemptCount < 3) {
            throw Exception('Unhandled format for Content: {role: model}');
          }
          return 'Success';
        },
        'test_operation',
      );
      
      expect(result, equals('Success'));
      expect(attemptCount, equals(3));
    });

    test('should not retry on non-retryable errors', () async {
      int attemptCount = 0;
      
      expect(
        () => errorHandler.executeWithRetry<String>(
          () async {
            attemptCount++;
            throw ArgumentError('Invalid argument');
          },
          'test_operation',
        ),
        throwsA(isA<ArgumentError>()),
      );
      
      expect(attemptCount, equals(1));
    });

    test('should implement exponential backoff', () async {
      final stopwatch = Stopwatch()..start();
      int attemptCount = 0;
      
      try {
        await errorHandler.executeWithRetry<String>(
          () async {
            attemptCount++;
            throw Exception('role: model');
          },
          'test_operation',
        );
      } catch (e) {
        // Expected to fail after retries
      }
      
      stopwatch.stop();
      
      // Should have taken some time due to exponential backoff
      expect(stopwatch.elapsedMilliseconds, greaterThan(1000));
      expect(attemptCount, equals(3)); // Default max retries
    });

    test('should open circuit breaker after threshold failures', () async {
      // Trigger multiple failures to open circuit breaker
      for (int i = 0; i < 6; i++) {
        try {
          await errorHandler.executeWithRetry<String>(
            () async => throw Exception('Network error'),
            'test_operation',
          );
        } catch (e) {
          // Expected failures
        }
      }
      
      final status = errorHandler.getCircuitStatus();
      expect(status['isOpen'], isTrue);
      expect(status['failureCount'], greaterThanOrEqualTo(5));
    });
  });

  group('AIException Tests', () {
    test('should create proper exception messages', () {
      final emptyException = const AIEmptyResponseException('Empty response');
      expect(emptyException.toString(), contains('Empty response'));
      
      final circuitException = const AICircuitBreakerException('Circuit open');
      expect(circuitException.toString(), contains('Circuit open'));
      
      final maxRetriesException = AIMaxRetriesExceededException('Max retries', Exception('cause'));
      expect(maxRetriesException.toString(), contains('Max retries'));
      expect(maxRetriesException.toString(), contains('cause'));
      
      final validationException = const AIResponseValidationException('Invalid response');
      expect(validationException.toString(), contains('Invalid response'));
    });
  });

  group('ErrorMonitoringService Tests', () {
    late ErrorMonitoringService monitoring;
    
    setUp(() {
      monitoring = ErrorMonitoringService();
    });

    test('should track error reports', () {
      monitoring.reportError('test_operation', 'Test error');
      
      final diagnostics = monitoring.getDiagnostics();
      expect(diagnostics['errorCounts']['test_operation'], equals(1));
    });

    test('should track success metrics', () {
      monitoring.reportSuccess('test_operation', const Duration(milliseconds: 500));
      
      final diagnostics = monitoring.getDiagnostics();
      expect(diagnostics['averageResponseTimes']['test_operation'], equals('500ms'));
    });

    test('should calculate success rates', () {
      // Report some successes and failures
      monitoring.reportSuccess('test_operation', const Duration(milliseconds: 500));
      monitoring.reportSuccess('test_operation', const Duration(milliseconds: 600));
      monitoring.reportError('test_operation', 'Test error');
      
      final diagnostics = monitoring.getDiagnostics();
      final successRate = diagnostics['successRates']['test_operation'];
      expect(successRate, greaterThan(50.0)); // 2/3 success rate
    });

    test('should identify error trends', () {
      // Report multiple recent errors
      for (int i = 0; i < 15; i++) {
        monitoring.reportError('failing_operation', 'Error $i');
      }
      
      final trends = monitoring.getErrorTrends();
      expect(trends['trend'], equals('increasing'));
      expect(trends['errors_last_hour'], greaterThan(10));
    });

    test('should suggest maintenance mode', () {
      // Report many errors to trigger maintenance mode suggestion
      for (int i = 0; i < 12; i++) {
        monitoring.reportError('critical_operation', 'Critical error $i');
      }
      
      expect(monitoring.shouldEnterMaintenanceMode(), isTrue);
    });

    test('should export diagnostics', () {
      monitoring.reportError('test_operation', 'Test error');
      monitoring.reportSuccess('test_operation', const Duration(milliseconds: 300));
      
      final export = monitoring.exportDiagnostics();
      expect(export, isA<String>());
      expect(export, contains('test_operation'));
      expect(export, contains('diagnostics'));
    });
  });

  group('EnhancedLogger Tests', () {
    late EnhancedLogger logger;
    
    setUp(() {
      logger = EnhancedLogger();
    });

    test('should log at different levels', () {
      logger.debug('Debug message');
      logger.info('Info message');
      logger.warning('Warning message');
      logger.error('Error message');
      logger.critical('Critical message');
      
      final logs = logger.getRecentLogs();
      expect(logs.length, greaterThanOrEqualTo(5));
      
      final levels = logs.map((log) => log.level).toSet();
      expect(levels.length, greaterThan(1)); // Multiple levels logged
    });

    test('should filter logs by level', () {
      logger.debug('Debug message');
      logger.info('Info message');
      logger.error('Error message');
      
      final errorLogs = logger.getRecentLogs(minLevel: LogLevel.error);
      expect(errorLogs.length, equals(1));
      expect(errorLogs.first.level, equals(LogLevel.error));
    });

    test('should log AI operations', () {
      logger.aiSuccess('test_operation', const Duration(milliseconds: 500));
      logger.aiError('test_operation', Exception('Test error'));
      logger.aiRetry('test_operation', 1, 3, Exception('Retry error'));
      
      final logs = logger.getRecentLogs();
      expect(logs.length, greaterThanOrEqualTo(3));
      
      final operations = logs.map((log) => log.operation).toSet();
      expect(operations.contains('test_operation'), isTrue);
    });

    test('should export logs', () {
      logger.info('Test log message');
      logger.error('Test error message');
      
      final export = logger.exportLogs();
      expect(export, isA<String>());
      expect(export, contains('Test log message'));
      expect(export, contains('Test error message'));
    });

    test('should configure logger settings', () {
      logger.configure(
        minLevel: LogLevel.warning,
        enableConsole: false,
        enableMonitoring: false,
      );
      
      // Debug and info should be filtered out
      logger.debug('Debug message');
      logger.info('Info message');
      logger.warning('Warning message');
      
      final logs = logger.getRecentLogs();
      final debugInfoLogs = logs.where((log) => 
          log.level == LogLevel.debug || log.level == LogLevel.info).toList();
      
      // Should have fewer debug/info logs due to filtering
      expect(debugInfoLogs.length, lessThanOrEqualTo(1)); // Only the config info log
    });
  });

  group('Integration Tests', () {
    test('should handle complete error flow', () async {
      final errorHandler = AIErrorHandler();
      final monitoring = ErrorMonitoringService();
      
      // Simulate AI operation with retries
      String? result;
      try {
        result = await errorHandler.executeWithRetry<String>(
          () async {
            // Simulate the known Firebase AI parsing error
            throw Exception('Unhandled format for Content: {role: model}');
          },
          'integration_test',
        );
      } catch (e) {
        // Expected to fail after retries
        monitoring.reportError('integration_test', e);
      }
      
      expect(result, isNull);
      
      final diagnostics = monitoring.getDiagnostics();
      expect(diagnostics['errorCounts']['integration_test'], greaterThan(0));
      
      final circuitStatus = errorHandler.getCircuitStatus();
      expect(circuitStatus['failureCount'], greaterThan(0));
    });

    test('should demonstrate fallback mechanisms', () async {
      final errorHandler = AIErrorHandler();
      
      // Test with fallback on failure
      final result = await errorHandler.executeWithRetry<String>(
        () async => throw Exception('role: model parsing error'),
        'fallback_test',
      ).catchError((e) {
        // Fallback response
        return 'Fallback response: Unable to process request due to technical issues.';
      });
      
      expect(result, contains('Fallback response'));
      expect(result, contains('technical issues'));
    });
  });
}

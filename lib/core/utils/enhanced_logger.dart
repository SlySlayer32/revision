import 'dart:developer' as dev;
import 'dart:convert';

import 'package:revision/core/services/error_monitoring_service.dart';

/// Enhanced logging system with structured logging, filtering, and persistence
class EnhancedLogger {
  static final EnhancedLogger _instance = EnhancedLogger._internal();
  factory EnhancedLogger() => _instance;
  EnhancedLogger._internal();

  static const String _logPrefix = '🔧 REVISION';
  
  // Log levels
  static const int _levelDebug = 0;
  static const int _levelInfo = 1;
  static const int _levelWarning = 2;
  static const int _levelError = 3;
  static const int _levelCritical = 4;
  
  int _currentLogLevel = _levelInfo;
  bool _enableConsoleOutput = true;
  bool _enableFileOutput = false;
  bool _enableMonitoringIntegration = true;
  
  final List<LogEntry> _logBuffer = [];
  static const int _maxBufferSize = 1000;

  /// Configure logger settings
  void configure({
    LogLevel? minLevel,
    bool? enableConsole,
    bool? enableFile,
    bool? enableMonitoring,
  }) {
    if (minLevel != null) {
      _currentLogLevel = _logLevelToInt(minLevel);
    }
    if (enableConsole != null) {
      _enableConsoleOutput = enableConsole;
    }
    if (enableFile != null) {
      _enableFileOutput = enableFile;
    }
    if (enableMonitoring != null) {
      _enableMonitoringIntegration = enableMonitoring;
    }
    
    info('Logger configured: level=${minLevel?.name}, console=$enableConsole, file=$enableFile');
  }

  /// Debug level logging
  void debug(String message, {
    String? operation,
    Map<String, dynamic>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.debug, message, operation, context, error, stackTrace);
  }

  /// Info level logging
  void info(String message, {
    String? operation,
    Map<String, dynamic>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.info, message, operation, context, error, stackTrace);
  }

  /// Warning level logging
  void warning(String message, {
    String? operation,
    Map<String, dynamic>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.warning, message, operation, context, error, stackTrace);
  }

  /// Error level logging
  void error(String message, {
    String? operation,
    Map<String, dynamic>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.error, message, operation, context, error, stackTrace);
    
    // Auto-report errors to monitoring
    if (_enableMonitoringIntegration && operation != null) {
      ErrorMonitoringService().reportError(
        operation,
        error ?? message,
        stackTrace: stackTrace,
        context: context,
      );
    }
  }

  /// Critical level logging
  void critical(String message, {
    String? operation,
    Map<String, dynamic>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.critical, message, operation, context, error, stackTrace);
    
    // Always report critical errors to monitoring
    if (_enableMonitoringIntegration) {
      ErrorMonitoringService().reportError(
        operation ?? 'CRITICAL',
        error ?? message,
        stackTrace: stackTrace,
        context: context,
      );
    }
  }

  /// AI-specific logging helpers
  void aiSuccess(String operation, Duration responseTime, {
    Map<String, dynamic>? context,
  }) {
    info(
      '✅ AI Success: $operation (${responseTime.inMilliseconds}ms)',
      operation: operation,
      context: {
        'response_time_ms': responseTime.inMilliseconds,
        'success': true,
        ...?context,
      },
    );
    
    if (_enableMonitoringIntegration) {
      ErrorMonitoringService().reportSuccess(operation, responseTime, context: context);
    }
  }

  void aiError(String operation, Object error, {
    Duration? responseTime,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    this.error(
      '❌ AI Error: $operation - $error',
      operation: operation,
      error: error,
      stackTrace: stackTrace,
      context: {
        'response_time_ms': responseTime?.inMilliseconds,
        'success': false,
        ...?context,
      },
    );
  }

  void aiRetry(String operation, int attempt, int maxAttempts, Object error) {
    warning(
      '🔄 AI Retry: $operation (attempt $attempt/$maxAttempts) - $error',
      operation: operation,
      context: {
        'attempt': attempt,
        'max_attempts': maxAttempts,
        'retry': true,
      },
    );
  }

  void circuitBreakerOpen(String operation, {
    int? failureCount,
    Duration? timeout,
  }) {
    critical(
      '🔴 Circuit Breaker OPEN: $operation',
      operation: operation,
      context: {
        'circuit_breaker': 'open',
        'failure_count': failureCount,
        'timeout_ms': timeout?.inMilliseconds,
      },
    );
  }

  void circuitBreakerReset(String operation) {
    info(
      '🟢 Circuit Breaker RESET: $operation',
      operation: operation,
      context: {
        'circuit_breaker': 'reset',
      },
    );
  }

  /// Performance logging
  void performanceMetric(String metric, num value, {
    String? unit,
    Map<String, dynamic>? context,
  }) {
    debug(
      '📊 Performance: $metric = $value${unit ?? ''}',
      operation: 'PERFORMANCE',
      context: {
        'metric': metric,
        'value': value,
        'unit': unit,
        ...?context,
      },
    );
  }

  /// Get recent logs
  List<LogEntry> getRecentLogs({int limit = 50, LogLevel? minLevel}) {
    var filtered = _logBuffer.toList();
    
    if (minLevel != null) {
      final minLevelInt = _logLevelToInt(minLevel);
      filtered = filtered.where((log) => _logLevelToInt(log.level) >= minLevelInt).toList();
    }
    
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filtered.take(limit).toList();
  }

  /// Export logs as JSON
  String exportLogs({LogLevel? minLevel, Duration? timeRange}) {
    var logs = _logBuffer.toList();
    
    if (minLevel != null) {
      final minLevelInt = _logLevelToInt(minLevel);
      logs = logs.where((log) => _logLevelToInt(log.level) >= minLevelInt).toList();
    }
    
    if (timeRange != null) {
      final cutoff = DateTime.now().subtract(timeRange);
      logs = logs.where((log) => log.timestamp.isAfter(cutoff)).toList();
    }
    
    final export = {
      'timestamp': DateTime.now().toIso8601String(),
      'log_count': logs.length,
      'logs': logs.map((log) => log.toMap()).toList(),
    };
    
    return const JsonEncoder.withIndent('  ').convert(export);
  }

  /// Clear old logs
  void clearOldLogs({Duration? olderThan}) {
    final cutoff = DateTime.now().subtract(olderThan ?? const Duration(hours: 24));
    _logBuffer.removeWhere((log) => log.timestamp.isBefore(cutoff));
    info('🧹 Cleared logs older than ${olderThan?.inHours ?? 24} hours');
  }

  // Private methods

  void _log(
    LogLevel level,
    String message,
    String? operation,
    Map<String, dynamic>? context,
    Object? error,
    StackTrace? stackTrace,
  ) {
    final levelInt = _logLevelToInt(level);
    if (levelInt < _currentLogLevel) return;

    final entry = LogEntry(
      level: level,
      message: message,
      operation: operation,
      context: context ?? {},
      error: error?.toString(),
      stackTrace: stackTrace?.toString(),
      timestamp: DateTime.now(),
    );

    // Add to buffer
    _logBuffer.add(entry);
    if (_logBuffer.length > _maxBufferSize) {
      _logBuffer.removeAt(0);
    }

    // Console output
    if (_enableConsoleOutput) {
      _outputToConsole(entry);
    }

    // File output (if enabled)
    if (_enableFileOutput) {
      _outputToFile(entry);
    }
  }

  void _outputToConsole(LogEntry entry) {
    final emoji = _getLevelEmoji(entry.level);
    final timestamp = entry.timestamp.toString().substring(11, 23); // HH:mm:ss.mmm
    
    var output = '$_logPrefix $emoji [$timestamp] ${entry.message}';
    
    if (entry.operation != null) {
      output = '$_logPrefix $emoji [$timestamp] [${entry.operation}] ${entry.message}';
    }
    
    if (entry.context.isNotEmpty) {
      output += ' | Context: ${entry.context}';
    }
    
    // Use appropriate dart:developer log level
    switch (entry.level) {
      case LogLevel.debug:
      case LogLevel.info:
        dev.log(output);
        break;
      case LogLevel.warning:
        dev.log(output, level: 900);
        break;
      case LogLevel.error:
      case LogLevel.critical:
        dev.log(output, level: 1000, error: entry.error, stackTrace: entry.stackTrace != null ? StackTrace.fromString(entry.stackTrace!) : null);
        break;
    }
  }

  void _outputToFile(LogEntry entry) {
    // In a real implementation, you would write to a file
    // For now, we'll just log that file output would happen
    dev.log('📝 [FILE] ${entry.toMap()}');
  }

  String _getLevelEmoji(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🐛';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.critical:
        return '🔴';
    }
  }

  int _logLevelToInt(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return _levelDebug;
      case LogLevel.info:
        return _levelInfo;
      case LogLevel.warning:
        return _levelWarning;
      case LogLevel.error:
        return _levelError;
      case LogLevel.critical:
        return _levelCritical;
    }
  }
}

/// Log levels
enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical;
  
  String get name => toString().split('.').last;
}

/// Individual log entry
class LogEntry {
  const LogEntry({
    required this.level,
    required this.message,
    required this.timestamp,
    this.operation,
    this.context = const {},
    this.error,
    this.stackTrace,
  });

  final LogLevel level;
  final String message;
  final String? operation;
  final Map<String, dynamic> context;
  final String? error;
  final String? stackTrace;
  final DateTime timestamp;

  Map<String, dynamic> toMap() {
    return {
      'level': level.name,
      'message': message,
      'operation': operation,
      'context': context,
      'error': error,
      'stackTrace': stackTrace,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Global logger instance
final logger = EnhancedLogger();

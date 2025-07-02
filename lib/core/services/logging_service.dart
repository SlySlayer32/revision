import 'dart:developer' as dev;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Production-grade logging service that integrates with Firebase Crashlytics
/// and provides structured logging capabilities
class LoggingService {
  const LoggingService._();

  static const LoggingService _instance = LoggingService._();
  static LoggingService get instance => _instance;

  /// Log levels for structured logging
  static const String _debug = 'DEBUG';
  static const String _info = 'INFO';
  static const String _warning = 'WARNING';
  static const String _error = 'ERROR';
  static const String _fatal = 'FATAL';

  /// Logs debug information (development only)
  void debug(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    if (kDebugMode) {
      _log(_debug, message, error: error, stackTrace: stackTrace, data: data);
    }
  }

  /// Logs informational messages
  void info(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(_info, message, error: error, stackTrace: stackTrace, data: data);
  }

  /// Logs warning messages
  void warning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(_warning, message, error: error, stackTrace: stackTrace, data: data);

    // Send warning to Crashlytics as non-fatal
    if (!kDebugMode && error != null) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        fatal: false,
        information: _buildCrashlyticsInfo(message, data).cast<Object>(),
      );
    }
  }

  /// Logs error messages
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(_error, message, error: error, stackTrace: stackTrace, data: data);

    // Send error to Crashlytics
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(
        error ?? Exception(message),
        stackTrace ?? StackTrace.current,
        fatal: false,
        information: _buildCrashlyticsInfo(message, data).cast<Object>(),
      );
    }
  }

  /// Logs fatal errors that may cause app crashes
  void fatal(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(_fatal, message, error: error, stackTrace: stackTrace, data: data);

    // Send fatal error to Crashlytics
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(
        error ?? Exception(message),
        stackTrace ?? StackTrace.current,
        fatal: true,
        information: _buildCrashlyticsInfo(message, data).cast<Object>(),
      );
    }
  }

  /// Logs API requests and responses
  void apiCall(
    String method,
    String endpoint, {
    int? statusCode,
    Duration? duration,
    String? requestId,
    Map<String, dynamic>? data,
  }) {
    final message = 'API $method $endpoint'
        '${statusCode != null ? ' - $statusCode' : ''}'
        '${duration != null ? ' (${duration.inMilliseconds}ms)' : ''}';

    final logData = {
      'method': method,
      'endpoint': endpoint,
      if (statusCode != null) 'statusCode': statusCode,
      if (duration != null) 'durationMs': duration.inMilliseconds,
      if (requestId != null) 'requestId': requestId,
      ...?data,
    };

    if (statusCode != null && statusCode >= 400) {
      error(message, data: logData);
    } else {
      info(message, data: logData);
    }
  }

  /// Logs user actions for analytics
  void userAction(
    String action, {
    Map<String, dynamic>? data,
  }) {
    info('User Action: $action', data: data);
  }

  /// Logs performance metrics
  void performance(
    String operation,
    Duration duration, {
    Map<String, dynamic>? data,
  }) {
    final message = 'Performance: $operation took ${duration.inMilliseconds}ms';
    final logData = {
      'operation': operation,
      'durationMs': duration.inMilliseconds,
      ...?data,
    };

    if (duration.inSeconds > 5) {
      warning(message, data: logData);
    } else {
      info(message, data: logData);
    }
  }

  /// Sets user identifier for crash reporting
  void setUserId(String userId) {
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.setUserIdentifier(userId);
    }
    info('User ID set: $userId');
  }

  /// Sets custom key-value pairs for crash reporting
  void setCustomKey(String key, String value) {
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.setCustomKey(key, value);
    }
  }

  /// Internal logging method
  void _log(
    String level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] [$level] $message';

    // Add data if provided
    final fullMessage =
        data != null ? '$logMessage - Data: ${data.toString()}' : logMessage;

    // Use dart:developer log for better debugging
    dev.log(
      fullMessage,
      name: 'RevisionApp',
      error: error,
      stackTrace: stackTrace,
      level: _getLevelValue(level),
    );

    // Also print to console for development
    if (kDebugMode) {
      print(fullMessage);
      if (error != null) {
        print('Error: $error');
      }
      if (stackTrace != null) {
        print('StackTrace: $stackTrace');
      }
    }
  }

  /// Converts log level to numeric value for dart:developer
  int _getLevelValue(String level) {
    switch (level) {
      case _debug:
        return 500;
      case _info:
        return 800;
      case _warning:
        return 900;
      case _error:
        return 1000;
      case _fatal:
        return 1200;
      default:
        return 800;
    }
  }

  /// Builds information array for Crashlytics
  List<dynamic> _buildCrashlyticsInfo(
      String message, Map<String, dynamic>? data) {
    final info = <dynamic>[message];
    if (data != null) {
      info.addAll(data.entries.map((e) => '${e.key}: ${e.value}'));
    }
    return info;
  }
}

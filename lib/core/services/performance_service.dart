import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:revision/core/services/logging_service.dart';

/// Production-grade performance monitoring service
class PerformanceService {
  PerformanceService._();
  
  static final PerformanceService _instance = PerformanceService._();
  static PerformanceService get instance => _instance;

  final Map<String, Stopwatch> _activeTimers = {};
  final Map<String, List<Duration>> _performanceHistory = {};

  /// Starts timing an operation
  void startTimer(String operationName) {
    final stopwatch = Stopwatch()..start();
    _activeTimers[operationName] = stopwatch;
    
    LoggingService.instance.debug('Started timing: $operationName');
  }

  /// Stops timing an operation and logs the result
  Duration? stopTimer(String operationName) {
    final stopwatch = _activeTimers.remove(operationName);
    if (stopwatch == null) {
      LoggingService.instance.warning('Timer not found: $operationName');
      return null;
    }

    stopwatch.stop();
    final duration = stopwatch.elapsed;

    // Store in history for analysis
    _performanceHistory.putIfAbsent(operationName, () => []).add(duration);
    
    // Keep only last 50 measurements per operation
    final history = _performanceHistory[operationName]!;
    if (history.length > 50) {
      history.removeAt(0);
    }

    LoggingService.instance.performance(operationName, duration);
    
    return duration;
  }

  /// Times an async operation
  Future<T> timeAsync<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    startTimer(operationName);
    try {
      final result = await operation();
      stopTimer(operationName);
      return result;
    } catch (e) {
      stopTimer(operationName);
      rethrow;
    }
  }

  /// Times a synchronous operation
  T timeSync<T>(
    String operationName,
    T Function() operation,
  ) {
    startTimer(operationName);
    try {
      final result = operation();
      stopTimer(operationName);
      return result;
    } catch (e) {
      stopTimer(operationName);
      rethrow;
    }
  }

  /// Gets performance statistics for an operation
  PerformanceStats? getStats(String operationName) {
    final history = _performanceHistory[operationName];
    if (history == null || history.isEmpty) {
      return null;
    }

    final durations = history.map((d) => d.inMilliseconds).toList()..sort();
    final count = durations.length;
    final sum = durations.reduce((a, b) => a + b);
    final avg = sum / count;
    
    final median = count % 2 == 0
        ? (durations[count ~/ 2 - 1] + durations[count ~/ 2]) / 2
        : durations[count ~/ 2].toDouble();

    final p95Index = ((count - 1) * 0.95).round();
    final p95 = durations[p95Index].toDouble();

    return PerformanceStats(
      operationName: operationName,
      count: count,
      averageMs: avg,
      medianMs: median,
      p95Ms: p95,
      minMs: durations.first.toDouble(),
      maxMs: durations.last.toDouble(),
    );
  }

  /// Gets all performance statistics
  Map<String, PerformanceStats> getAllStats() {
    final stats = <String, PerformanceStats>{};
    for (final operationName in _performanceHistory.keys) {
      final stat = getStats(operationName);
      if (stat != null) {
        stats[operationName] = stat;
      }
    }
    return stats;
  }

  /// Logs performance summary
  void logPerformanceSummary() {
    final stats = getAllStats();
    if (stats.isEmpty) {
      LoggingService.instance.info('No performance data available');
      return;
    }

    LoggingService.instance.info('Performance Summary:');
    for (final stat in stats.values) {
      LoggingService.instance.info(
        '${stat.operationName}: '
        'avg=${stat.averageMs.toStringAsFixed(1)}ms, '
        'p95=${stat.p95Ms.toStringAsFixed(1)}ms, '
        'count=${stat.count}',
      );
    }
  }

  /// Monitors app lifecycle performance
  void monitorAppLifecycle() {
    if (kDebugMode) {
      SystemChannels.lifecycle.setMessageHandler((message) async {
        if (message != null) {
          LoggingService.instance.info('App lifecycle: $message');
          
          switch (message) {
            case 'AppLifecycleState.resumed':
              startTimer('app_resume_time');
              break;
            case 'AppLifecycleState.paused':
              stopTimer('app_resume_time');
              break;
          }
        }
        return null;
      });
    }
  }

  /// Monitors memory usage (debug mode only)
  void logMemoryUsage() {
    if (kDebugMode) {
      // This is a simplified memory monitoring
      // In production, you might want to use more sophisticated tools
      final runtime = Runtime.current;
      LoggingService.instance.debug(
        'Memory usage: ${runtime.totalMemory ~/ 1024 / 1024}MB total, '
        '${runtime.freeMemory ~/ 1024 / 1024}MB free',
      );
    }
  }

  /// Clears performance history
  void clearHistory() {
    _performanceHistory.clear();
    LoggingService.instance.info('Performance history cleared');
  }
}

/// Performance statistics for an operation
class PerformanceStats {
  const PerformanceStats({
    required this.operationName,
    required this.count,
    required this.averageMs,
    required this.medianMs,
    required this.p95Ms,
    required this.minMs,
    required this.maxMs,
  });

  final String operationName;
  final int count;
  final double averageMs;
  final double medianMs;
  final double p95Ms;
  final double minMs;
  final double maxMs;

  @override
  String toString() {
    return 'PerformanceStats($operationName: '
        'avg=${averageMs.toStringAsFixed(1)}ms, '
        'median=${medianMs.toStringAsFixed(1)}ms, '
        'p95=${p95Ms.toStringAsFixed(1)}ms, '
        'range=${minMs.toStringAsFixed(1)}-${maxMs.toStringAsFixed(1)}ms, '
        'count=$count)';
  }
}

/// Simple runtime class for memory monitoring
class Runtime {
  static Runtime get current => const Runtime._();
  
  const Runtime._();
  
  // Placeholder values - in real implementation you'd use platform-specific APIs
  int get totalMemory => 512 * 1024 * 1024; // 512MB placeholder
  int get freeMemory => 256 * 1024 * 1024;  // 256MB placeholder
}

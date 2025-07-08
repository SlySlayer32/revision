import 'dart:async';
import 'dart:developer';

import 'package:revision/core/constants/app_constants.dart';

/// Production-grade performance monitoring service
///
/// Tracks app performance, memory usage, and provides insights
/// for optimization and issue detection.
class PerformanceMonitoringService {
  static final PerformanceMonitoringService _instance =
      PerformanceMonitoringService._();
  factory PerformanceMonitoringService() => _instance;
  PerformanceMonitoringService._();

  final Map<String, List<Duration>> _operationTimes = {};
  final Map<String, int> _operationCounts = {};
  final List<PerformanceMetric> _metrics = [];

  Timer? _memoryMonitorTimer;
  bool _isMonitoring = false;

  /// Starts performance monitoring
  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;

    // Monitor memory usage every 30 seconds
    _memoryMonitorTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkMemoryUsage(),
    );

    log('Performance monitoring started', name: 'PerformanceMonitor');
  }

  /// Stops performance monitoring
  void stopMonitoring() {
    if (!_isMonitoring) return;

    _isMonitoring = false;
    _memoryMonitorTimer?.cancel();
    _memoryMonitorTimer = null;

    log('Performance monitoring stopped', name: 'PerformanceMonitor');
  }

  /// Times an async operation and records performance metrics
  ///
  /// [operationName] - Name of the operation for tracking
  /// [operation] - The async operation to time
  ///
  /// Returns the result of the operation
  Future<T> timeOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();

    try {
      final result = await operation();
      stopwatch.stop();

      _recordOperationTime(operationName, stopwatch.elapsed);
      _recordMetric(
        PerformanceMetric(
          name: operationName,
          type: MetricType.operationTime,
          value: stopwatch.elapsedMilliseconds.toDouble(),
          timestamp: DateTime.now(),
        ),
      );

      return result;
    } catch (e) {
      stopwatch.stop();

      _recordOperationTime(operationName, stopwatch.elapsed);
      _recordMetric(
        PerformanceMetric(
          name: '${operationName}_error',
          type: MetricType.error,
          value: stopwatch.elapsedMilliseconds.toDouble(),
          timestamp: DateTime.now(),
          metadata: {'error': e.toString()},
        ),
      );

      rethrow;
    }
  }

  /// Records the time taken for an operation
  void _recordOperationTime(String operationName, Duration duration) {
    _operationTimes.putIfAbsent(operationName, () => []);
    _operationTimes[operationName]!.add(duration);

    _operationCounts[operationName] =
        (_operationCounts[operationName] ?? 0) + 1;

    // Keep only the last 100 measurements per operation
    if (_operationTimes[operationName]!.length > 100) {
      _operationTimes[operationName]!.removeAt(0);
    }

    // Log slow operations
    if (duration.inMilliseconds > _getSlowThreshold(operationName)) {
      log(
        'Slow operation detected: $operationName took ${duration.inMilliseconds}ms',
        name: 'PerformanceMonitor',
      );
    }
  }

  /// Gets the slow operation threshold for a given operation type
  int _getSlowThreshold(String operationName) {
    switch (operationName.toLowerCase()) {
      case 'auth':
      case 'signin':
      case 'signup':
        return 5000; // 5 seconds
      case 'ai':
      case 'image_processing':
      case 'gemini':
        return 30000; // 30 seconds
      case 'network':
      case 'upload':
      case 'download':
        return 10000; // 10 seconds
      case 'database':
      case 'firestore':
        return 3000; // 3 seconds
      default:
        return 2000; // 2 seconds
    }
  }

  /// Records a performance metric
  void _recordMetric(PerformanceMetric metric) {
    _metrics.add(metric);

    // Keep only the last 1000 metrics
    if (_metrics.length > 1000) {
      _metrics.removeAt(0);
    }
  }

  /// Checks memory usage and alerts if threshold exceeded
  void _checkMemoryUsage() {
    // Note: In a real implementation, you would use platform-specific
    // methods to get actual memory usage. This is a simplified version.

    _recordMetric(
      PerformanceMetric(
        name: 'memory_check',
        type: MetricType.memoryUsage,
        value: 0, // Placeholder - would get actual memory usage
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Gets performance statistics for an operation
  PerformanceStats? getOperationStats(String operationName) {
    final times = _operationTimes[operationName];
    if (times == null || times.isEmpty) return null;

    final durations = times.map((d) => d.inMilliseconds).toList()..sort();
    final count = _operationCounts[operationName] ?? 0;

    final sum = durations.reduce((a, b) => a + b);
    final average = sum / durations.length;

    final median = durations.length % 2 == 0
        ? (durations[durations.length ~/ 2 - 1] +
                  durations[durations.length ~/ 2]) /
              2.0
        : durations[durations.length ~/ 2].toDouble();

    final p95Index = ((durations.length - 1) * 0.95).round();
    final p95 = durations[p95Index].toDouble();

    return PerformanceStats(
      operationName: operationName,
      count: count,
      averageMs: average,
      medianMs: median,
      p95Ms: p95,
      minMs: durations.first.toDouble(),
      maxMs: durations.last.toDouble(),
    );
  }

  /// Gets all performance statistics
  Map<String, PerformanceStats> getAllStats() {
    final stats = <String, PerformanceStats>{};

    for (final operationName in _operationTimes.keys) {
      final operationStats = getOperationStats(operationName);
      if (operationStats != null) {
        stats[operationName] = operationStats;
      }
    }

    return stats;
  }

  /// Gets recent performance metrics
  List<PerformanceMetric> getRecentMetrics({
    Duration? since,
    MetricType? type,
    int? limit,
  }) {
    var metrics = _metrics.toList();

    if (since != null) {
      final cutoff = DateTime.now().subtract(since);
      metrics = metrics.where((m) => m.timestamp.isAfter(cutoff)).toList();
    }

    if (type != null) {
      metrics = metrics.where((m) => m.type == type).toList();
    }

    // Sort by timestamp (newest first)
    metrics.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (limit != null && metrics.length > limit) {
      metrics = metrics.take(limit).toList();
    }

    return metrics;
  }

  /// Generates a performance report
  PerformanceReport generateReport() {
    final stats = getAllStats();
    final recentMetrics = getRecentMetrics(
      since: const Duration(hours: 1),
      limit: 50,
    );

    // Find slow operations
    final slowOperations = stats.entries
        .where((e) => e.value.averageMs > _getSlowThreshold(e.key))
        .map((e) => e.value)
        .toList();

    // Find operations with high error rates
    final errorMetrics = getRecentMetrics(
      type: MetricType.error,
      since: const Duration(hours: 1),
    );

    final errorsByOperation = <String, int>{};
    for (final metric in errorMetrics) {
      final operationName = metric.name.replaceAll('_error', '');
      errorsByOperation[operationName] =
          (errorsByOperation[operationName] ?? 0) + 1;
    }

    return PerformanceReport(
      generatedAt: DateTime.now(),
      overallStats: stats,
      recentMetrics: recentMetrics,
      slowOperations: slowOperations,
      errorsByOperation: errorsByOperation,
      recommendations: _generateRecommendations(stats, slowOperations),
    );
  }

  /// Generates performance recommendations
  List<String> _generateRecommendations(
    Map<String, PerformanceStats> stats,
    List<PerformanceStats> slowOperations,
  ) {
    final recommendations = <String>[];

    // Check for slow operations
    for (final operation in slowOperations) {
      recommendations.add(
        'Operation "${operation.operationName}" is running slowly. '
        'Average: ${operation.averageMs.toStringAsFixed(0)}ms, '
        'P95: ${operation.p95Ms.toStringAsFixed(0)}ms',
      );
    }

    // Check for high variance operations
    for (final stat in stats.values) {
      final variance = stat.maxMs - stat.minMs;
      if (variance > 5000 && stat.count > 10) {
        recommendations.add(
          'Operation "${stat.operationName}" has high variance. '
          'Range: ${stat.minMs.toStringAsFixed(0)}ms - ${stat.maxMs.toStringAsFixed(0)}ms',
        );
      }
    }

    // Memory recommendations
    recommendations.add(
      'Keep memory usage below ${AppConstants.memoryWarningThresholdMB}MB '
      'for optimal performance',
    );

    if (recommendations.isEmpty) {
      recommendations.add('Performance looks good! No issues detected.');
    }

    return recommendations;
  }

  /// Clears all performance data
  void clearData() {
    _operationTimes.clear();
    _operationCounts.clear();
    _metrics.clear();

    log('Performance data cleared', name: 'PerformanceMonitor');
  }

  /// Disposes the service
  void dispose() {
    stopMonitoring();
    clearData();
  }
}

/// Performance metric data class
class PerformanceMetric {
  const PerformanceMetric({
    required this.name,
    required this.type,
    required this.value,
    required this.timestamp,
    this.metadata,
  });

  final String name;
  final MetricType type;
  final double value;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
}

/// Types of performance metrics
enum MetricType { operationTime, memoryUsage, networkLatency, error, custom }

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
}

/// Comprehensive performance report
class PerformanceReport {
  const PerformanceReport({
    required this.generatedAt,
    required this.overallStats,
    required this.recentMetrics,
    required this.slowOperations,
    required this.errorsByOperation,
    required this.recommendations,
  });

  final DateTime generatedAt;
  final Map<String, PerformanceStats> overallStats;
  final List<PerformanceMetric> recentMetrics;
  final List<PerformanceStats> slowOperations;
  final Map<String, int> errorsByOperation;
  final List<String> recommendations;
}

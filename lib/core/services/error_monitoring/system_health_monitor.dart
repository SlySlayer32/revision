import 'error_enums.dart';
import 'error_event.dart';
import 'error_monitoring_constants.dart';

/// Monitors and analyzes system health based on error patterns
class SystemHealthMonitor {
  const SystemHealthMonitor();

  /// Calculate system health score (0-100)
  int calculateHealthScore(List<ErrorEvent> recentErrors) {
    if (recentErrors.isEmpty) {
      return ErrorMonitoringConstants.maxHealthScore;
    }

    final maxErrors = ErrorMonitoringConstants.maxHealthScoreErrors;
    final errorCount = recentErrors.length.clamp(0, maxErrors);
    final baseScore = ((maxErrors - errorCount) / maxErrors * 100).round();
    
    // Apply severity penalty
    final severityPenalty = _calculateSeverityPenalty(recentErrors);
    final finalScore = (baseScore - severityPenalty).clamp(
      ErrorMonitoringConstants.minHealthScore,
      ErrorMonitoringConstants.maxHealthScore,
    );
    
    return finalScore;
  }

  /// Check if system is in a healthy state
  bool isSystemHealthy(List<ErrorEvent> recentErrors, bool hasActiveAlerts) {
    if (hasActiveAlerts) return false;
    
    final criticalErrors = recentErrors
        .where((e) => e.severity == ErrorSeverity.critical)
        .length;
    
    return criticalErrors == 0 && 
           recentErrors.length < ErrorMonitoringConstants.systemHealthErrorThreshold;
  }

  /// Detect cascading failure patterns
  CascadingFailureAnalysis analyzeCascadingFailures(List<ErrorEvent> recentErrors) {
    final uniqueErrorTypes = recentErrors.map((e) => e.errorKey).toSet();
    
    final isCascadingFailure = uniqueErrorTypes.length >= 
            ErrorMonitoringConstants.cascadingFailureMinErrorTypes &&
        recentErrors.length >= ErrorMonitoringConstants.cascadingFailureMinErrors;
    
    return CascadingFailureAnalysis(
      isCascadingFailure: isCascadingFailure,
      uniqueErrorTypes: uniqueErrorTypes.length,
      totalErrors: recentErrors.length,
      timeWindow: ErrorMonitoringConstants.cascadingFailureWindow,
      errorDistribution: _calculateErrorDistribution(recentErrors),
    );
  }

  /// Analyze error patterns and trends
  ErrorPatternAnalysis analyzeErrorPatterns(List<ErrorEvent> errors) {
    if (errors.isEmpty) {
      return ErrorPatternAnalysis.empty();
    }

    final errorsByCategory = <ErrorCategory, int>{};
    final errorsBySeverity = <ErrorSeverity, int>{};
    final errorsByType = <String, int>{};
    
    for (final error in errors) {
      errorsByCategory[error.category] = (errorsByCategory[error.category] ?? 0) + 1;
      errorsBySeverity[error.severity] = (errorsBySeverity[error.severity] ?? 0) + 1;
      errorsByType[error.errorKey] = (errorsByType[error.errorKey] ?? 0) + 1;
    }

    final dominantCategory = errorsByCategory.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    
    final dominantSeverity = errorsBySeverity.entries
        .reduce((a, b) => a.value > b.value ? a : b);

    return ErrorPatternAnalysis(
      totalErrors: errors.length,
      errorsByCategory: errorsByCategory,
      errorsBySeverity: errorsBySeverity,
      errorsByType: errorsByType,
      dominantCategory: dominantCategory.key,
      dominantSeverity: dominantSeverity.key,
      timeSpan: _calculateTimeSpan(errors),
    );
  }

  /// Generate health report
  SystemHealthReport generateHealthReport(
    List<ErrorEvent> recentErrors,
    bool hasActiveAlerts,
  ) {
    final healthScore = calculateHealthScore(recentErrors);
    final isHealthy = isSystemHealthy(recentErrors, hasActiveAlerts);
    final cascadingAnalysis = analyzeCascadingFailures(recentErrors);
    final patternAnalysis = analyzeErrorPatterns(recentErrors);

    return SystemHealthReport(
      healthScore: healthScore,
      isHealthy: isHealthy,
      hasActiveAlerts: hasActiveAlerts,
      cascadingFailureAnalysis: cascadingAnalysis,
      errorPatternAnalysis: patternAnalysis,
      timestamp: DateTime.now(),
    );
  }

  int _calculateSeverityPenalty(List<ErrorEvent> errors) {
    int penalty = 0;
    for (final error in errors) {
      switch (error.severity) {
        case ErrorSeverity.critical:
          penalty += 20;
          break;
        case ErrorSeverity.high:
          penalty += 10;
          break;
        case ErrorSeverity.medium:
          penalty += 5;
          break;
        case ErrorSeverity.low:
          penalty += 1;
          break;
        case ErrorSeverity.unknown:
          penalty += 3;
          break;
      }
    }
    return penalty;
  }

  Map<ErrorCategory, double> _calculateErrorDistribution(List<ErrorEvent> errors) {
    if (errors.isEmpty) return {};
    
    final distribution = <ErrorCategory, int>{};
    for (final error in errors) {
      distribution[error.category] = (distribution[error.category] ?? 0) + 1;
    }
    
    return distribution.map(
      (category, count) => MapEntry(category, count / errors.length),
    );
  }

  Duration _calculateTimeSpan(List<ErrorEvent> errors) {
    if (errors.isEmpty) return Duration.zero;
    
    final timestamps = errors.map((e) => e.timestamp).toList()..sort();
    return timestamps.last.difference(timestamps.first);
  }
}

/// Result of cascading failure analysis
class CascadingFailureAnalysis {
  const CascadingFailureAnalysis({
    required this.isCascadingFailure,
    required this.uniqueErrorTypes,
    required this.totalErrors,
    required this.timeWindow,
    required this.errorDistribution,
  });

  final bool isCascadingFailure;
  final int uniqueErrorTypes;
  final int totalErrors;
  final Duration timeWindow;
  final Map<ErrorCategory, double> errorDistribution;
}

/// Result of error pattern analysis
class ErrorPatternAnalysis {
  const ErrorPatternAnalysis({
    required this.totalErrors,
    required this.errorsByCategory,
    required this.errorsBySeverity,
    required this.errorsByType,
    required this.dominantCategory,
    required this.dominantSeverity,
    required this.timeSpan,
  });

  final int totalErrors;
  final Map<ErrorCategory, int> errorsByCategory;
  final Map<ErrorSeverity, int> errorsBySeverity;
  final Map<String, int> errorsByType;
  final ErrorCategory dominantCategory;
  final ErrorSeverity dominantSeverity;
  final Duration timeSpan;

  factory ErrorPatternAnalysis.empty() {
    return const ErrorPatternAnalysis(
      totalErrors: 0,
      errorsByCategory: {},
      errorsBySeverity: {},
      errorsByType: {},
      dominantCategory: ErrorCategory.unknown,
      dominantSeverity: ErrorSeverity.unknown,
      timeSpan: Duration.zero,
    );
  }
}

/// Comprehensive system health report
class SystemHealthReport {
  const SystemHealthReport({
    required this.healthScore,
    required this.isHealthy,
    required this.hasActiveAlerts,
    required this.cascadingFailureAnalysis,
    required this.errorPatternAnalysis,
    required this.timestamp,
  });

  final int healthScore;
  final bool isHealthy;
  final bool hasActiveAlerts;
  final CascadingFailureAnalysis cascadingFailureAnalysis;
  final ErrorPatternAnalysis errorPatternAnalysis;
  final DateTime timestamp;

  Map<String, dynamic> toMap() {
    return {
      'health_score': healthScore,
      'is_healthy': isHealthy,
      'has_active_alerts': hasActiveAlerts,
      'cascading_failure': {
        'detected': cascadingFailureAnalysis.isCascadingFailure,
        'unique_error_types': cascadingFailureAnalysis.uniqueErrorTypes,
        'total_errors': cascadingFailureAnalysis.totalErrors,
      },
      'error_patterns': {
        'total_errors': errorPatternAnalysis.totalErrors,
        'dominant_category': errorPatternAnalysis.dominantCategory.value,
        'dominant_severity': errorPatternAnalysis.dominantSeverity.value,
      },
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

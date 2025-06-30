/// Configuration interface for error monitoring
abstract class ErrorMonitoringConfig {
  int get maxHistorySize;
  int get criticalErrorThreshold;
  int get cascadingFailureMinErrorTypes;
  int get cascadingFailureMinErrors;
  int get systemHealthErrorThreshold;
  int get maxHealthScoreErrors;
  
  Duration get errorWindowDuration;
  Duration get circuitBreakerCooldown;
  Duration get cascadingFailureWindow;
  Duration get healthCheckWindow;
  Duration get statsWindow24h;
  Duration get statsWindow1h;
  
  int get maxFrequentErrorsToShow;
  bool get enableRealTimeAlerting;
  bool get enableHealthMonitoring;
}

/// Default production configuration
class DefaultErrorMonitoringConfig implements ErrorMonitoringConfig {
  const DefaultErrorMonitoringConfig();

  @override
  int get maxHistorySize => 1000;

  @override
  int get criticalErrorThreshold => 5;

  @override
  int get cascadingFailureMinErrorTypes => 3;

  @override
  int get cascadingFailureMinErrors => 8;

  @override
  int get systemHealthErrorThreshold => 10;

  @override
  int get maxHealthScoreErrors => 20;

  @override
  Duration get errorWindowDuration => const Duration(minutes: 5);

  @override
  Duration get circuitBreakerCooldown => const Duration(minutes: 15);

  @override
  Duration get cascadingFailureWindow => const Duration(minutes: 2);

  @override
  Duration get healthCheckWindow => const Duration(minutes: 5);

  @override
  Duration get statsWindow24h => const Duration(hours: 24);

  @override
  Duration get statsWindow1h => const Duration(hours: 1);

  @override
  int get maxFrequentErrorsToShow => 5;

  @override
  bool get enableRealTimeAlerting => true;

  @override
  bool get enableHealthMonitoring => true;
}

/// Test configuration with shorter intervals
class TestErrorMonitoringConfig implements ErrorMonitoringConfig {
  const TestErrorMonitoringConfig();

  @override
  int get maxHistorySize => 100;

  @override
  int get criticalErrorThreshold => 3;

  @override
  int get cascadingFailureMinErrorTypes => 2;

  @override
  int get cascadingFailureMinErrors => 4;

  @override
  int get systemHealthErrorThreshold => 5;

  @override
  int get maxHealthScoreErrors => 10;

  @override
  Duration get errorWindowDuration => const Duration(seconds: 30);

  @override
  Duration get circuitBreakerCooldown => const Duration(seconds: 60);

  @override
  Duration get cascadingFailureWindow => const Duration(seconds: 15);

  @override
  Duration get healthCheckWindow => const Duration(seconds: 30);

  @override
  Duration get statsWindow24h => const Duration(hours: 1);

  @override
  Duration get statsWindow1h => const Duration(minutes: 5);

  @override
  int get maxFrequentErrorsToShow => 3;

  @override
  bool get enableRealTimeAlerting => true;

  @override
  bool get enableHealthMonitoring => true;
}

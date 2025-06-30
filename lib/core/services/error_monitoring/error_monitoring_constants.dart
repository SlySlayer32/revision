/// Constants for error monitoring configuration
class ErrorMonitoringConstants {
  static const int maxHistorySize = 1000;
  static const int criticalErrorThreshold = 5;
  static const int cascadingFailureMinErrorTypes = 3;
  static const int cascadingFailureMinErrors = 8;
  static const int systemHealthErrorThreshold = 10;
  static const int maxHealthScoreErrors = 20;
  
  static const Duration errorWindowDuration = Duration(minutes: 5);
  static const Duration circuitBreakerCooldown = Duration(minutes: 15);
  static const Duration cascadingFailureWindow = Duration(minutes: 2);
  static const Duration healthCheckWindow = Duration(minutes: 5);
  static const Duration statsWindow24h = Duration(hours: 24);
  static const Duration statsWindow1h = Duration(hours: 1);
  
  static const int maxFrequentErrorsToShow = 5;
  static const int maxHealthScore = 100;
  static const int minHealthScore = 0;
  
  ErrorMonitoringConstants._();
}

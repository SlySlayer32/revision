/// Error category enumeration
enum ErrorCategory {
  network('network'),
  authentication('authentication'),
  aiService('ai_service'),
  validation('validation'),
  permission('permission'),
  circuitBreaker('circuit_breaker'),
  storage('storage'),
  firebase('firebase'),
  unknown('unknown');

  const ErrorCategory(this.value);
  final String value;

  @override
  String toString() => value;
}

/// Error severity levels
enum ErrorSeverity {
  low('low'),
  medium('medium'),
  high('high'),
  critical('critical'),
  unknown('unknown');

  const ErrorSeverity(this.value);
  final String value;

  @override 
  String toString() => value;
}

/// Alert types for different monitoring scenarios
enum AlertType {
  criticalErrorPattern('CRITICAL_ERROR_PATTERN'),
  cascadingFailure('CASCADING_FAILURE'),
  systemHealthDegraded('SYSTEM_HEALTH_DEGRADED'),
  circuitBreakerTripped('CIRCUIT_BREAKER_TRIPPED');

  const AlertType(this.value);
  final String value;

  @override
  String toString() => value;
}

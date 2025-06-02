import 'dart:developer';

import 'package:revision/core/error/exceptions.dart';

/// Circuit breaker states for managing service health
enum CircuitBreakerState { closed, open, halfOpen }

/// Circuit breaker service for AI service resilience following VGV patterns
class CircuitBreakerService {
  static final Map<String, CircuitBreaker> _breakers = {};

  /// Get or create circuit breaker for Vertex AI
  static CircuitBreaker get vertexAI => _breakers.putIfAbsent(
        'vertex_ai',
        () => CircuitBreaker(
          failureThreshold: 5,
          recoveryTimeout: const Duration(minutes: 2),
          onStateChange: (state) => _logStateChange('vertex_ai', state),
        ),
      );

  /// Execute operation with circuit breaker protection
  static Future<T> executeWithBreaker<T>(
    String service,
    Future<T> Function() operation,
  ) async {
    final breaker = _breakers[service];
    if (breaker == null) {
      throw Exception('Circuit breaker not found for service: $service');
    }

    return breaker.execute(operation);
  }

  /// Reset circuit breaker for a service
  static void reset(String service) {
    _breakers[service]?.reset();
  }

  /// Get current state of circuit breaker
  static CircuitBreakerState? getState(String service) {
    return _breakers[service]?.state;
  }

  static void _logStateChange(String service, CircuitBreakerState state) {
    log('🔌 Circuit breaker for $service changed to: ${state.name}');
  }
}

/// Individual circuit breaker implementation
class CircuitBreaker {
  CircuitBreaker({
    required this.failureThreshold,
    required this.recoveryTimeout,
    this.onStateChange,
  });
  CircuitBreakerState _state = CircuitBreakerState.closed;
  int _failureCount = 0;
  DateTime? _lastFailureTime;

  final int failureThreshold;
  final Duration recoveryTimeout;
  final void Function(CircuitBreakerState)? onStateChange;

  /// Current state of the circuit breaker
  CircuitBreakerState get state => _state;

  /// Execute operation with circuit breaker protection
  Future<T> execute<T>(Future<T> Function() operation) async {
    if (_state == CircuitBreakerState.open) {
      if (_shouldAttemptReset()) {
        _state = CircuitBreakerState.halfOpen;
        onStateChange?.call(_state);
      } else {
        throw const CircuitBreakerOpenException();
      }
    }

    try {
      final result = await operation();
      _onSuccess();
      return result;
    } catch (e) {
      _onFailure();
      rethrow;
    }
  }

  /// Reset circuit breaker to closed state
  void reset() {
    _failureCount = 0;
    _state = CircuitBreakerState.closed;
    _lastFailureTime = null;
    onStateChange?.call(_state);
  }

  void _onSuccess() {
    _failureCount = 0;
    _state = CircuitBreakerState.closed;
    onStateChange?.call(_state);
  }

  void _onFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_failureCount >= failureThreshold) {
      _state = CircuitBreakerState.open;
      onStateChange?.call(_state);
    }
  }

  bool _shouldAttemptReset() {
    return _lastFailureTime != null &&
        DateTime.now().difference(_lastFailureTime!) > recoveryTimeout;
  }
}

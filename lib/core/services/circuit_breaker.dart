import 'dart:async';

import 'package:revision/core/constants/app_constants.dart';
import 'package:revision/core/error/exceptions.dart';

/// Circuit breaker states following VGV patterns
enum CircuitBreakerState { closed, open, halfOpen }

/// Circuit breaker for resilient service calls
class CircuitBreaker {
  CircuitBreaker({
    this.failureThreshold = AppConstants.circuitBreakerFailureThreshold,
    this.timeout = AppConstants.circuitBreakerTimeout,
    this.resetTimeout = AppConstants.circuitBreakerResetTimeout,
  });

  final int failureThreshold;
  final Duration timeout;
  final Duration resetTimeout;

  CircuitBreakerState _state = CircuitBreakerState.closed;
  int _failureCount = 0;
  DateTime? _lastFailureTime;
  Timer? _resetTimer;

  CircuitBreakerState get state => _state;
  int get failureCount => _failureCount;

  /// Execute a function with circuit breaker protection
  Future<T> execute<T>(Future<T> Function() operation) async {
    if (_state == CircuitBreakerState.open) {
      if (_shouldAttemptReset()) {
        _state = CircuitBreakerState.halfOpen;
      } else {
        throw const NetworkException('Circuit breaker is open');
      }
    }

    try {
      final result = await operation().timeout(timeout);
      _onSuccess();
      return result;
    } catch (e) {
      _onFailure();
      rethrow;
    }
  }

  /// Handle successful operation
  void _onSuccess() {
    _failureCount = 0;
    _lastFailureTime = null;
    _resetTimer?.cancel();
    _resetTimer = null;
    _state = CircuitBreakerState.closed;
  }

  /// Handle failed operation
  void _onFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_failureCount >= failureThreshold) {
      _state = CircuitBreakerState.open;
      _scheduleReset();
    }
  }

  /// Check if we should attempt to reset the circuit breaker
  bool _shouldAttemptReset() {
    if (_lastFailureTime == null) return false;
    return DateTime.now().difference(_lastFailureTime!) >= resetTimeout;
  }

  /// Schedule automatic reset of the circuit breaker
  void _scheduleReset() {
    _resetTimer?.cancel();
    _resetTimer = Timer(resetTimeout, () {
      _state = CircuitBreakerState.halfOpen;
    });
  }

  /// Reset the circuit breaker manually
  void reset() {
    _failureCount = 0;
    _lastFailureTime = null;
    _resetTimer?.cancel();
    _resetTimer = null;
    _state = CircuitBreakerState.closed;
  }

  /// Dispose of resources
  void dispose() {
    _resetTimer?.cancel();
    _resetTimer = null;
  }
}

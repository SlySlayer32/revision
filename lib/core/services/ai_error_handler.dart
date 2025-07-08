import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;

// import 'package:firebase_ai/firebase_ai.dart'; // Removed - using REST API instead
import 'package:revision/core/constants/firebase_ai_constants.dart';
import 'package:revision/core/utils/enhanced_logger.dart';

/// Robust error handling and retry logic for Firebase AI SDK
/// Addresses the "Unhandled format for Content: {role: model}" error
class AIErrorHandler {
  AIErrorHandler({
    int? maxRetries,
    int? baseDelayMs,
    int? maxDelayMs,
    int? circuitBreakerThreshold,
    int? circuitBreakerTimeoutMs,
  }) : maxRetries = maxRetries ?? FirebaseAIConstants.maxRetries,
       baseDelayMs =
           baseDelayMs ?? FirebaseAIConstants.retryBaseDelay.inMilliseconds,
       maxDelayMs =
           maxDelayMs ?? FirebaseAIConstants.retryMaxDelay.inMilliseconds,
       circuitBreakerThreshold =
           circuitBreakerThreshold ??
           FirebaseAIConstants.circuitBreakerThreshold,
       circuitBreakerTimeoutMs =
           circuitBreakerTimeoutMs ??
           FirebaseAIConstants.circuitBreakerTimeout.inMilliseconds;

  final int maxRetries;
  final int baseDelayMs;
  final int maxDelayMs;
  final int circuitBreakerThreshold;
  final int circuitBreakerTimeoutMs;

  // Circuit breaker state
  int _failureCount = 0;
  DateTime? _lastFailureTime;
  bool _isCircuitOpen = false;

  /// Execute AI call with comprehensive error handling
  Future<T> executeWithRetry<T>(
    Future<T> Function() operation,
    String operationName, {
    bool validateResponse = true,
  }) async {
    if (_isCircuitOpen) {
      if (_shouldResetCircuit()) {
        _resetCircuit();
      } else {
        throw AICircuitBreakerException(
          'Circuit breaker is open for $operationName. Too many failures.',
        );
      }
    }

    Exception? lastException;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        log('🔄 Attempt ${attempt + 1}/$maxRetries for $operationName');

        final result = await operation();

        if (validateResponse && !_isValidResponse(result)) {
          throw AIEmptyResponseException(
            'Empty or invalid response from $operationName',
          );
        }

        // Success - reset failure count
        _onSuccess();
        return result;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());

        if (!_isRetryableError(e)) {
          log('❌ Non-retryable error in $operationName: $e');
          _onFailure();
          rethrow;
        }

        if (attempt < maxRetries - 1) {
          final delay = _calculateDelay(attempt);
          logger.aiRetry(operationName, attempt + 1, maxRetries, e);
          await Future.delayed(delay);
        } else {
          logger.error(
            'All retries exhausted for $operationName',
            operation: operationName,
          );
        }
      }
    }

    _onFailure();
    throw AIMaxRetriesExceededException(
      'Max retries ($maxRetries) exceeded for $operationName',
      lastException,
    );
  }

  /// Validate AI response to catch empty/malformed responses
  bool _isValidResponse<T>(T response) {
    if (response == null) return false;

    if (response is String) {
      return response.trim().isNotEmpty;
    }

    return true;
  }

  /// Determine if error should trigger retry
  bool _isRetryableError(dynamic error) {
    final errorMessage = error.toString().toLowerCase();

    // Known retryable errors
    if (errorMessage.contains('unhandled format for content')) return true;
    if (errorMessage.contains('role: model')) return true;
    if (errorMessage.contains('empty response')) return true;
    if (errorMessage.contains('timeout')) return true;
    if (errorMessage.contains('network')) return true;
    if (errorMessage.contains('connection')) return true;
    if (errorMessage.contains('429')) return true; // Rate limiting
    if (errorMessage.contains('503')) return true; // Service unavailable
    if (errorMessage.contains('502')) return true; // Bad gateway
    if (errorMessage.contains('500')) return true; // Server error

    // REST API specific errors (HTTP status codes)
    if (errorMessage.contains('400')) return false; // Bad request - don't retry
    if (errorMessage.contains('401'))
      return false; // Unauthorized - don't retry
    if (errorMessage.contains('403')) return false; // Forbidden - don't retry

    return false;
  }

  /// Calculate exponential backoff delay with jitter
  Duration _calculateDelay(int attempt) {
    final exponentialDelay = math
        .min(baseDelayMs * math.pow(2, attempt), maxDelayMs)
        .toInt();

    // Add jitter (±25% randomness)
    final jitter =
        (exponentialDelay * 0.25 * (math.Random().nextDouble() - 0.5)).toInt();
    final totalDelay = exponentialDelay + jitter;

    return Duration(milliseconds: math.max(totalDelay, baseDelayMs));
  }

  /// Handle successful operation
  void _onSuccess() {
    _failureCount = 0;
    _lastFailureTime = null;
    _isCircuitOpen = false;
  }

  /// Handle failed operation
  void _onFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_failureCount >= circuitBreakerThreshold) {
      _isCircuitOpen = true;
      logger.circuitBreakerOpen('GENERIC', failureCount: _failureCount);
    }
  }

  /// Check if circuit should be reset
  bool _shouldResetCircuit() {
    if (_lastFailureTime == null) return false;

    final timeSinceLastFailure = DateTime.now().difference(_lastFailureTime!);
    return timeSinceLastFailure.inMilliseconds > circuitBreakerTimeoutMs;
  }

  /// Reset circuit breaker
  void _resetCircuit() {
    logger.circuitBreakerReset('GENERIC');
    _failureCount = 0;
    _lastFailureTime = null;
    _isCircuitOpen = false;
  }

  /// Get current circuit breaker status
  Map<String, dynamic> getCircuitStatus() {
    return {
      'isOpen': _isCircuitOpen,
      'failureCount': _failureCount,
      'lastFailureTime': _lastFailureTime?.toIso8601String(),
      'timeUntilReset': _lastFailureTime != null
          ? math.max(
              0,
              circuitBreakerTimeoutMs -
                  DateTime.now().difference(_lastFailureTime!).inMilliseconds,
            )
          : 0,
    };
  }
}

/// Custom exceptions for AI operations
class AIException implements Exception {
  const AIException(this.message, [this.cause]);

  final String message;
  final Exception? cause;

  @override
  String toString() =>
      'AIException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

class AIEmptyResponseException extends AIException {
  const AIEmptyResponseException(String message) : super(message);
}

class AICircuitBreakerException extends AIException {
  const AICircuitBreakerException(String message) : super(message);
}

class AIMaxRetriesExceededException extends AIException {
  const AIMaxRetriesExceededException(String message, Exception? cause)
    : super(message, cause);
}

class AIResponseValidationException extends AIException {
  const AIResponseValidationException(String message) : super(message);
}

/// Response validator for REST API operations
class AIResponseValidator {
  /// Validate REST API response text
  static String validateAndExtractText(String response) {
    if (response.trim().isEmpty) {
      throw const AIResponseValidationException('Empty response text');
    }
    return response.trim();
  }

  /// Validate base64 image data
  static List<int> validateAndExtractImageData(String base64Data) {
    if (base64Data.trim().isEmpty) {
      throw const AIResponseValidationException('Empty image data');
    }

    try {
      return base64Decode(base64Data);
    } catch (e) {
      throw AIResponseValidationException('Invalid base64 image data: $e');
    }
  }
}

import 'dart:collection';
import 'dart:developer';

import 'package:revision/core/services/secure_logger.dart';

/// Configuration for rate limiting per operation.
class RateLimitConfig {
  final int maxRequests;
  final Duration window;

  const RateLimitConfig({
    required this.maxRequests,
    required this.window,
  });
}

/// Exception thrown when rate limit is exceeded.
class RateLimitExceededException implements Exception {
  final String message;
  final String operation;
  final Duration retryAfter;

  RateLimitExceededException(
    this.message, {
    required this.operation,
    required this.retryAfter,
  });

  @override
  String toString() =>
      'RateLimitExceededException: $message (retry after: ${retryAfter.inSeconds}s)';
}

/// Implements per-operation rate limiting with configurable windows.
class RateLimitingService {
  // Singleton pattern
  static final RateLimitingService _instance = RateLimitingService._internal();
  static RateLimitingService get instance => _instance;
  RateLimitingService._internal();

  // Stores per-operation limiters
  final Map<String, RateLimiter> _limiters = {};

  /// Get or create a rate limiter for an operation
  RateLimiter getLimiter(String operation) {
    return _limiters.putIfAbsent(
      operation,
      () {
        final config = _getConfigForOperation(operation);
        return RateLimiter(
          maxRequests: config.maxRequests,
          window: config.window,
          operation: operation,
        );
      },
    );
  }

  /// Checks if the operation is currently rate limited.
  bool isRateLimited(String operation) {
    final limiter = getLimiter(operation);
    return limiter.isLimited();
  }

  /// Resets the limiter for a given operation.
  void resetLimiter(String operation) {
    _limiters[operation]?.reset();
  }

  /// Executes [function] with rate limiting for [operation].
  /// Throws [RateLimitExceededException] if limit reached.
  Future<T> executeWithRateLimit<T>(
    String operation,
    Future<T> Function() function,
  ) async {
    final limiter = getLimiter(operation);

    if (limiter.isLimited()) {
      SecureLogger.logAuditEvent(
        'Rate limit exceeded',
        operation: operation,
        details: {
          'maxRequests': limiter.maxRequests,
          'windowMs': limiter.window.inMilliseconds,
        },
      );
      throw RateLimitExceededException(
        'Rate limit exceeded for operation: $operation',
        operation: operation,
        retryAfter: limiter.getRetryAfter(),
      );
    }

    limiter.recordRequest();

    try {
      return await function();
    } finally {
      limiter.cleanup();
    }
  }

  /// Returns configuration for a given operation.
  RateLimitConfig _getConfigForOperation(String operation) {
    switch (operation) {
      case 'gemini_text':
        return const RateLimitConfig(
          maxRequests: 10,
          window: Duration(minutes: 1),
        );
      case 'gemini_multimodal':
        return const RateLimitConfig(
          maxRequests: 5,
          window: Duration(minutes: 1),
        );
      case 'gemini_segmentation':
        return const RateLimitConfig(
          maxRequests: 3,
          window: Duration(minutes: 1),
        );
      case 'gemini_image_generation':
        return const RateLimitConfig(
          maxRequests: 2,
          window: Duration(minutes: 1),
        );
      case 'gemini_object_detection':
        return const RateLimitConfig(
          maxRequests: 3,
          window: Duration(minutes: 1),
        );
      default:
        return const RateLimitConfig(
          maxRequests: 10,
          window: Duration(minutes: 1),
        );
    }
  }
}

/// Handles rate limiting for a single operation.
class RateLimiter {
  final int maxRequests;
  final Duration window;
  final String operation;
  final List<DateTime> _requestTimes = [];

  RateLimiter({
    required this.maxRequests,
    required this.window,
    required this.operation,
  });

  /// Returns true if rate limit is currently exceeded.
  bool isLimited() {
    _cleanupOldRequests();
    return _requestTimes.length >= maxRequests;
  }

  /// Records a new request timestamp.
  void recordRequest() {
    _requestTimes.add(DateTime.now());
  }

  /// Returns the time remaining until requests are allowed again.
  Duration getRetryAfter() {
    if (_requestTimes.isEmpty) return Duration.zero;
    final oldest = _requestTimes.first;
    final resetTime = oldest.add(window);
    final now = DateTime.now();
    return resetTime.isAfter(now) ? resetTime.difference(now) : Duration.zero;
  }

  /// Removes old request timestamps outside the window.
  void cleanup() => _cleanupOldRequests();

  /// Clears all recorded requests.
  void reset() => _requestTimes.clear();

  void _cleanupOldRequests() {
    final now = DateTime.now();
    _requestTimes.removeWhere((t) => now.difference(t) > window);
  }
}
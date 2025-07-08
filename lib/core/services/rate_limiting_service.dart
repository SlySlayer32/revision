import 'dart:developer';

import 'package:revision/core/services/secure_logger.dart';

/// Rate limiting service for API calls
class RateLimitingService {
  static final RateLimitingService _instance = RateLimitingService._internal();
  static RateLimitingService get instance => _instance;
  
  RateLimitingService._internal();

  final Map<String, RateLimiter> _limiters = {};

  /// Get or create rate limiter for a specific operation
  RateLimiter getLimiter(String operation) {
    return _limiters.putIfAbsent(operation, () {
      final config = _getConfigForOperation(operation);
      return RateLimiter(
        maxRequests: config.maxRequests,
        window: config.window,
        operation: operation,
      );
    });
  }

  /// Check if operation is rate limited
  bool isRateLimited(String operation) {
    final limiter = getLimiter(operation);
    return limiter.isLimited();
  }

  /// Execute operation with rate limiting
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
      // Clean up old entries periodically
      limiter.cleanup();
    }
  }

  /// Reset rate limiter for specific operation
  void resetLimiter(String operation) {
    _limiters[operation]?.reset();
  }

  /// Get rate limit configuration for operation
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
      default:
        return const RateLimitConfig(
          maxRequests: 10,
          window: Duration(minutes: 1),
        );
    }
  }
}

/// Individual rate limiter implementation
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

  /// Check if rate limit is exceeded
  bool isLimited() {
    _cleanupOldRequests();
    return _requestTimes.length >= maxRequests;
  }

  /// Record a new request
  void recordRequest() {
    _requestTimes.add(DateTime.now());
  }

  /// Get time until rate limit resets
  Duration getRetryAfter() {
    if (_requestTimes.isEmpty) {
      return Duration.zero;
    }
    
    final oldestRequest = _requestTimes.first;
    final resetTime = oldestRequest.add(window);
    final now = DateTime.now();
    
    if (resetTime.isAfter(now)) {
      return resetTime.difference(now);
    }
    
    return Duration.zero;
  }

  /// Clean up old requests outside the window
  void cleanup() {
    _cleanupOldRequests();
  }

  /// Reset rate limiter
  void reset() {
    _requestTimes.clear();
  }

  void _cleanupOldRequests() {
    final now = DateTime.now();
    _requestTimes.removeWhere((time) => now.difference(time) > window);
  }
}

/// Rate limit configuration
class RateLimitConfig {
  final int maxRequests;
  final Duration window;

  const RateLimitConfig({
    required this.maxRequests,
    required this.window,
  });
}

/// Exception thrown when rate limit is exceeded
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
  String toString() => 'RateLimitExceededException: $message (retry after: ${retryAfter.inSeconds}s)';
}
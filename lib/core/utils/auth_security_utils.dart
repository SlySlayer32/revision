import 'dart:async';
import 'dart:developer' as dev;

import 'package:revision/core/config/environment_detector.dart';
import 'package:revision/core/services/logging_service.dart';
import 'package:revision/core/utils/security_utils.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';

/// Authentication-specific security utilities for production applications
class AuthSecurityUtils {
  AuthSecurityUtils._();

  static const String _authRateLimitKey = 'auth_attempts';
  static const Duration _authTimeout = Duration(seconds: 30);
  static const Duration _sessionTimeout = Duration(minutes: 30);

  /// Logs authentication events with environment-aware logging
  /// and PII sanitization
  static void logAuthEvent(
    String event, {
    User? user,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    // Only log in development or with sanitized data in production
    if (EnvironmentDetector.isDevelopment) {
      LoggingService.instance.debug(
        'Auth Event: $event',
        error: error,
        stackTrace: stackTrace,
        data: {
          'userId': user?.id,
          'userEmail': user?.email, // Only in development
          ...?data,
        },
      );
    } else {
      // Production logging - sanitize PII
      LoggingService.instance.info(
        'Auth Event: $event',
        error: error,
        stackTrace: stackTrace,
        data: {
          'userId': user?.id,
          'hasUser': user != null,
          'userEmailHash': user?.email != null ? _hashEmail(user!.email) : null,
          ...?data,
        },
      );
    }
  }

  /// Logs authentication errors with proper categorization
  static void logAuthError(
    String context,
    Object error, {
    StackTrace? stackTrace,
    User? user,
    Map<String, dynamic>? data,
  }) {
    LoggingService.instance.error(
      'Auth Error in $context: ${error.toString()}',
      error: error,
      stackTrace: stackTrace,
      data: {
        'context': context,
        'userId': user?.id,
        'hasUser': user != null,
        'errorType': error.runtimeType.toString(),
        ...?data,
      },
    );
  }

  /// Checks if authentication attempts are rate limited
  static bool isAuthRateLimited(String identifier) {
    return SecurityUtils.isRateLimited(
      '${_authRateLimitKey}_$identifier',
      maxRequests: 5,
      window: const Duration(minutes: 15),
    );
  }

  /// Creates a timeout-aware future for authentication operations
  static Future<T> withAuthTimeout<T>(
    Future<T> operation,
    String operationName,
  ) async {
    try {
      return await operation.timeout(
        _authTimeout,
        onTimeout: () {
          logAuthError(
            operationName,
            TimeoutException('Authentication operation timed out', _authTimeout),
          );
          throw TimeoutException(
            'Authentication operation timed out',
            _authTimeout,
          );
        },
      );
    } catch (e) {
      logAuthError(operationName, e);
      rethrow;
    }
  }

  /// Checks if a user session has timed out
  static bool isSessionTimedOut(DateTime? lastActivity) {
    if (lastActivity == null) return true;
    
    final now = DateTime.now();
    final timeSinceLastActivity = now.difference(lastActivity);
    
    return timeSinceLastActivity > _sessionTimeout;
  }

  /// Sanitizes user data for logging
  static Map<String, dynamic> sanitizeUserData(User? user) {
    if (user == null) {
      return {'hasUser': false};
    }

    return {
      'hasUser': true,
      'userId': user.id,
      'userEmailHash': _hashEmail(user.email),
      'isEmailVerified': user.isEmailVerified,
    };
  }

  /// Categorizes authentication errors for better error handling
  static AuthErrorCategory categorizeAuthError(Object error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || 
        errorString.contains('connection') ||
        errorString.contains('timeout')) {
      return AuthErrorCategory.network;
    }
    
    if (errorString.contains('permission') ||
        errorString.contains('unauthorized') ||
        errorString.contains('forbidden')) {
      return AuthErrorCategory.permission;
    }
    
    if (errorString.contains('user-not-found') ||
        errorString.contains('wrong-password') ||
        errorString.contains('invalid-email')) {
      return AuthErrorCategory.credential;
    }
    
    if (errorString.contains('too-many-requests') ||
        errorString.contains('rate-limit')) {
      return AuthErrorCategory.rateLimit;
    }
    
    return AuthErrorCategory.unknown;
  }

  /// Creates a hash of email for logging purposes
  static String _hashEmail(String email) {
    // Simple hash for logging - not for security
    return email.split('@').first.substring(0, 1) + 
           '***@' + 
           email.split('@').last;
  }
}

/// Authentication error categories for better error handling
enum AuthErrorCategory {
  network,
  permission,
  credential,
  rateLimit,
  unknown;

  /// Gets user-friendly error message
  String get userMessage {
    switch (this) {
      case AuthErrorCategory.network:
        return 'Network connection issue. Please check your internet connection.';
      case AuthErrorCategory.permission:
        return 'Access denied. Please try signing in again.';
      case AuthErrorCategory.credential:
        return 'Invalid credentials. Please check your email and password.';
      case AuthErrorCategory.rateLimit:
        return 'Too many attempts. Please wait a moment and try again.';
      case AuthErrorCategory.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Gets retry delay for this error category
  Duration get retryDelay {
    switch (this) {
      case AuthErrorCategory.network:
        return const Duration(seconds: 5);
      case AuthErrorCategory.permission:
        return const Duration(seconds: 10);
      case AuthErrorCategory.credential:
        return const Duration(seconds: 3);
      case AuthErrorCategory.rateLimit:
        return const Duration(minutes: 1);
      case AuthErrorCategory.unknown:
        return const Duration(seconds: 5);
    }
  }
}
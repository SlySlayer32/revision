import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:revision/core/error/failures.dart';
import 'package:revision/core/services/logging_service.dart';

/// Production-grade error handling service that provides centralized
/// error handling, user-friendly error messages, and error reporting
class ErrorHandlerService {
  const ErrorHandlerService._();

  static const ErrorHandlerService _instance = ErrorHandlerService._();
  static ErrorHandlerService get instance => _instance;

  /// Handles errors and shows appropriate user feedback
  void handleError(
    BuildContext context,
    Object error, {
    StackTrace? stackTrace,
    String? userMessage,
    Map<String, dynamic>? metadata,
  }) {
    final errorInfo = _categorizeError(error);

    // Log the error
    LoggingService.instance.error(
      errorInfo.technicalMessage,
      error: error,
      stackTrace: stackTrace,
      data: {
        'category': errorInfo.category.name,
        'userFriendly': errorInfo.userMessage,
        ...?metadata,
      },
    );

    // Show user-friendly message
    final displayMessage = userMessage ?? errorInfo.userMessage;
    _showErrorToUser(context, displayMessage, errorInfo.category);
  }

  /// Handles authentication errors specifically
  void handleAuthError(
    BuildContext context,
    Object error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    String userMessage;

    if (error is FirebaseAuthException) {
      userMessage = _getFirebaseAuthErrorMessage(error);
    } else {
      userMessage = 'Authentication failed. Please try again.';
    }

    handleError(
      context,
      error,
      stackTrace: stackTrace,
      userMessage: userMessage,
      metadata: {'authError': true, ...?metadata},
    );
  }

  /// Handles network errors specifically
  void handleNetworkError(
    BuildContext context,
    Object error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    const userMessage =
        'Network error. Please check your internet connection and try again.';

    handleError(
      context,
      error,
      stackTrace: stackTrace,
      userMessage: userMessage,
      metadata: {'networkError': true, ...?metadata},
    );
  }

  /// Handles file operation errors
  void handleFileError(
    BuildContext context,
    Object error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    const userMessage =
        'File operation failed. Please check permissions and try again.';

    handleError(
      context,
      error,
      stackTrace: stackTrace,
      userMessage: userMessage,
      metadata: {'fileError': true, ...?metadata},
    );
  }

  /// Handles AI processing errors
  void handleAIError(
    BuildContext context,
    Object error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    const userMessage =
        'AI processing failed. Please try again or contact support if the issue persists.';

    handleError(
      context,
      error,
      stackTrace: stackTrace,
      userMessage: userMessage,
      metadata: {'aiError': true, ...?metadata},
    );
  }

  /// Registers global error handlers
  static void registerGlobalHandlers() {
    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      LoggingService.instance.fatal(
        'Flutter Error: ${details.exception}',
        error: details.exception,
        stackTrace: details.stack,
        data: {
          'library': details.library,
          'context': details.context?.toString(),
        },
      );
    };

    // Handle async errors that weren't caught
    // Note: PlatformDispatcher is available in Flutter 3.0+
    // For older versions, use runZonedGuarded
    try {
      // Use ServicesBinding for error handling
      ServicesBinding.instance.platformDispatcher.onError = (error, stack) {
        LoggingService.instance.fatal(
          'Uncaught Error: $error',
          error: error,
          stackTrace: stack,
        );
        return true;
      };
    } catch (e) {
      // Fallback for older Flutter versions
      LoggingService.instance.warning('Could not set global error handler: $e');
    }
  }

  /// Shows error to user based on severity
  void _showErrorToUser(
    BuildContext context,
    String message,
    ErrorCategory category,
  ) {
    if (!context.mounted) return;

    switch (category) {
      case ErrorCategory.critical:
        _showErrorDialog(context, 'Critical Error', message);
        break;
      case ErrorCategory.warning:
        _showWarningSnackBar(context, message);
        break;
      case ErrorCategory.info:
        _showInfoSnackBar(context, message);
        break;
    }
  }

  /// Shows error dialog for critical errors
  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Shows warning snackbar
  void _showWarningSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Shows info snackbar
  void _showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  /// Categorizes errors for appropriate handling
  ErrorInfo _categorizeError(Object error) {
    if (error is FirebaseAuthException) {
      return ErrorInfo(
        category: ErrorCategory.warning,
        userMessage: _getFirebaseAuthErrorMessage(error),
        technicalMessage:
            'Firebase Auth Error: ${error.code} - ${error.message}',
      );
    }

    if (error is NetworkFailure) {
      return ErrorInfo(
        category: ErrorCategory.warning,
        userMessage: 'Network connection problem. Please check your internet.',
        technicalMessage: 'Network Failure: ${error.message}',
      );
    }

    if (error is Exception && error.toString().contains('Server')) {
      return ErrorInfo(
        category: ErrorCategory.warning,
        userMessage: 'Server error. Please try again later.',
        technicalMessage: 'Server Error: ${error.toString()}',
      );
    }

    if (error is ValidationFailure) {
      return ErrorInfo(
        category: ErrorCategory.info,
        userMessage: error.message,
        technicalMessage: 'Validation Failure: ${error.message}',
      );
    }

    if (error is TimeoutException) {
      return ErrorInfo(
        category: ErrorCategory.warning,
        userMessage: 'Operation timed out. Please try again.',
        technicalMessage: 'Timeout: ${error.message}',
      );
    }

    // Default for unknown errors
    return ErrorInfo(
      category: ErrorCategory.critical,
      userMessage:
          'An unexpected error occurred. Please restart the app or contact support.',
      technicalMessage: 'Unknown Error: ${error.toString()}',
    );
  }

  /// Gets user-friendly message for Firebase Auth errors
  String _getFirebaseAuthErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}

/// Error category for determining user feedback type
enum ErrorCategory { info, warning, critical }

/// Error information for structured error handling
class ErrorInfo {
  const ErrorInfo({
    required this.category,
    required this.userMessage,
    required this.technicalMessage,
  });

  final ErrorCategory category;
  final String userMessage;
  final String technicalMessage;
}

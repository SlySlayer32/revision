import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:revision/core/error/failures.dart';
import 'package:revision/features/authentication/domain/exceptions/auth_exception.dart';

/// Production-grade exception handling service
///
/// Centralizes exception handling patterns to eliminate code duplication
/// and ensure consistent error processing across the application.
class ExceptionHandlerService {
  static final ExceptionHandlerService _instance = ExceptionHandlerService._();
  factory ExceptionHandlerService() => _instance;
  ExceptionHandlerService._();

  /// Handles Firebase Authentication exceptions with consistent mapping
  ///
  /// [operation] - Name of the operation being performed (for logging)
  /// [exception] - The caught exception
  /// [context] - Additional context for logging
  ///
  /// Returns appropriate [AuthenticationFailure] based on exception type
  AuthenticationFailure handleAuthException(
    String operation,
    dynamic exception, {
    Map<String, dynamic>? context,
  }) {
    // Log the exception with context
    log(
      'Authentication exception in $operation',
      error: exception,
      name: 'ExceptionHandler',
    );

    // Log additional context if provided
    if (context != null) {
      log('Context: ${context.toString()}', name: 'ExceptionHandler');
    }

    // Map Firebase exceptions to domain exceptions
    if (exception is FirebaseAuthException) {
      return _mapFirebaseAuthException(exception);
    }

    // Map domain exceptions
    if (exception is AuthException) {
      return AuthenticationFailure(exception.message, exception.code);
    }

    // Handle Firebase core exceptions
    if (exception is FirebaseException) {
      return AuthenticationFailure(
        'Firebase error: ${exception.message}',
        exception.code,
      );
    }

    // Handle network and timeout exceptions
    if (exception.toString().contains('timeout') ||
        exception.toString().contains('network')) {
      return const AuthenticationFailure(
        'Network error. Please check your internet connection.',
        'network-error',
      );
    }

    // Fallback for unexpected exceptions
    return AuthenticationFailure(
      'An unexpected error occurred: ${exception.toString()}',
      'unexpected-error',
    );
  }

  /// Maps FirebaseAuthException to appropriate AuthenticationFailure
  AuthenticationFailure _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return const AuthenticationFailure(
          'No user found with this email address.',
          'user-not-found',
        );
      case 'wrong-password':
        return const AuthenticationFailure(
          'Incorrect password provided.',
          'wrong-password',
        );
      case 'email-already-in-use':
        return const AuthenticationFailure(
          'This email address is already registered.',
          'email-already-in-use',
        );
      case 'weak-password':
        return const AuthenticationFailure(
          'Password is too weak. Please choose a stronger password.',
          'weak-password',
        );
      case 'invalid-email':
        return const AuthenticationFailure(
          'Invalid email address format.',
          'invalid-email',
        );
      case 'user-disabled':
        return const AuthenticationFailure(
          'This user account has been disabled.',
          'user-disabled',
        );
      case 'operation-not-allowed':
        return const AuthenticationFailure(
          'This operation is not allowed. Please contact support.',
          'operation-not-allowed',
        );
      case 'too-many-requests':
        return const AuthenticationFailure(
          'Too many failed attempts. Please try again later.',
          'too-many-requests',
        );
      case 'network-request-failed':
        return const AuthenticationFailure(
          'Network error. Please check your internet connection.',
          'network-request-failed',
        );
      case 'requires-recent-login':
        return const AuthenticationFailure(
          'This operation requires recent authentication. Please sign in again.',
          'requires-recent-login',
        );
      case 'credential-already-in-use':
        return const AuthenticationFailure(
          'This credential is already associated with another user account.',
          'credential-already-in-use',
        );
      case 'invalid-credential':
        return const AuthenticationFailure(
          'The authentication credential is invalid or expired.',
          'invalid-credential',
        );
      case 'account-exists-with-different-credential':
        return const AuthenticationFailure(
          'An account already exists with a different credential.',
          'account-exists-with-different-credential',
        );
      default:
        return AuthenticationFailure(
          e.message ?? 'Authentication failed',
          e.code,
        );
    }
  }

  /// Handles generic exceptions with structured logging
  ///
  /// [operation] - Name of the operation being performed
  /// [exception] - The caught exception
  /// [context] - Additional context for logging
  ///
  /// Returns appropriate [Failure] based on exception type
  Failure handleGenericException(
    String operation,
    dynamic exception, {
    Map<String, dynamic>? context,
  }) {
    // Log the exception with context
    log(
      'Exception in $operation',
      error: exception,
      name: 'ExceptionHandler',
    );

    // Log additional context if provided
    if (context != null) {
      log('Context: ${context.toString()}', name: 'ExceptionHandler');
    }

    // Handle specific exception types
    if (exception is FirebaseException) {
      return NetworkFailure(
        'Firebase error: ${exception.message}',
        exception.code,
      );
    }

    if (exception.toString().contains('timeout')) {
      return const NetworkFailure(
        'Operation timed out. Please try again.',
        'timeout',
      );
    }

    if (exception.toString().contains('network') ||
        exception.toString().contains('connection')) {
      return const NetworkFailure(
        'Network error. Please check your internet connection.',
        'network-error',
      );
    }

    // Fallback for unexpected exceptions
    return NetworkFailure(
      'An unexpected error occurred: ${exception.toString()}',
      'unexpected-error',
    );
  }

  /// Creates a performance-monitored exception handler wrapper
  ///
  /// [operation] - Name of the operation for logging
  /// [action] - The async action to execute
  ///
  /// Returns the result of the action or appropriate failure
  Future<T> withExceptionHandling<T>(
    String operation,
    Future<T> Function() action, {
    Map<String, dynamic>? context,
  }) async {
    try {
      log('Starting operation: $operation', name: 'ExceptionHandler');
      final result = await action();
      log('Completed operation: $operation', name: 'ExceptionHandler');
      return result;
    } catch (e) {
      log(
        'Exception in operation: $operation',
        error: e,
        name: 'ExceptionHandler',
      );

      if (context != null) {
        log('Context: ${context.toString()}', name: 'ExceptionHandler');
      }

      rethrow;
    }
  }
}

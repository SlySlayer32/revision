import 'dart:async';
import 'dart:developer' as developer;

import 'package:revision/core/utils/result.dart';
import 'package:revision/features/authentication/domain/repositories/auth_repository.dart';

/// Use case for sending email verification to authenticated users.
///
/// This use case handles the business logic for sending email verification
/// with proper error handling, rate limiting, and structured logging.
///
/// Usage:
/// ```dart
/// final result = await sendEmailVerificationUseCase();
/// result.fold(
///   success: (_) => print('Verification email sent'),
///   failure: (error) => print('Failed: $error'),
/// );
/// ```
class SendEmailVerificationUseCase {
  /// Creates a new [SendEmailVerificationUseCase]
  ///
  /// [_repository] - The authentication repository for email operations
  /// [_rateLimitDuration] - Minimum time between verification email requests
  const SendEmailVerificationUseCase(
    this._repository, {
    Duration rateLimitDuration = const Duration(minutes: 1),
  }) : _rateLimitDuration = rateLimitDuration;

  final AuthRepository _repository;
  final Duration _rateLimitDuration;

  // Static variable to track last email send time for rate limiting
  static DateTime? _lastEmailSentTime;

  /// Sends email verification to the currently signed-in user.
  ///
  /// This method will:
  /// - Validate that a user is currently authenticated
  /// - Check rate limiting to prevent spam
  /// - Check if the user's email is already verified
  /// - Send the verification email through the repository
  /// - Handle and log any errors that occur
  ///
  /// @returns [Result<void>] Success if email was sent, Failure with error message otherwise.
  Future<Result<void>> call() async {
    developer.log(
      'Attempting to send email verification',
      name: 'SendEmailVerificationUseCase',
    );

    try {
      // Validate user authentication state
      final authValidation = await _validateUserAuthentication();
      if (authValidation.isFailure) {
        return authValidation;
      }

      // Check rate limiting
      final rateLimitCheck = _checkRateLimit();
      if (rateLimitCheck.isFailure) {
        return rateLimitCheck;
      }

      // Check if email is already verified
      final verificationCheck = await _checkEmailVerificationStatus();
      if (verificationCheck.isFailure) {
        return verificationCheck;
      }

      // Send the verification email
      final either = await _repository.sendEmailVerification();
      final result = either.fold(
        (failure) {
          developer.log(
            'Failed to send verification email: ${failure.message}',
            name: 'SendEmailVerificationUseCase',
            level: 900,
          );
          return Failure<void>(Exception(failure.message));
        },
        (_) {
          _lastEmailSentTime = DateTime.now();
          developer.log(
            'Email verification request initiated successfully',
            name: 'SendEmailVerificationUseCase',
          );
          return const Success<void>(null);
        },
      );
      return result;
    } on TimeoutException catch (e) {
      final errorMessage = 'Request timed out while sending verification email';
      developer.log(
        errorMessage,
        name: 'SendEmailVerificationUseCase',
        error: e,
      );
      return Failure<void>(Exception(errorMessage));
    } on FormatException catch (e) {
      final errorMessage = 'Invalid email format detected';
      developer.log(
        errorMessage,
        name: 'SendEmailVerificationUseCase',
        error: e,
      );
      return Failure<void>(Exception(errorMessage));
    } catch (e, stackTrace) {
      final errorMessage =
          'Unexpected error occurred while sending verification email: e.toString()}';
      developer.log(
        errorMessage,
        name: 'SendEmailVerificationUseCase',
        error: e,
        stackTrace: stackTrace,
      );
      return Failure<void>(Exception(errorMessage));
    }
  }

  /// Validates that a user is currently authenticated.
  ///
  /// @returns [Result<void>] Success if a user is authenticated, Failure otherwise.
  /// @visibleForTesting
  Future<Result<void>> _validateUserAuthentication() async {
    try {
      final either = await _repository.getCurrentUser();
      return either.fold(
        (failure) {
          final errorMessage =
              'Failed to validate user authentication: ${failure.message}';
          developer.log(
            errorMessage,
            name: 'SendEmailVerificationUseCase',
            level: 900, // Warning level
          );
          return Failure<void>(Exception(errorMessage));
        },
        (user) {
          if (user == null) {
            final errorMessage = 'No user is currently signed in';
            developer.log(
              errorMessage,
              name: 'SendEmailVerificationUseCase',
              level: 900, // Warning level
            );
            return Failure<void>(Exception(errorMessage));
          }
          return const Success<void>(null);
        },
      );
    } catch (e) {
      final errorMessage =
          'Failed to validate user authentication: ${e.toString()}';
      developer.log(
        errorMessage,
        name: 'SendEmailVerificationUseCase',
        error: e,
      );
      return Failure<void>(Exception(errorMessage));
    }
  }

  /// Checks rate limiting to prevent spam email requests.
  ///
  /// @returns [Result<void>] Success if not rate limited, Failure otherwise.
  Result<void> _checkRateLimit() {
    if (_lastEmailSentTime != null) {
      final timeSinceLastEmail = DateTime.now().difference(_lastEmailSentTime!);
      if (timeSinceLastEmail < _rateLimitDuration) {
        final remainingTime = _rateLimitDuration - timeSinceLastEmail;
        final errorMessage =
            'Please wait ${remainingTime.inSeconds} seconds before requesting another verification email';
        developer.log(
          'Rate limit exceeded: $errorMessage',
          name: 'SendEmailVerificationUseCase',
          level: 900, // Warning level
        );
        return Failure<void>(Exception(errorMessage));
      }
    }
    return const Success<void>(null);
  }

  /// Checks if the user's email is already verified.
  ///
  /// @returns [Result<void>] Success if not verified, Failure if already verified.
  Future<Result<void>> _checkEmailVerificationStatus() async {
    try {
      final either = await _repository.getCurrentUser();
      return either.fold(
        (failure) {
          // If we can't check verification status, we'll proceed anyway
          developer.log(
            'Could not verify email verification status, proceeding anyway: ${failure.message}',
            name: 'SendEmailVerificationUseCase',
            level: 900, // Warning level
          );
          return const Success<void>(null);
        },
        (user) {
          if (user == null) {
            // If we can't check verification status, we'll proceed anyway
            developer.log(
              'Could not verify email verification status, proceeding anyway: user is null',
              name: 'SendEmailVerificationUseCase',
              level: 900, // Warning level
            );
            return const Success<void>(null);
          }
          if (user.isEmailVerified) {
            final errorMessage = 'Email is already verified';
            developer.log(
              errorMessage,
              name: 'SendEmailVerificationUseCase',
              level: 800, // Info level
            );
            return Failure<void>(Exception(errorMessage));
          }
          return const Success<void>(null);
        },
      );
    } catch (e) {
      // If we can't check verification status, we'll proceed anyway
      developer.log(
        'Could not verify email verification status, proceeding anyway: ${e.toString()}',
        name: 'SendEmailVerificationUseCase',
        level: 900, // Warning level
        error: e,
      );
      return const Success<void>(null);
    }
  }

  /// Resets the rate limiting timer (useful for testing).
  static void resetRateLimit() {
    _lastEmailSentTime = null;
    developer.log(
      'Rate limit reset',
      name: 'SendEmailVerificationUseCase',
    );
  }

  /// Gets the remaining time before another email can be sent.
  ///
  /// @returns [Duration?] The remaining cooldown duration, or null if no cooldown.
  Duration? getRemainingCooldown() {
    if (_lastEmailSentTime == null) return null;

    final timeSinceLastEmail = DateTime.now().difference(_lastEmailSentTime!);
    if (timeSinceLastEmail >= _rateLimitDuration) return null;

    return _rateLimitDuration - timeSinceLastEmail;
  }
}

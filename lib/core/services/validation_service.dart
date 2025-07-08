import 'dart:typed_data';

import 'package:revision/core/constants/app_constants.dart';
import 'package:revision/core/utils/result.dart';
import 'package:revision/features/ai_processing/domain/exceptions/ai_processing_exception.dart';

/// Production-grade input validation service
///
/// Provides comprehensive validation for all user inputs and data
/// to ensure security, data integrity, and prevent errors.
class ValidationService {
  static final ValidationService _instance = ValidationService._();
  factory ValidationService() => _instance;
  ValidationService._();

  // ============================================================================
  // EMAIL VALIDATION
  // ============================================================================

  /// Validates email address format and domain
  ///
  /// [email] - The email address to validate
  ///
  /// Returns [Success] if valid, [Failure] with validation error if invalid
  Result<void> validateEmail(String email) {
    if (email.isEmpty) {
      return const Failure(
        ValidationException('Email address cannot be empty'),
      );
    }

    if (email.length > 254) {
      return const Failure(
        ValidationException('Email address is too long (max 254 characters)'),
      );
    }

    if (!AppConstants.isValidEmail(email)) {
      return const Failure(
        ValidationException('Please enter a valid email address'),
      );
    }

    // Additional domain validation
    final domain = email.split('@').last;
    if (domain.isEmpty || domain.length < 3) {
      return const Failure(ValidationException('Invalid email domain'));
    }

    return const Success(null);
  }

  // ============================================================================
  // PASSWORD VALIDATION
  // ============================================================================

  /// Validates password strength and security requirements
  ///
  /// [password] - The password to validate
  ///
  /// Returns [Success] if valid, [Failure] with specific requirements if invalid
  Result<void> validatePassword(String password) {
    if (password.isEmpty) {
      return const Failure(ValidationException('Password cannot be empty'));
    }

    if (password.length < AppConstants.minPasswordLength) {
      return const Failure(
        ValidationException(
          'Password must be at least ${AppConstants.minPasswordLength} characters long',
        ),
      );
    }

    if (password.length > 128) {
      return const Failure(
        ValidationException('Password is too long (max 128 characters)'),
      );
    }

    // Check for common weak patterns
    if (_isCommonWeakPassword(password)) {
      return const Failure(
        ValidationException(
          'Password is too common. Please choose a more secure password.',
        ),
      );
    }

    // Check strength requirements
    if (!AppConstants.isStrongPassword(password)) {
      return const Failure(
        ValidationException(
          'Password must contain at least one uppercase letter, '
          'one lowercase letter, and one number',
        ),
      );
    }

    return const Success(null);
  }

  /// Checks if password matches common weak patterns
  bool _isCommonWeakPassword(String password) {
    final commonWeakPasswords = [
      'password',
      'password123',
      '123456',
      '12345678',
      'qwerty',
      'abc123',
      'admin',
      'letmein',
      'welcome',
      'monkey',
      'dragon',
      'master',
    ];

    return commonWeakPasswords.contains(password.toLowerCase()) ||
        _isSequentialPattern(password) ||
        _isRepeatingPattern(password);
  }

  /// Checks for sequential patterns (123456, abcdef)
  bool _isSequentialPattern(String password) {
    if (password.length < 4) return false;

    for (int i = 0; i < password.length - 3; i++) {
      final substr = password.substring(i, i + 4);
      if (_isSequential(substr)) return true;
    }

    return false;
  }

  /// Checks if a substring is sequential
  bool _isSequential(String str) {
    for (int i = 1; i < str.length; i++) {
      if (str.codeUnitAt(i) != str.codeUnitAt(i - 1) + 1) return false;
    }
    return true;
  }

  /// Checks for repeating patterns (aaaa, 1111)
  bool _isRepeatingPattern(String password) {
    if (password.length < 4) return false;

    for (int i = 0; i < password.length - 3; i++) {
      final char = password[i];
      if (password.substring(i, i + 4) == char * 4) return true;
    }

    return false;
  }

  // ============================================================================
  // USERNAME VALIDATION
  // ============================================================================

  /// Validates username format and restrictions
  ///
  /// [username] - The username to validate
  ///
  /// Returns [Success] if valid, [Failure] with validation error if invalid
  Result<void> validateUsername(String username) {
    if (username.isEmpty) {
      return const Failure(ValidationException('Username cannot be empty'));
    }

    if (!AppConstants.isValidUsername(username)) {
      return const Failure(
        ValidationException(
          'Username must be 3-20 characters long and contain only '
          'letters, numbers, and underscores',
        ),
      );
    }

    // Check for reserved usernames
    if (_isReservedUsername(username)) {
      return const Failure(
        ValidationException(
          'This username is reserved. Please choose another.',
        ),
      );
    }

    return const Success(null);
  }

  /// Checks if username is reserved
  bool _isReservedUsername(String username) {
    final reservedUsernames = [
      'admin',
      'administrator',
      'root',
      'system',
      'user',
      'api',
      'app',
      'service',
      'bot',
      'test',
      'null',
      'undefined',
      'anonymous',
      'guest',
    ];

    return reservedUsernames.contains(username.toLowerCase());
  }

  // ============================================================================
  // IMAGE VALIDATION
  // ============================================================================

  /// Validates image data for size, format, and integrity
  ///
  /// [imageData] - The image data as bytes
  /// [filename] - Optional filename for format validation
  ///
  /// Returns [Success] if valid, [Failure] with validation error if invalid
  Result<void> validateImageData(Uint8List imageData, {String? filename}) {
    if (imageData.isEmpty) {
      return const Failure(
        ImageValidationException('Image data cannot be empty'),
      );
    }

    // Check file size
    if (imageData.length > AppConstants.maxImageSize) {
      final sizeMB = AppConstants.bytesToMB(imageData.length);
      final maxSizeMB = AppConstants.bytesToMB(AppConstants.maxImageSize);
      return Failure(
        ImageValidationException(
          'Image is too large: ${sizeMB.toStringAsFixed(1)}MB '
          '(max ${maxSizeMB.toStringAsFixed(1)}MB)',
        ),
      );
    }

    // Basic format validation
    if (!_isValidImageFormat(imageData)) {
      return const Failure(
        ImageValidationException('Invalid or unsupported image format'),
      );
    }

    // Filename validation if provided
    if (filename != null) {
      final validationResult = _validateImageFilename(filename);
      if (validationResult.isFailure) {
        return validationResult;
      }
    }

    return const Success(null);
  }

  /// Validates image format based on file headers
  bool _isValidImageFormat(Uint8List data) {
    if (data.length < 8) return false;

    // Check common image format headers
    // JPEG: FF D8 FF
    if (data[0] == 0xFF && data[1] == 0xD8 && data[2] == 0xFF) return true;

    // PNG: 89 50 4E 47 0D 0A 1A 0A
    if (data.length >= 8 &&
        data[0] == 0x89 &&
        data[1] == 0x50 &&
        data[2] == 0x4E &&
        data[3] == 0x47 &&
        data[4] == 0x0D &&
        data[5] == 0x0A &&
        data[6] == 0x1A &&
        data[7] == 0x0A)
      return true;

    // WebP: RIFF...WEBP
    if (data.length >= 12 &&
        data[0] == 0x52 &&
        data[1] == 0x49 &&
        data[2] == 0x46 &&
        data[3] == 0x46 &&
        data[8] == 0x57 &&
        data[9] == 0x45 &&
        data[10] == 0x42 &&
        data[11] == 0x50)
      return true;

    // GIF: GIF87a or GIF89a
    if (data.length >= 6 &&
        data[0] == 0x47 &&
        data[1] == 0x49 &&
        data[2] == 0x46 &&
        data[3] == 0x38 &&
        (data[4] == 0x37 || data[4] == 0x39) &&
        data[5] == 0x61)
      return true;

    return false;
  }

  /// Validates image filename
  Result<void> _validateImageFilename(String filename) {
    if (filename.isEmpty) {
      return const Failure(ValidationException('Filename cannot be empty'));
    }

    final extension = filename.toLowerCase().split('.').last;
    if (!AppConstants.supportedImageFormats.contains(extension)) {
      return Failure(
        ValidationException(
          'Unsupported image format: $extension. '
          'Supported formats: ${AppConstants.supportedImageFormats.join(', ')}',
        ),
      );
    }

    // Check for potentially dangerous characters
    if (filename.contains(RegExp(r'[<>:"/\\|?*]'))) {
      return const Failure(
        ValidationException('Filename contains invalid characters'),
      );
    }

    return const Success(null);
  }

  // ============================================================================
  // TEXT VALIDATION
  // ============================================================================

  /// Validates text input for length and content safety
  ///
  /// [text] - The text to validate
  /// [minLength] - Minimum required length
  /// [maxLength] - Maximum allowed length
  /// [fieldName] - Name of the field for error messages
  ///
  /// Returns [Success] if valid, [Failure] with validation error if invalid
  Result<void> validateText(
    String text, {
    int minLength = 0,
    int maxLength = 1000,
    String fieldName = 'Text',
  }) {
    if (text.isEmpty && minLength > 0) {
      return Failure(ValidationException('$fieldName cannot be empty'));
    }

    if (text.length < minLength) {
      return Failure(
        ValidationException(
          '$fieldName must be at least $minLength characters long',
        ),
      );
    }

    if (text.length > maxLength) {
      return Failure(
        ValidationException('$fieldName cannot exceed $maxLength characters'),
      );
    }

    // Check for potentially harmful content
    if (_containsSuspiciousContent(text)) {
      return Failure(
        ValidationException('$fieldName contains prohibited content'),
      );
    }

    return const Success(null);
  }

  /// Checks for suspicious or harmful content
  bool _containsSuspiciousContent(String text) {
    // Basic patterns to detect potential security threats
    final suspiciousPatterns = [
      RegExp(r'<script', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false),
      RegExp(r'data:text/html', caseSensitive: false),
    ];

    return suspiciousPatterns.any((pattern) => pattern.hasMatch(text));
  }

  // ============================================================================
  // BATCH VALIDATION
  // ============================================================================

  /// Validates multiple inputs at once
  ///
  /// [validations] - Map of field names to validation functions
  ///
  /// Returns [Success] if all valid, [Failure] with first error if any invalid
  Result<void> validateAll(Map<String, Result<void> Function()> validations) {
    for (final entry in validations.entries) {
      final result = entry.value();
      if (result.isFailure) {
        return Failure(
          ValidationException('${entry.key}: ${result.exceptionOrNull}'),
        );
      }
    }

    return const Success(null);
  }
}

/// Custom exception for validation errors
class ValidationException implements Exception {
  const ValidationException(this.message);

  final String message;

  @override
  String toString() => 'ValidationException: $message';
}

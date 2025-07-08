import 'package:revision/core/utils/security_utils.dart';

class Validators {
  // More comprehensive email regex that supports modern email formats
  static const String _emailPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static final RegExp _emailRegExp = RegExp(_emailPattern);

  /// Validates email format
  static String? validateEmail(String email) {
    if (email.isEmpty) return 'Email cannot be empty';

    // Use security utils for more robust validation
    if (!SecurityUtils.isValidEmail(email)) {
      return 'Please enter a valid email';
    }

    return null;
  }

  /// Validates password strength using security utils
  static String? validatePassword(String password) {
    if (password.isEmpty) return 'Password cannot be empty';
    if (password.length < 8) return 'Password must be at least 8 characters';
    
    final strength = SecurityUtils.validatePasswordStrength(password);
    if (strength == PasswordStrength.weak) {
      return 'Password is too weak. Use uppercase, lowercase, numbers, and special characters';
    }
    
    return null;
  }

  /// Validates display name
  static String? validateDisplayName(String? displayName) {
    if (displayName == null || displayName.isEmpty) {
      return 'Display name cannot be empty';
    }
    if (displayName.length < 2) {
      return 'Display name must be at least 2 characters';
    }
    if (displayName.length > 50) {
      return 'Display name cannot exceed 50 characters';
    }
    return null;
  }

  /// Validates phone number format
  static String? validatePhoneNumber(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      return null; // Optional field
    }
    
    // Remove all non-digit characters
    final digits = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digits.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    if (digits.length > 15) {
      return 'Phone number cannot exceed 15 digits';
    }
    
    return null;
  }

  /// Validates age verification
  static String? validateAge(bool isAdult) {
    if (!isAdult) {
      return 'You must be at least 13 years old to use this service';
    }
    return null;
  }

  /// Validates terms acceptance
  static String? validateTermsAcceptance(bool acceptedTerms) {
    if (!acceptedTerms) {
      return 'You must accept the Terms of Service to continue';
    }
    return null;
  }

  /// Validates privacy policy acceptance
  static String? validatePrivacyAcceptance(bool acceptedPrivacy) {
    if (!acceptedPrivacy) {
      return 'You must accept the Privacy Policy to continue';
    }
    return null;
  }
}

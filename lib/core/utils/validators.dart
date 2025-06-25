class Validators {
  // More comprehensive email regex that supports modern email formats
  static const String _emailPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static final RegExp _emailRegExp = RegExp(_emailPattern);

  /// Validates email format
  static String? validateEmail(String email) {
    if (email.isEmpty) return 'Email cannot be empty';

    // Additional validation for edge cases
    if (email.startsWith('.') || email.endsWith('.')) {
      return 'Please enter a valid email';
    }
    if (email.contains('..')) return 'Please enter a valid email';
    if (email.split('@').length != 2) return 'Please enter a valid email';

    final parts = email.split('@');
    final localPart = parts[0];
    final domainPart = parts[1];

    // Local part validation
    if (localPart.isEmpty ||
        localPart.endsWith('.') ||
        localPart.startsWith('.')) {
      return 'Please enter a valid email';
    }

    // Domain part validation
    if (domainPart.isEmpty ||
        domainPart.startsWith('.') ||
        domainPart.endsWith('.')) {
      return 'Please enter a valid email';
    }

    if (!_emailRegExp.hasMatch(email)) return 'Please enter a valid email';
    return null;
  }

  /// Validates password strength
  static String? validatePassword(String password) {
    if (password.isEmpty) return 'Password cannot be empty';
    if (password.length < 6) return 'Password must be at least 6 characters';
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
}

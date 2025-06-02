class Validators {
  static const String _emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static final RegExp _emailRegExp = RegExp(_emailPattern);

  /// Validates email format
  static String? validateEmail(String email) {
    if (email.isEmpty) return 'Email cannot be empty';
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

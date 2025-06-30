import 'environment_detector.dart';

/// Environment configuration for Firebase AI Logic and other settings.
///
/// This class retrieves configuration from environment variables
/// passed during the build process and supports runtime environment detection.
///
/// Note: API keys are managed by Firebase AI Logic, not in environment variables.
class EnvConfig {
  /// Firebase AI Logic is always configured when Firebase is properly initialized.
  /// API keys are managed internally by Firebase.
  static bool get isFirebaseAIConfigured => true;

  /// Get the current environment
  static AppEnvironment get currentEnvironment =>
      EnvironmentDetector.currentEnvironment;

  /// Get environment as string
  static String get environmentString => EnvironmentDetector.environmentString;

  /// Check if current environment is development
  static bool get isDevelopment => EnvironmentDetector.isDevelopment;

  /// Check if current environment is staging
  static bool get isStaging => EnvironmentDetector.isStaging;

  /// Check if current environment is production
  static bool get isProduction => EnvironmentDetector.isProduction;

  /// Get comprehensive debug information
  static Map<String, dynamic> getDebugInfo() {
    return {
      'firebaseAIConfigured': isFirebaseAIConfigured,
      'environment': environmentString,
      ...EnvironmentDetector.getDebugInfo(),
    };
  }
}

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'environment_detector.dart';

/// Environment configuration for Firebase AI Logic and other settings.
///
/// This class retrieves configuration from environment variables
/// passed during the build process and supports runtime environment detection.
///
/// Note: Firebase AI Logic manages API keys internally, but direct Gemini REST API
/// calls (required for image input) need an explicit API key from environment.
class EnvConfig {
  /// Firebase AI Logic is always configured when Firebase is properly initialized.
  /// API keys are managed internally by Firebase.
  static bool get isFirebaseAIConfigured => true;

  /// Get Gemini API key for direct REST API calls (required for image operations)
  /// Since Firebase AI Logic doesn't support image input, we need direct API access
  static String? get geminiApiKey => dotenv.env['GEMINI_API_KEY'];

  /// Check if Gemini API key is configured for direct REST calls
  static bool get isGeminiRestApiConfigured => geminiApiKey?.isNotEmpty == true;

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
      'geminiRestApiConfigured': isGeminiRestApiConfigured,
      'environment': environmentString,
      ...EnvironmentDetector.getDebugInfo(),
    };
  }
}

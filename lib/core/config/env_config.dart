import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'environment_detector.dart';

/// Environment configuration for API keys and other secrets.
///
/// This class retrieves configuration from environment variables
/// passed during the build process and supports runtime environment detection.
class EnvConfig {
  /// The API key for Gemini, retrieved from .env file or --dart-define flag.
  static String get geminiApiKey {
    // First try to get from dotenv (loaded from .env file)
    final fromDotenv = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (fromDotenv.isNotEmpty) {
      return fromDotenv;
    }
    
    // Fallback to compile-time environment variable
    return const String.fromEnvironment(
      'GEMINI_API_KEY',
      defaultValue: '',
    );
  }

  /// A flag to check if the Gemini API key has been configured.
  static bool get isConfigured => geminiApiKey.isNotEmpty;

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
      'geminiApiKeyConfigured': isConfigured,
      'geminiApiKeyLength': geminiApiKey.length,
      'environment': environmentString,
      ...EnvironmentDetector.getDebugInfo(),
    };
  }
}

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
  static String? get geminiApiKey {
    try {
      // Determine the key based on the environment
      String keyName;
      if (isDevelopment) {
        keyName = 'GEMINI_API_KEY_DEV';
      } else if (isStaging) {
        keyName = 'GEMINI_API_KEY_STAGING';
      } else if (isProduction) {
        keyName = 'GEMINI_API_KEY_PROD';
      } else {
        keyName = 'GEMINI_API_KEY'; // Fallback for unknown environments
      }

      // First, try to get the environment-specific key from dotenv
      String? apiKey = dotenv.env[keyName];

      // If not found, fall back to the generic key for backward compatibility
      if (apiKey == null || apiKey.isEmpty) {
        apiKey = dotenv.env['GEMINI_API_KEY'];
      }

      // If still not found, try dart-define as a last resort
      if (apiKey == null || apiKey.isEmpty) {
        const fallback = String.fromEnvironment('GEMINI_API_KEY');
        return fallback.isNotEmpty ? fallback : null;
      }

      return apiKey;
    } catch (e) {
      // If dotenv is not initialized, try dart-define fallback
      const fallback = String.fromEnvironment('GEMINI_API_KEY');
      return fallback.isNotEmpty ? fallback : null;
    }
  }

  /// Check if Gemini API key is configured for direct REST calls
  static bool get isGeminiRestApiConfigured {
    try {
      final apiKey = geminiApiKey;
      return apiKey?.isNotEmpty == true;
    } catch (e) {
      return false;
    }
  }

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
      'geminiApiKeyPresent': geminiApiKey != null,
      'geminiApiKeyLength': geminiApiKey?.length ?? 0,
      ...EnvironmentDetector.getDebugInfo(),
    };
  }
}

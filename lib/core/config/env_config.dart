/// Environment configuration for API keys and other secrets.
///
/// This class retrieves the Gemini API key from the environment variables
/// passed during the build process.
class EnvConfig {
  /// The API key for Gemini, retrieved from the `--dart-define` flag.
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// A flag to check if the Gemini API key has been configured.
  static bool get isConfigured => geminiApiKey.isNotEmpty;
}

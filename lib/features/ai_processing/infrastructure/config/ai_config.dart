/// Configuration for AI services
abstract class AiConfig {
  // Vertex AI endpoints
  static const String analysisEndpoint = 'vertex-ai-analysis';
  static const String editEndpoint = 'vertex-ai-editing';

  // Request timeouts
  static const Duration analysisTimeout = Duration(seconds: 30);
  static const Duration editingTimeout = Duration(seconds: 60);

  // Model configurations
  static const String analysisModel = 'gemini-1.5-flash';
  static const String editingModel = 'imagen-3.0';

  // Image constraints
  static const int maxImageSizeBytes = 10 * 1024 * 1024; // 10MB
  static const List<String> supportedFormats = ['jpg', 'jpeg', 'png'];

  // Retry configuration
  static const int maxRetries = 2;
  static const Duration retryDelay = Duration(seconds: 2);
}

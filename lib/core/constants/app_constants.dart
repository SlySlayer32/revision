/// Global application constants following VGV architecture patterns
class AppConstants {
  const AppConstants._();

  // App Information
  static const String appName = 'Revision';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'AI-Powered Photo Editor';

  // Firebase Project Configuration
  static const String firebaseProjectId = 'revision-ai-editor';

  // Environment-specific configurations
  static const String developmentSuffix = '-dev';
  static const String stagingSuffix = '-staging';
  static const String productionSuffix = '';

  // AI Processing Constants
  static const String vertexAiModel = 'gemini-1.5-flash';
  static const int maxImageSize = 4 * 1024 * 1024; // 4MB
  static const int aiRequestTimeout = 30000; // 30 seconds
  static const int maxRetryAttempts = 3;

  // Image Processing Constants
  static const List<String> supportedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'webp',
    'tiff',
    'raw',
    'dng',
  ];

  // Circuit Breaker Constants
  static const int circuitBreakerFailureThreshold = 5;
  static const Duration circuitBreakerTimeout = Duration(minutes: 1);
  static const Duration circuitBreakerResetTimeout = Duration(minutes: 5);

  // Error Handling
  static const String genericErrorMessage =
      'Something went wrong. Please try again.';
  static const String networkErrorMessage =
      'Network error. Please check your connection.';
  static const String aiServiceErrorMessage =
      'AI service is temporarily unavailable.';

  // Feature Flags
  static const bool enableAdvancedEditing = true;
  static const bool enableBatchProcessing = false;
  static const bool enableCloudSync = true;
}

/// Global application constants following VGV architecture patterns
/// 
/// This class centralizes all magic numbers, timeouts, and configuration values
/// to improve maintainability and prevent scattered hardcoded values.
class AppConstants {
  const AppConstants._();

  // ============================================================================
  // APP INFORMATION
  // ============================================================================
  
  static const String appName = 'Revision';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'AI-Powered Photo Editor';

  // ============================================================================
  // FIREBASE PROJECT CONFIGURATION
  // ============================================================================
  
  static const String firebaseProjectId = 'revision-ai-editor';
  static const String developmentSuffix = '-dev';
  static const String stagingSuffix = '-staging';
  static const String productionSuffix = '';

  // ============================================================================
  // AI PROCESSING CONSTANTS
  // ============================================================================
  
  /// Gemini model for AI processing
  static const String geminiModel = 'gemini-2.5-flash';
  
  /// Maximum image size for AI processing (4MB)
  static const int maxImageSize = 4 * 1024 * 1024;
  
  /// AI request timeout in milliseconds
  static const int aiRequestTimeout = 30000; // 30 seconds
  
  /// Maximum retry attempts for AI operations
  static const int maxRetryAttempts = 3;
  
  /// AI processing cooldown period in milliseconds
  static const int aiCooldownMs = 5000; // 5 seconds
  
  /// Maximum concurrent AI operations
  static const int maxConcurrentAIOperations = 2;

  // ============================================================================
  // IMAGE PROCESSING CONSTANTS
  // ============================================================================
  
  /// Supported image formats
  static const List<String> supportedImageFormats = [
    'jpg', 'jpeg', 'png', 'webp', 'tiff', 'raw', 'dng',
  ];

  /// Maximum image dimensions
  static const int maxImageWidth = 4096;
  static const int maxImageHeight = 4096;
  static const int maxImageResolution = maxImageWidth * maxImageHeight;

  /// Image quality and compression settings
  static const int jpegQuality = 85;
  static const int pngCompressionLevel = 6;
  static const int defaultImageQuality = 85;
  
  /// Marked areas constraints
  static const int maxMarkedAreasPerImage = 10;
  static const double minMarkedAreaSizePercent = 0.01; // 1%
  static const double maxMarkedAreaSizePercent = 0.9; // 90%

  // ============================================================================
  // AUTHENTICATION CONSTANTS
  // ============================================================================
  
  /// Authentication timeout in milliseconds
  static const int authTimeoutMs = 30000; // 30 seconds
  
  /// Maximum authentication retry attempts
  static const int maxAuthRetryAttempts = 3;
  
  /// Password minimum length requirement
  static const int minPasswordLength = 8;
  
  /// Session timeout in minutes
  static const int sessionTimeoutMinutes = 30;
  
  /// Maximum failed login attempts before lockout
  static const int maxFailedLoginAttempts = 5;
  
  /// Account lockout duration in minutes
  static const int accountLockoutMinutes = 15;

  // ============================================================================
  // NETWORK CONSTANTS
  // ============================================================================
  
  /// Connection timeout in milliseconds
  static const int connectionTimeout = 30000; // 30 seconds
  
  /// Data receive timeout in milliseconds
  static const int receiveTimeout = 60000; // 60 seconds
  
  /// Maximum network retry attempts
  static const int maxNetworkRetryAttempts = 3;
  
  /// Network retry delay base in milliseconds
  static const int networkRetryDelayMs = 1000;

  // ============================================================================
  // CACHE AND STORAGE CONSTANTS
  // ============================================================================
  
  /// Maximum cache size (100MB)
  static const int maxCacheSize = 100 * 1024 * 1024;
  
  /// Maximum number of cached items
  static const int maxCacheItems = 50;
  
  /// Cache expiration time in hours
  static const int cacheExpirationHours = 24;
  
  /// Maximum number of cached images
  static const int maxCachedImages = 50;

  // Animation and UI Constants
  static const int defaultAnimationDuration = 300; // 300ms
  static const int debounceDuration = 500; // 500ms

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

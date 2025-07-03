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

  // ============================================================================
  // UI AND ANIMATION CONSTANTS
  // ============================================================================
  
  /// Default animation duration in milliseconds
  static const int defaultAnimationDuration = 300;
  
  /// Debounce duration in milliseconds
  static const int debounceDuration = 500;
  
  /// Loading indicator minimum display time in milliseconds
  static const int minLoadingDisplayMs = 500;
  
  /// Snackbar display duration in milliseconds
  static const int snackbarDurationMs = 4000;
  
  /// Page transition duration in milliseconds
  static const int pageTransitionMs = 250;

  // ============================================================================
  // PERFORMANCE CONSTANTS
  // ============================================================================
  
  /// Target frame rate (FPS)
  static const int targetFrameRate = 60;
  
  /// Memory warning threshold in MB
  static const int memoryWarningThresholdMB = 150;
  
  /// Maximum memory usage in MB
  static const int maxMemoryUsageMB = 200;
  
  /// Performance monitoring sample rate (0.0 to 1.0)
  static const double performanceSampleRate = 0.1;

  // ============================================================================
  // CIRCUIT BREAKER CONSTANTS
  // ============================================================================
  
  /// Circuit breaker failure threshold
  static const int circuitBreakerFailureThreshold = 5;
  
  /// Circuit breaker timeout duration
  static const Duration circuitBreakerTimeout = Duration(minutes: 1);
  
  /// Circuit breaker reset timeout duration
  static const Duration circuitBreakerResetTimeout = Duration(minutes: 5);

  // ============================================================================
  // ERROR HANDLING
  // ============================================================================
  
  /// Generic error message
  static const String genericErrorMessage =
      'Something went wrong. Please try again.';
      
  /// Network error message
  static const String networkErrorMessage =
      'Network error. Please check your connection.';
      
  /// AI service error message
  static const String aiServiceErrorMessage =
      'AI service is temporarily unavailable.';
  
  /// Maximum error context data size in characters
  static const int maxErrorContextSize = 1000;
  
  /// Error retry exponential backoff multiplier
  static const double retryBackoffMultiplier = 2.0;
  
  /// Maximum retry delay in seconds
  static const int maxRetryDelaySeconds = 60;

  // ============================================================================
  // FEATURE FLAGS
  // ============================================================================
  
  /// Enable advanced editing features
  static const bool enableAdvancedEditing = true;
  
  /// Enable batch processing features
  static const bool enableBatchProcessing = false;
  
  /// Enable cloud synchronization
  static const bool enableCloudSync = true;
  
  /// Enable analytics collection
  static const bool enableAnalytics = true;
  
  /// Enable crash reporting
  static const bool enableCrashReporting = true;
  
  /// Enable performance monitoring
  static const bool enablePerformanceMonitoring = true;

  // ============================================================================
  // VALIDATION PATTERNS
  // ============================================================================
  
  /// Email validation regex pattern
  static const String emailPattern = 
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  
  /// Password strength regex (at least 8 chars, 1 upper, 1 lower, 1 number)
  static const String passwordPattern = 
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$';
  
  /// Username validation regex (alphanumeric and underscore, 3-20 chars)
  static const String usernamePattern = r'^[a-zA-Z0-9_]{3,20}$';

  // ============================================================================
  // API RATE LIMITING
  // ============================================================================
  
  /// Gemini API requests per minute limit
  static const int geminiRateLimit = 60;
  
  /// Firebase Auth requests per minute limit
  static const int authRateLimit = 100;
  
  /// Storage upload requests per minute limit
  static const int storageRateLimit = 30;
  
  /// Rate limit window duration in minutes
  static const int rateLimitWindowMinutes = 1;

  // ============================================================================
  // LOGGING CONSTANTS
  // ============================================================================
  
  /// Maximum log file size in MB
  static const int maxLogFileSizeMB = 10;
  
  /// Log retention period in days
  static const int logRetentionDays = 7;
  
  /// Maximum number of log files to keep
  static const int maxLogFiles = 5;

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================
  
  /// Converts bytes to megabytes
  static double bytesToMB(int bytes) => bytes / (1024 * 1024);
  
  /// Converts megabytes to bytes
  static int mbToBytes(double mb) => (mb * 1024 * 1024).round();
  
  /// Gets timeout duration for operation type
  static Duration getTimeoutDuration(String operationType) {
    switch (operationType.toLowerCase()) {
      case 'auth':
        return const Duration(milliseconds: authTimeoutMs);
      case 'ai':
        return const Duration(milliseconds: aiRequestTimeout);
      case 'network':
        return const Duration(milliseconds: connectionTimeout);
      default:
        return const Duration(milliseconds: connectionTimeout);
    }
  }
  
  /// Gets retry attempts for operation type
  static int getRetryAttempts(String operationType) {
    switch (operationType.toLowerCase()) {
      case 'auth':
        return maxAuthRetryAttempts;
      case 'ai':
        return maxRetryAttempts;
      case 'network':
        return maxNetworkRetryAttempts;
      default:
        return maxNetworkRetryAttempts;
    }
  }
  
  /// Validates email format
  static bool isValidEmail(String email) {
    return RegExp(emailPattern).hasMatch(email);
  }
  
  /// Validates password strength
  static bool isStrongPassword(String password) {
    return password.length >= minPasswordLength && 
           RegExp(passwordPattern).hasMatch(password);
  }
  
  /// Validates username format
  static bool isValidUsername(String username) {
    return RegExp(usernamePattern).hasMatch(username);
  }
}

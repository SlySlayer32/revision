import 'package:revision/core/constants/environment_config.dart';

/// Firebase-specific constants and configuration following VGV patterns
class FirebaseConstants {
  const FirebaseConstants._();

  // Firebase Project ID (Environment-specific based on user feedback)
  static String get projectId {
    switch (Environment.current) {
      case Environment.development:
        return 'com.sly.revision.dev';
      case Environment.staging:
        return 'com.sly.revision.stg';
      case Environment.production:
        return 'com.sly.revision';
    }
  }

  // Firebase Auth Configuration
  static const String authDomain = 'revision-fc66c.firebaseapp.com';
  static const bool useAuthEmulator =
      true; // Always use emulator in development
  static const String authEmulatorHost = 'localhost';
  static const int authEmulatorPort = 9098;

  // Firestore Configuration
  static const String firestoreDatabase = '(default)';
  static const bool useFirestoreEmulator =
      bool.fromEnvironment('USE_FIRESTORE_EMULATOR');
  static const String firestoreEmulatorHost = 'localhost';
  static const int firestoreEmulatorPort = 8080;

  // Firebase Storage Configuration
  static const String storageBucket = 'revision-fc66c.appspot.com';
  static const bool useStorageEmulator =
      bool.fromEnvironment('USE_STORAGE_EMULATOR');
  static const String storageEmulatorHost = 'localhost';
  static const int storageEmulatorPort = 9199;

  // Vertex AI Configuration
  static const String vertexAiLocation = 'us-central1'; // Matches prompt

  // Updated model names for latest Gemini and Imagen models
  static const String geminiModel = 'gemini-2.0-flash-exp'; // Matches prompt
  static const String imagenModel = 'imagen-3.0-generate-001'; // Matches prompt
  static const String defaultModel = 'gemini-1.5-flash'; // Existing, keep

  static const Map<String, String> availableModels = {
    // Existing, keep
    'gemini-1.5-flash': 'Fast general-purpose model',
    'gemini-1.5-pro': 'High-quality model for complex tasks',
    'gemini-2.0-flash-exp': 'Latest experimental flash model',
    'imagen-3.0-generate-001': 'Advanced image generation model',
  };

  // AI Processing Timeouts and Limits (Matches prompt)
  static const Duration aiRequestTimeout = Duration(seconds: 60);
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Image Processing Limits
  static const int maxImageSize = 4096; // 4K max resolution
  static const int maxFileSizeMB = 10;
  static const List<String> supportedFormats = ['jpg', 'jpeg', 'png', 'heic'];

  // Concurrent Request Limits
  static const int maxConcurrentRequests = 3;
  static const Duration requestQueueTimeout = Duration(minutes: 5);

  // Firebase Functions Configuration
  static const String functionsRegion = 'us-central1';
  static const bool useFunctionsEmulator =
      bool.fromEnvironment('USE_FUNCTIONS_EMULATOR');
  static const String functionsEmulatorHost = 'localhost';
  static const int functionsEmulatorPort = 5001;

  // Security Rules
  static const Duration tokenRefreshInterval = Duration(minutes: 55);
  static const Duration sessionTimeout = Duration(hours: 24);

  // Error Codes
  static const String networkErrorCode = 'network-request-failed';
  static const String authErrorCode = 'user-not-found';
  static const String permissionErrorCode = 'permission-denied';
  static const String quotaExceededCode = 'quota-exceeded';
  static const String rateLimitErrorCode = 'rate-limit-exceeded';
  static const String modelOverloadedCode = 'model-overloaded';
}

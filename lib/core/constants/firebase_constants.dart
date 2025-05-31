/// Firebase-specific constants and configuration following VGV patterns
class FirebaseConstants {
  const FirebaseConstants._();

  // Firebase App Names (Environment-specific)
  static const String developmentAppName = 'revision-development';
  static const String stagingAppName = 'revision-staging';
  static const String productionAppName = 'revision-production';

  // Firebase Auth Configuration
  static const String authDomain = 'revision-ai-editor.firebaseapp.com';
  static const bool useAuthEmulator = bool.fromEnvironment('USE_AUTH_EMULATOR');
  static const String authEmulatorHost = 'localhost';
  static const int authEmulatorPort = 9099;

  // Firestore Configuration
  static const String firestoreDatabase = '(default)';
  static const bool useFirestoreEmulator =
      bool.fromEnvironment('USE_FIRESTORE_EMULATOR');
  static const String firestoreEmulatorHost = 'localhost';
  static const int firestoreEmulatorPort = 8080;

  // Firebase Storage Configuration
  static const String storageBucket = 'revision-ai-editor.appspot.com';
  static const bool useStorageEmulator =
      bool.fromEnvironment('USE_STORAGE_EMULATOR');
  static const String storageEmulatorHost = 'localhost';
  static const int storageEmulatorPort = 9199;

  // Vertex AI Configuration
  static const String vertexAiLocation = 'us-central1';
  static const String defaultModel = 'gemini-1.5-flash';
  static const Map<String, String> availableModels = {
    'gemini-1.5-flash': 'Fast general-purpose model',
    'gemini-1.5-pro': 'High-quality model for complex tasks',
    'gemini-1.0-pro-vision': 'Vision-specific model',
  };

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
}

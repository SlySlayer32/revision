import 'package:revision/core/constants/firebase_constants.dart';

/// Environment-specific configuration following VGV architecture patterns
enum Environment {
  development,
  staging,
  production;

  /// Get the current environment based on build configuration
  static Environment get current {
    const env =
        String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
    switch (env.toLowerCase()) {
      case 'production':
        return Environment.production;
      case 'staging':
        return Environment.staging;
      case 'development':
      default:
        return Environment.development;
    }
  }

  /// Get Firebase app name for current environment
  String get firebaseAppName {
    // Use the bundle ID for environment-specific naming if needed
    return FirebaseConstants.projectId;
  }

  /// Check if emulators should be used
  bool get useEmulators {
    switch (this) {
      case Environment.development:
        return true;
      case Environment.staging:
      case Environment.production:
        return false;
    }
  }

  /// Get environment-specific API endpoints
  String get baseUrl {
    switch (this) {
      case Environment.development:
        return 'http://localhost:5001/revision-ai-editor/us-central1';
      case Environment.staging:
        return 'https://us-central1-revision-ai-editor-staging.cloudfunctions.net';
      case Environment.production:
        return 'https://us-central1-revision-ai-editor.cloudfunctions.net';
    }
  }

  /// Get Firebase Functions URL for environment (alias for baseUrl for test compatibility)
  String get firebaseFunctionsUrl => baseUrl;

  /// Get debug mode flag
  bool get isDebugMode {
    switch (this) {
      case Environment.development:
        return true;
      case Environment.staging:
      case Environment.production:
        return false;
    }
  }

  /// Get analytics enablement
  bool get enableAnalytics {
    switch (this) {
      case Environment.development:
        return false;
      case Environment.staging:
      case Environment.production:
        return true;
    }
  }
}

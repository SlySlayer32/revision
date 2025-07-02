import 'package:revision/core/config/env_config.dart';

/// Configuration for analysis service endpoints and settings
abstract class AnalysisServiceConfig {
  /// Base URL for Vertex AI services
  static const String baseUrl = 'https://vertex-ai.googleapis.com/v1';
  
  /// Analysis endpoint template with placeholders
  static const String analysisEndpoint = 'projects/{project}/locations/{location}/models/{model}:predict';
  
  /// Request timeout duration
  static const Duration requestTimeout = Duration(minutes: 2);
  
  /// Maximum number of retry attempts
  static const int maxRetries = 3;
  
  /// Delay between retry attempts
  static const Duration retryDelay = Duration(seconds: 2);
  
  /// Default project ID from environment
  static String get projectId => EnvConfig.firebaseProjectId ?? 'revision-464202';
  
  /// Default location for AI services
  static const String location = 'us-central1';
  
  /// Analysis model identifier
  static const String analysisModel = 'gemini-1.5-flash-002';
  
  /// Constructs the full analysis endpoint URL
  static String get fullEndpoint {
    return '$baseUrl/$analysisEndpoint'
        .replaceAll('{project}', projectId)
        .replaceAll('{location}', location)
        .replaceAll('{model}', analysisModel);
  }
  
  /// Authorization headers template
  static Map<String, String> getAuthHeaders(String accessToken) {
    return {
      'Authorization': 'Bearer $accessToken',
      'X-Goog-User-Project': projectId,
      'Content-Type': 'application/json',
    };
  }
}

import 'package:revision/core/di/service_locator.dart';
import 'package:revision/core/services/firebase_ai_remote_config_service.dart';

/// Configuration for AI services, managed by Firebase Remote Config
class AIConfig {
  /// Access to the Firebase Remote Config service
  static final remoteConfig = getIt<FirebaseAIRemoteConfigService>();

  /// Get the Gemini model for text analysis
  static String get geminiModel => remoteConfig.geminiModel;

  /// Get the Gemini model for image generation
  static String get geminiImageModel => remoteConfig.geminiImageModel;

  /// Get the system prompt for the analysis model
  static String get analysisSystemPrompt => remoteConfig.analysisSystemPrompt;

  /// Get the user prompt template
  static String get userPromptTemplate => remoteConfig.userPromptTemplate;

  /// Get the model temperature
  static double get temperature => remoteConfig.temperature;

  /// Get the maximum output tokens
  static int get maxOutputTokens => remoteConfig.maxOutputTokens;

  /// Get the top-K value
  static int get topK => remoteConfig.topK;

  /// Get the top-P value
  static double get topP => remoteConfig.topP;

  /// Get the request timeout duration
  static Duration get requestTimeout => remoteConfig.requestTimeout;

  /// Check if advanced features are enabled
  static bool get enableAdvancedFeatures => remoteConfig.enableAdvancedFeatures;
}

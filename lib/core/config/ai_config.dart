import 'dart:developer';

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration for AI services including API keys and rate limits
class AIConfig {
  /// Firebase AI configuration
  static const String geminiModel = 'gemini-2.5-flash';
  static const String geminiImageModel = 'gemini-2.0-flash-preview-image-generation';

  /// API Keys (loaded from environment)
  static String get apiKey => _getConfigValue('FIREBASE_AI_API_KEY');
  static String get projectId => _getConfigValue('GOOGLE_CLOUD_PROJECT_ID');

  /// Helper method to get config values
  static String _getConfigValue(String key) {
    final value = dotenv.env[key];
    if (value == null) {
      log('⚠️ Missing environment variable: $key');
      throw Exception('Missing required environment variable: $key');
    }
    return value;
  }

  /// Model configuration
  static const double temperature = 0.7;
  static const int maxOutputTokens = 2048;
  static const int topK = 32;
  static const double topP = 1.0;

  /// Rate limiting configuration
  static const int maxRequestsPerMinute = 60;
  static const int maxRequestsPerHour = 1000;

  /// Timeouts and retries
  static const Duration requestTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  /// Image processing limits
  static const int maxImageSizeMB = 20;
  static const int maxImagesPerRequest = 5;

  /// System prompts
  static const String analysisSystemPrompt = '''
You are an AI assistant specialized in analyzing and editing photos.
Focus on identifying objects, lighting conditions, and potential edits.
Provide clear, actionable recommendations for improvements.
''';

  static const String editingSystemPrompt = '''
You are a photo editing AI assistant.
Provide precise, step-by-step instructions for image edits.
Focus on achieving natural-looking results.
''';
}

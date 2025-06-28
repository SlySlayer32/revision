import 'dart:developer';

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration for AI services including API keys and rate limits
class AIConfig {
  /// Firebase AI configuration - Updated to match AI pipeline flow
  static const String geminiModel = 'gemini-2.0-flash'; // Step 3: Analyze marked area & generate removal prompt
  static const String geminiImageModel = 'gemini-2.0-flash-preview-image-generation'; // Step 5: Generate new image using prompt

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

  /// System prompts matching the AI pipeline flow
  static const String analysisSystemPrompt = '''
You are an AI specialized in analyzing marked objects in images for removal.
The user has marked specific objects that they want removed from their photo.

Your task:
1. Analyze the marked areas and identify what objects need to be removed
2. Examine the background behind/around the marked objects
3. Generate a precise removal prompt for the next AI model
4. Focus on content-aware reconstruction and seamless blending

Provide a detailed prompt that will guide the next AI model to:
- Remove the marked objects completely
- Fill the space with realistic background reconstruction
- Maintain lighting consistency and natural appearance
- Preserve image quality and composition

Keep the prompt technical and specific for optimal removal results.''';

  static const String editingSystemPrompt = '''
You are Gemini 2.0 Flash Preview Image Generation AI.
You will receive an image and a removal prompt from the analysis stage.

Your task:
1. Generate a new version of the image with the specified objects removed
2. Use content-aware reconstruction to fill removed areas naturally
3. Maintain consistent lighting, shadows, and color harmony
4. Preserve the original composition and visual quality
5. Ensure seamless integration of reconstructed areas

Generate the edited image directly with the requested removals applied.''';
}

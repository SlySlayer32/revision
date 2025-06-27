import 'dart:developer';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:revision/core/config/env_config.dart';
import 'package:revision/core/constants/firebase_ai_constants.dart';
import 'package:revision/core/services/ai_service.dart';

/// Google AI (Gemini API) service implementation
/// Uses Google AI Studio API with Firebase AI SDK
///
/// Configuration:
/// - API key is managed through Firebase Console (not in code)
/// - Uses Gemini Developer API (not Vertex AI)
/// - Requires Firebase project setup with AI Logic enabled
class GeminiAIService implements AIService {
  GeminiAIService() {
    _initializeModels();
  }

  late final GenerativeModel _geminiModel;
  late final GenerativeModel _geminiImageModel;

  void _initializeModels() {
    try {
      log('🚀 Initializing Firebase AI Logic models...');

      // Initialize Firebase AI with Google AI backend (AI Studio)
      // API key is configured in Firebase Console, not passed here
      final firebaseAI = FirebaseAI.googleAI();

      // Initialize Gemini model for text and analysis
      _geminiModel = firebaseAI.generativeModel(
        model: FirebaseAIConstants.geminiModel, // 'gemini-2.5-flash'
        generationConfig: GenerationConfig(
          temperature: FirebaseAIConstants.temperature,
          maxOutputTokens: FirebaseAIConstants.maxOutputTokens,
          topK: FirebaseAIConstants.topK,
          topP: FirebaseAIConstants.topP,
        ),
        systemInstruction:
            Content.text(FirebaseAIConstants.analysisSystemPrompt),
      );

      // Initialize Gemini model for image processing
      _geminiImageModel = firebaseAI.generativeModel(
        model: FirebaseAIConstants
            .geminiImageModel, // Can use same model for images
        generationConfig: GenerationConfig(
          temperature: 0.3, // Lower temperature for more controlled responses
          maxOutputTokens: 2048,
          topK: 32,
          topP: 0.9,
        ),
        systemInstruction:
            Content.text(FirebaseAIConstants.editingSystemPrompt),
      );

      log('✅ Google AI (Gemini API) models initialized successfully');
      log('🔑 API key source: Firebase Console configuration');
    } catch (e, stackTrace) {
      log('❌ Failed to initialize Google AI models: $e',
          stackTrace: stackTrace);
      log('💡 Common issues:');
      log('   - Firebase project not set up with AI Logic');
      log('   - Gemini API not enabled in Firebase Console');
      log('   - API key not configured in Firebase Console');
      log('   - Firebase not initialized properly');
      rethrow;
    }
  }

  /// Process text prompt using Google AI
  Future<String> processTextPrompt(String prompt) async {
    try {
      final content = [Content.text(prompt)];

      final response = await _geminiModel
          .generateContent(content)
          .timeout(FirebaseAIConstants.requestTimeout);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response from Google AI');
      }

      log('✅ Google AI processTextPrompt completed successfully');
      return response.text!;
    } catch (e, stackTrace) {
      log('❌ Google AI processTextPrompt failed: $e', stackTrace: stackTrace);

      // Return fallback response for MVP
      return 'Sorry, I encountered an error processing your request. Please try again.';
    }
  }

  @override
  Future<String> processImagePrompt(Uint8List imageData, String prompt) async {
    try {
      // Validate image size using updated constants
      if (imageData.length > FirebaseAIConstants.maxImageSizeMB * 1024 * 1024) {
        throw Exception(
          'Image too large: ${imageData.length ~/ (1024 * 1024)}MB',
        );
      }

      // Create content with image and text using Google AI
      final content = [
        Content.multi([
          InlineDataPart('image/jpeg', imageData),
          TextPart('''
Analyze this image and provide editing instructions based on: $prompt

Focus on:
1. Object identification and removal suggestions
2. Background reconstruction techniques
3. Lighting and shadow adjustments
4. Color harmony maintenance

Provide clear, actionable editing steps.
'''),
        ]),
      ];

      final response = await _geminiImageModel
          .generateContent(content)
          .timeout(FirebaseAIConstants.requestTimeout);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response from Google AI');
      }

      log('✅ Google AI processImagePrompt completed successfully');
      return response.text!;
    } catch (e, stackTrace) {
      log('❌ Google AI processImagePrompt failed: $e', stackTrace: stackTrace);

      // Return fallback response for MVP
      return '''
I apologize, but I'm currently unable to analyze this image due to a technical issue.

For object removal, I generally recommend:
1. Identify the object boundaries carefully
2. Consider the background pattern for reconstruction
3. Use content-aware tools for seamless blending
4. Adjust lighting and shadows to match surroundings

Please try again or contact support if the issue persists.
''';
    }
  }

  @override
  Future<String> generateImageDescription(Uint8List imageData) async {
    try {
      final content = [
        Content.multi([
          InlineDataPart('image/jpeg', imageData),
          TextPart('''
Describe this image in detail for photo editing purposes.

Include:
1. Main subjects and objects
2. Lighting conditions
3. Colors and composition
4. Background elements
5. Overall mood and style

Keep the description clear and technical.
'''),
        ]),
      ];

      final response = await _geminiImageModel
          .generateContent(content)
          .timeout(FirebaseAIConstants.requestTimeout);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response from Google AI');
      }

      log('✅ Google AI generateImageDescription completed successfully');
      return response.text!;
    } catch (e, stackTrace) {
      log('❌ Google AI generateImageDescription failed: $e',
          stackTrace: stackTrace);
      return 'Unable to analyze image at this time.';
    }
  }

  @override
  Future<List<String>> suggestImageEdits(Uint8List imageData) async {
    try {
      final content = [
        Content.multi([
          InlineDataPart('image/jpeg', imageData),
          TextPart('''
Analyze this image and provide 5 specific editing suggestions to improve it.

Focus on:
1. Object removal opportunities
2. Lighting improvements
3. Composition enhancements
4. Color corrections
5. Background improvements

Provide each suggestion as a clear, actionable sentence.
'''),
        ]),
      ];

      final response = await _geminiImageModel
          .generateContent(content)
          .timeout(FirebaseAIConstants.requestTimeout);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response from Google AI');
      }

      // Parse response into suggestions
      final suggestions = response.text!
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .map((line) => line.replaceAll(RegExp(r'^\d+\.?\s*'), '').trim())
          .where((suggestion) => suggestion.isNotEmpty)
          .take(5)
          .toList();

      log('✅ Google AI suggestImageEdits completed successfully');
      return suggestions.isNotEmpty ? suggestions : _getFallbackSuggestions();
    } catch (e, stackTrace) {
      log('❌ Google AI suggestImageEdits failed: $e', stackTrace: stackTrace);
      return _getFallbackSuggestions();
    }
  }

  @override
  Future<bool> checkContentSafety(Uint8List imageData) async {
    try {
      final content = [
        Content.multi([
          InlineDataPart('image/jpeg', imageData),
          TextPart('''
Analyze this image for content safety. Is this image appropriate for a photo editing application?

Consider:
1. Does it contain inappropriate content?
2. Is it suitable for general audiences?
3. Does it violate content policies?

Respond with "SAFE" if appropriate, "UNSAFE" if not appropriate, followed by a brief reason.
'''),
        ]),
      ];

      final response = await _geminiImageModel
          .generateContent(content)
          .timeout(FirebaseAIConstants.requestTimeout);

      if (response.text == null || response.text!.isEmpty) {
        // Default to safe if we can't analyze
        return true;
      }

      final responseText = response.text!.toUpperCase();
      log('✅ Google AI checkContentSafety completed successfully');
      return responseText.contains('SAFE') && !responseText.contains('UNSAFE');
    } catch (e, stackTrace) {
      log('❌ Google AI checkContentSafety failed: $e', stackTrace: stackTrace);
      // Default to safe on error
      return true;
    }
  }

  @override
  Future<String> generateEditingPrompt({
    required Uint8List imageBytes,
    required List<Map<String, dynamic>> markers,
  }) async {
    try {
      final markerDescriptions = markers
          .map((marker) =>
              'Marker at (${marker['x']}, ${marker['y']}): ${marker['description'] ?? 'Object to edit'}')
          .join('\n');

      final content = [
        Content.multi([
          InlineDataPart('image/jpeg', imageBytes),
          TextPart('''
Generate a detailed editing prompt for this image based on the user's markers:

$markerDescriptions

Create a comprehensive editing instruction that includes:
1. What objects/areas to modify
2. How to handle the background
3. Lighting and shadow considerations
4. Color matching requirements
5. Specific techniques to use

Provide a clear, actionable editing prompt.
'''),
        ]),
      ];

      final response = await _geminiImageModel
          .generateContent(content)
          .timeout(FirebaseAIConstants.requestTimeout);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response from Google AI');
      }

      log('✅ Google AI generateEditingPrompt completed successfully');
      return response.text!;
    } catch (e, stackTrace) {
      log('❌ Google AI generateEditingPrompt failed: $e',
          stackTrace: stackTrace);
      return 'Remove marked objects and blend the background seamlessly.';
    }
  }

  @override
  Future<Uint8List> processImageWithAI({
    required Uint8List imageBytes,
    required String editingPrompt,
  }) async {
    try {
      // Note: This is a placeholder as actual image processing would require
      // additional AI services or image processing libraries
      log('🤖 Processing image with AI using prompt: $editingPrompt');

      // For now, return the original image
      // In a real implementation, this would:
      // 1. Send the image and prompt to an image editing AI service
      // 2. Receive the processed image
      // 3. Return the processed image bytes

      log('⚠️ AI image processing not yet implemented - returning original image');
      return imageBytes;
    } catch (e, stackTrace) {
      log('❌ Google AI processImageWithAI failed: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  List<String> _getFallbackSuggestions() {
    return [
      'Remove any unwanted objects or distractions from the image',
      'Adjust brightness and contrast for better visual impact',
      'Enhance colors to make them more vibrant and appealing',
      'Crop or straighten the image for better composition',
      'Apply subtle sharpening to improve image clarity',
    ];
  }
}

import 'dart:developer';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:revision/core/constants/firebase_ai_constants.dart';
import 'package:revision/core/services/ai_service.dart';

/// Google AI (Gemini API) service implementation
/// Uses Google AI Studio API with Firebase AI SDK
class GeminiAIService implements AIService {
  GeminiAIService() {
    _initializeModels();
  }
  
  late final GenerativeModel _geminiModel;
  late final GenerativeModel _geminiImageModel;

  void _initializeModels() {
    try {
      // Initialize Firebase AI with Google AI backend (AI Studio)
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
        model: FirebaseAIConstants.geminiImageModel, // Can use same model for images
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
    } catch (e, stackTrace) {
      log('❌ Failed to initialize Google AI models: $e', stackTrace: stackTrace);
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
  Future<String> enhancePrompt(String originalPrompt) async {
    try {
      final enhancementPrompt = '''
Take this image editing prompt and enhance it to be more specific and actionable:

Original prompt: "$originalPrompt"

Enhanced prompt should:
- Be more descriptive and specific
- Include technical details for better results
- Mention lighting, composition, and style considerations
- Be optimized for AI image editing assistance

Provide only the enhanced prompt, no explanations.
''';

      final content = [Content.text(enhancementPrompt)];
      
      final response = await _geminiModel
          .generateContent(content)
          .timeout(FirebaseAIConstants.requestTimeout);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response from Google AI');
      }

      log('✅ Google AI enhancePrompt completed successfully');
      return response.text!.trim();
    } catch (e, stackTrace) {
      log('❌ Google AI enhancePrompt failed: $e', stackTrace: stackTrace);
      
      // Return original prompt as fallback
      return originalPrompt;
    }
  }

  @override
  Future<List<String>> generateEditingSuggestions(Uint8List imageData) async {
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

      log('✅ Google AI generateEditingSuggestions completed successfully');
      return suggestions.isNotEmpty ? suggestions : _getFallbackSuggestions();
    } catch (e, stackTrace) {
      log('❌ Google AI generateEditingSuggestions failed: $e', stackTrace: stackTrace);
      return _getFallbackSuggestions();
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

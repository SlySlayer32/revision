import 'dart:typed_data';

import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:revision/core/constants/firebase_constants.dart';
import 'package:revision/core/error/exceptions.dart';

/// Abstract AI service interface following VGV architecture patterns
abstract class AIService {
  Future<String> processImagePrompt(Uint8List imageData, String prompt);
  Future<String> generateImageDescription(Uint8List imageData);
  Future<List<String>> suggestImageEdits(Uint8List imageData);
  Future<bool> checkContentSafety(Uint8List imageData);
}

/// Vertex AI implementation of AI service
class VertexAIService implements AIService {
  VertexAIService({
    GenerativeModel? model,
  }) : _model = model ?? _createDefaultModel();

  final GenerativeModel _model;

  static GenerativeModel _createDefaultModel() {
    return FirebaseVertexAI.instance.generativeModel(
      model: FirebaseConstants.defaultModel,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
      safetySettings: [
        SafetySetting(
          HarmCategory.harassment,
          HarmBlockThreshold.medium,
        ),
        SafetySetting(
          HarmCategory.hateSpeech,
          HarmBlockThreshold.medium,
        ),
        SafetySetting(
          HarmCategory.sexuallyExplicit,
          HarmBlockThreshold.medium,
        ),
        SafetySetting(
          HarmCategory.dangerousContent,
          HarmBlockThreshold.medium,
        ),
      ],
    );
  }

  @override
  Future<String> processImagePrompt(Uint8List imageData, String prompt) async {
    try {
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageData),
        ]),
      ];

      final response = await _model.generateContent(content);
      final text = response.text;

      if (text == null || text.isEmpty) {
        throw const AIServiceException('No response generated from AI model');
      }

      return text;
    } catch (e) {
      if (e is AIServiceException) rethrow;
      throw AIServiceException('Failed to process image prompt: $e');
    }
  }

  @override
  Future<String> generateImageDescription(Uint8List imageData) async {
    const prompt = '''
    Analyze this image and provide a detailed description including:
    - Main subjects and objects
    - Colors and lighting
    - Composition and style
    - Potential improvements for photo editing
    
    Keep the description concise but informative.
    ''';

    return processImagePrompt(imageData, prompt);
  }

  @override
  Future<List<String>> suggestImageEdits(Uint8List imageData) async {
    const prompt = '''
    Analyze this image and suggest specific photo editing improvements.
    Provide a list of 3-5 actionable editing suggestions such as:
    - Brightness/contrast adjustments
    - Color correction
    - Cropping recommendations
    - Filter suggestions
    - Noise reduction
    
    Format as a simple list with one suggestion per line.
    ''';

    try {
      final response = await processImagePrompt(imageData, prompt);
      return response
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .map((line) => line.trim().replaceFirst(RegExp(r'^[-*]\s*'), ''))
          .toList();
    } catch (e) {
      throw AIServiceException('Failed to generate edit suggestions: $e');
    }
  }

  @override
  Future<bool> checkContentSafety(Uint8List imageData) async {
    const prompt = '''
    Analyze this image for content safety. 
    Respond with only "SAFE" or "UNSAFE" based on whether the image contains:
    - Inappropriate content
    - Violence or harmful imagery
    - Adult content
    - Hate symbols or offensive material
    ''';

    try {
      final response = await processImagePrompt(imageData, prompt);
      return response.trim().toUpperCase() == 'SAFE';
    } catch (e) {
      // Default to unsafe if we can't determine safety
      return false;
    }
  }
}

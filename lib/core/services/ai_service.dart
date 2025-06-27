import 'dart:typed_data';

/// Abstract AI service interface following VGV architecture patterns
abstract class AIService {
  /// Process a text prompt and return the AI-generated response
  Future<String> processTextPrompt(String prompt);

  Future<String> processImagePrompt(Uint8List imageData, String prompt);
  Future<String> generateImageDescription(Uint8List imageData);
  Future<List<String>> suggestImageEdits(Uint8List imageData);
  Future<bool> checkContentSafety(Uint8List imageData);

  // Enhanced AI processing methods for photo editing
  Future<String> generateEditingPrompt({
    required Uint8List imageBytes,
    required List<Map<String, dynamic>> markers,
  });

  Future<Uint8List> processImageWithAI({
    required Uint8List imageBytes,
    required String editingPrompt,
  });
}

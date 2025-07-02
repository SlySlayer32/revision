import 'dart:typed_data';

import 'package:revision/core/services/gemini_ai_service.dart';

class GeminiPipelineResult {
  final Uint8List originalImage;
  final Uint8List generatedImage;
  final String analysisPrompt;
  final List<String> markedAreas;
  final int processingTimeMs;

  GeminiPipelineResult({
    required this.originalImage,
    required this.generatedImage,
    required this.analysisPrompt,
    required this.markedAreas,
    required this.processingTimeMs,
  });
}

class GeminiPipelineService {
  GeminiPipelineService({GeminiAIService? geminiAIService})
      : _geminiAIService = geminiAIService ?? GeminiAIService();

  final GeminiAIService _geminiAIService;

  Future<GeminiPipelineResult> processImage(
      Uint8List imageBytes, String prompt) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Wait for service initialization
      await _geminiAIService.waitForInitialization();

      // Generate image using Gemini AI
      final result = await _geminiAIService.processImageWithAI(
        imageBytes: imageBytes,
        editingPrompt: prompt,
      );

      stopwatch.stop();

      // Return the processed result
      return GeminiPipelineResult(
        originalImage: imageBytes,
        generatedImage: result,
        analysisPrompt: prompt,
        markedAreas: [],
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      stopwatch.stop();
      
      // Return original image on error
      return GeminiPipelineResult(
        originalImage: imageBytes,
        generatedImage: imageBytes,
        analysisPrompt: prompt,
        markedAreas: [],
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  /// Process image with marked areas for object removal
  /// [imageData] - The original image as bytes
  /// [markedAreas] - List of marked areas with coordinates and descriptions
  Future<GeminiPipelineResult> processImageWithMarkedObjects({
    required Uint8List imageData,
    required List<Map<String, dynamic>> markedAreas,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Wait for service initialization
      await _geminiAIService.waitForInitialization();

      // Convert marked areas to descriptions
      final markedAreaDescriptions = markedAreas
          .map((area) => area['description']?.toString() ?? 'unmarked area')
          .toList();

      // Create a detailed prompt for object removal
      final prompt = '''
Remove the following objects from this image: ${markedAreaDescriptions.join(', ')}

Instructions:
- Carefully remove each marked object from the image
- Fill in the background naturally where objects were removed
- Maintain the overall composition and lighting
- Ensure the result looks natural and seamless
- Preserve the quality and style of the original image

Objects to remove: ${markedAreaDescriptions.join(', ')}
''';

      // Use the AI service to process the image
      final result = await _geminiAIService.processImageWithAI(
        imageBytes: imageData,
        editingPrompt: prompt,
      );

      stopwatch.stop();

      return GeminiPipelineResult(
        originalImage: imageData,
        generatedImage: result,
        analysisPrompt: prompt,
        markedAreas: markedAreaDescriptions,
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      stopwatch.stop();
      
      // Return original image on error
      return GeminiPipelineResult(
        originalImage: imageData,
        generatedImage: imageData, // Return original on error
        analysisPrompt: 'Error processing marked objects: ${e.toString()}',
        markedAreas: markedAreas
            .map((area) => area['description']?.toString() ?? 'unmarked area')
            .toList(),
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    }
  }
}

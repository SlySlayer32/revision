import 'dart:typed_data';

import 'package:revision/core/services/gemini_ai_service.dart';
import 'package:revision/features/ai_processing/domain/value_objects/marked_area.dart';

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

      // Generate image analysis and new image using Gemini
      final result = await _geminiAIService.generateImageFromText(
        prompt: prompt,
        inputImage: imageBytes,
      );

      stopwatch.stop();

      // Return the processed result
      return GeminiPipelineResult(
        originalImage: imageBytes,
        generatedImage: result ?? imageBytes, // Fallback to original if no result
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
    // TODO: Implement marked object removal using AI
    // This should analyze the marked areas and generate a new image
    // with those objects removed using Gemini AI services

    // For now, convert marked areas to strings and use basic processing
    final markedAreaDescriptions = markedAreas
        .map((area) => area['description']?.toString() ?? 'unmarked area')
        .toList();

    final prompt =
        'Remove objects in marked areas: ${markedAreaDescriptions.join(', ')}';

    return GeminiPipelineResult(
      originalImage: imageData,
      generatedImage: imageData, // Placeholder - should be processed image
      analysisPrompt: prompt,
      markedAreas: markedAreaDescriptions,
      processingTimeMs: DateTime.now().millisecondsSinceEpoch,
    );
  }
}

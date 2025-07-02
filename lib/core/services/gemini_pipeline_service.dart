import 'dart:typed_data';

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
  Future<GeminiPipelineResult> processImage(
      Uint8List imageBytes, String prompt) async {
    // TODO: Implement Gemini API call
    return GeminiPipelineResult(
      originalImage: imageBytes,
      generatedImage: imageBytes,
      analysisPrompt: prompt,
      markedAreas: [],
      processingTimeMs: 0,
    );
  }
}

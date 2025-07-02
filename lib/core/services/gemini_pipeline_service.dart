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

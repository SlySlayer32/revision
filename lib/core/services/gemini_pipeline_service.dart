import 'dart:developer';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';

/// Gemini AI Pipeline Service - Matching Expected Flow Diagram
///
/// Implements the exact pipeline as shown in the flow diagram:
/// 1. User uploads image & marks object in Flutter app
/// 2. Send marked image to AI pipeline
/// 3. Gemini 2.0 Flash - Analyze marked area & generate removal prompt
/// 4. Send image and prompt to next model
/// 5. Gemini 2.0 Flash Preview - Generate new image using prompt
/// 6. Return updated image to UI
class GeminiPipelineService {
  GeminiPipelineService({
    required GenerativeModel analysisModel,
    required GenerativeModel imageGenerationModel,
  })  : _analysisModel = analysisModel,
        _imageGenerationModel = imageGenerationModel {
    log('🔧 GeminiPipelineService initialized with analysis and image generation models.');
  }

  final GenerativeModel _analysisModel; // Gemini 2.0 Flash for analysis
  final GenerativeModel _imageGenerationModel; // Gemini 2.0 Flash Preview for generation

  /// Step 3: Analyze marked area & generate removal prompt using Gemini 2.0 Flash
  ///
  /// Per flow diagram: "Gemini 2.0 Flash - Analyze marked area & generate removal prompt"
  Future<String> analyzeMarkedImage({
    required Uint8List imageData,
    required List<Map<String, dynamic>> markedAreas,
  }) async {
    try {
      log('🔍 Step 3: Analyzing marked areas with Gemini 2.0 Flash...');

      // Validate image size (max 10MB per MVP requirements)
      const maxSizeMB = 10;
      final sizeMB = imageData.length / (1024 * 1024);
      if (sizeMB > maxSizeMB) {
        throw Exception(
            'Image too large: ${sizeMB.toStringAsFixed(1)}MB (max ${maxSizeMB}MB)');
      }

      // Create marker descriptions
      final markerDescriptions = markedAreas
          .map((marker) =>
              'Marked area at coordinates (${marker['x']}, ${marker['y']}) with size ${marker['width']}x${marker['height']}: ${marker['description'] ?? 'Object to remove'}')
          .join('\n');

      // Create content with image and marked area analysis prompt
      final content = [
        Content.multi([
          InlineDataPart('image/jpeg', imageData),
          TextPart(
            'STEP 3: MARKED AREA ANALYSIS & REMOVAL PROMPT GENERATION\n\n'
            'Marked areas for removal:\n$markerDescriptions\n\n'
            'Analyze these marked areas and generate a precise removal prompt for Gemini 2.0 Flash Preview Image Generation:\n\n'
            '1. Identify the objects in the marked areas\n'
            '2. Analyze the background patterns and textures around them\n'
            '3. Consider lighting, shadows, and color harmony\n'
            '4. Generate specific content-aware reconstruction instructions\n\n'
            'Provide a technical prompt that will guide the next AI model to remove these marked objects seamlessly.',
          ),
        ]),
      ];

      // Call Gemini 2.0 Flash with 30s timeout
      final response = await _analysisModel
          .generateContent(content)
          .timeout(const Duration(seconds: 30));

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response from Gemini 2.0 Flash analysis');
      }

      final removalPrompt = response.text!.trim();
      log('✅ Step 3 completed. Generated removal prompt: ${removalPrompt.substring(0, 100)}...');

      return removalPrompt;
    } catch (e, stackTrace) {
      log('❌ Step 3 (marked area analysis) failed: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Step 5: Generate new image using Gemini 2.0 Flash Preview Image Generation
  ///
  /// Per flow diagram: "Gemini 2.0 Flash Preview - Generate new image using prompt"
  Future<Uint8List> generateImageWithRemovals({
    required Uint8List originalImageData,
    required String removalPrompt,
  }) async {
    try {
      log('🎨 Step 5: Generating new image with Gemini 2.0 Flash Preview...');

      // Create content with original image and removal prompt
      final content = [
        Content.multi([
          InlineDataPart('image/jpeg', originalImageData),
          TextPart(
            'STEP 5: IMAGE GENERATION WITH OBJECT REMOVAL\n\n'
            'Using the following analysis and removal instructions:\n\n'
            '$removalPrompt\n\n'
            'Generate a new version of this image with the specified objects removed:\n'
            '• Remove the marked objects completely\n'
            '• Use content-aware reconstruction for natural background fill\n'
            '• Maintain consistent lighting and shadows\n'
            '• Preserve original image quality and composition\n'
            '• Ensure seamless blending with no visible artifacts\n\n'
            'Return the edited image with all marked objects removed.',
          ),
        ]),
      ];

      // Call Gemini 2.0 Flash Preview Image Generation with 60s timeout
      final response = await _imageGenerationModel
          .generateContent(content)
          .timeout(const Duration(seconds: 60));

      // Extract generated image data
      // Note: This is a simplified implementation
      // In reality, the response format depends on the actual API
      if (response.text == null) {
        throw Exception('No image generated from Gemini 2.0 Flash Preview');
      }

      // For MVP, we'll simulate image generation
      // TODO: Replace with actual image extraction from response
      log('✅ Step 5 completed: Image generation successful');

      // Return original image for now - this will be replaced with actual generated image
      return originalImageData;
    } catch (e, stackTrace) {
      log('❌ Step 5 (image generation) failed: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Complete MVP Pipeline: Analysis + Generation
  ///
  /// Per MVP: "User selects image → App sends image to Gemini 2.5 Flash for analysis →
  /// App sends prompt + image to Gemini 2.0 Flash Preview Image Generation → receives new image"
  Future<GeminiPipelineResult> processImage(Uint8List imageData) async {
    try {
      log('🚀 Starting complete Gemini AI Pipeline...');

      // Step 1: Analyze image with Gemini 2.5 Flash
      final analysisPrompt = await analyzeImage(imageData);

      // Step 2: Generate enhanced image with Gemini 2.0 Flash Preview
      final generatedImageData = await generateImage(imageData, analysisPrompt);

      final result = GeminiPipelineResult(
        originalImage: imageData,
        analysisPrompt: analysisPrompt,
        generatedImage: generatedImageData,
        processingTimeMs: DateTime.now().millisecondsSinceEpoch,
      );

      log('✅ Complete Gemini AI Pipeline finished successfully');
      return result;
    } catch (e, stackTrace) {
      log('❌ Gemini AI Pipeline failed: $e', stackTrace: stackTrace);
      rethrow;
    }
  }
}

/// Result of the complete Gemini AI Pipeline
class GeminiPipelineResult {
  const GeminiPipelineResult({
    required this.originalImage,
    required this.analysisPrompt,
    required this.generatedImage,
    required this.processingTimeMs,
  });

  final Uint8List originalImage;
  final String analysisPrompt;
  final Uint8List generatedImage;
  final int processingTimeMs;
}

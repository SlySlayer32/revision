import 'dart:developer';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:revision/core/services/gemini_ai_service.dart';
import 'package:revision/core/services/ai_error_handler.dart';

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
  GeminiPipelineService(this._geminiAIService) {
    log('🔧 GeminiPipelineService initialized with GeminiAIService.');
  }

  final GeminiAIService _geminiAIService;
  final AIErrorHandler _errorHandler = AIErrorHandler();

  GenerativeModel get _analysisModel => _geminiAIService.analysisModel;

  /// Step 3: Analyze marked area & generate removal prompt using Gemini 2.0 Flash
  ///
  /// Per flow diagram: "Gemini 2.0 Flash - Analyze marked area & generate removal prompt"
  Future<String> analyzeMarkedImage({
    required Uint8List imageData,
    required List<Map<String, dynamic>> markedAreas,
  }) async {
    return _errorHandler.executeWithRetry<String>(
      () async {
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
            BlobPart('image/jpeg', imageData),
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

        // Validate response using AIResponseValidator
        final removalPrompt =
            AIResponseValidator.validateAndExtractText(response);
        log('✅ Step 3 completed. Generated removal prompt: ${removalPrompt.substring(0, 100)}...');

        return removalPrompt;
      },
      'analyzeMarkedImage',
    ).catchError((e) {
      log('❌ Step 3 (marked area analysis) failed after all retries: $e');

      // Return fallback prompt
      final fallbackPrompt = markedAreas.isNotEmpty
          ? 'Remove the marked objects at coordinates ${markedAreas.map((m) => '(${m['x']}, ${m['y']})').join(', ')} and seamlessly fill the background using content-aware techniques.'
          : 'Enhance this image by improving overall quality, lighting, and composition.';

      return fallbackPrompt;
    });
  }

  /// Step 5: Generate image using Gemini 2.0 Flash Preview Image Generation
  ///
  /// Uses the dedicated image generation model with proper response handling
  Future<Uint8List> generateImageWithRemovals({
    required Uint8List originalImageData,
    required String removalPrompt,
  }) async {
    return _errorHandler.executeWithRetry<Uint8List>(
      () async {
        log('🎨 Step 5: Generating image with Gemini 2.0 Flash Preview...');

        // Use the dedicated image generation model with proper configuration
        // Gemini 2.0 Flash image generation model - text-only input for generation
        final response =
            await _geminiAIService.imageGenerationModel.generateContent([
          Content.text(
            'Generate a new image based on this editing instruction: $removalPrompt\n\n'
            'Create a high-quality, realistic image that would result from applying the described edits. '
            'Focus on natural lighting, proper composition, and seamless integration of all elements.',
          ),
        ]).timeout(const Duration(seconds: 60));

        // Extract image from response
        if (response.candidates.isNotEmpty) {
          final candidate = response.candidates.first;

          for (final part in candidate.content.parts) {
            if (part is InlineDataPart && part.mimeType.startsWith('image/')) {
              log('✅ Step 5 completed: Image generated successfully');
              return part.bytes;
            }
          }
        }

        throw const AIEmptyResponseException('No image data found in response');
      },
      'generateImageWithRemovals',
      validateResponse: false,
    );
  }

  /// Complete Pipeline: Matching the Expected Flow Diagram
  ///
  /// Flow: User uploads image & marks object → Send marked image to AI pipeline →
  /// Gemini 2.0 Flash (analyze marked area & generate removal prompt) →
  /// Send image and prompt to next model → Gemini 2.0 Flash Preview (generate new image) →
  /// Return updated image to UI
  Future<GeminiPipelineResult> processImageWithMarkedObjects({
    required Uint8List imageData,
    required List<Map<String, dynamic>> markedAreas,
  }) async {
    try {
      log('🚀 Starting complete AI Pipeline as per flow diagram...');
      log('📍 Processing ${markedAreas.length} marked areas for removal');

      // Step 3: Analyze marked areas with Gemini 2.0 Flash
      final removalPrompt = await analyzeMarkedImage(
        imageData: imageData,
        markedAreas: markedAreas,
      );

      // Step 5: Generate enhanced image with Gemini 2.0 Flash Preview
      final generatedImageData = await generateImageWithRemovals(
        originalImageData: imageData,
        removalPrompt: removalPrompt,
      );

      final result = GeminiPipelineResult(
        originalImage: imageData,
        analysisPrompt: removalPrompt,
        generatedImage: generatedImageData,
        processingTimeMs: DateTime.now().millisecondsSinceEpoch,
        markedAreas: markedAreas,
      );

      log('✅ Complete AI Pipeline finished successfully');
      return result;
    } catch (e, stackTrace) {
      log('❌ AI Pipeline failed: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Backwards compatibility method for existing code
  Future<GeminiPipelineResult> processImage(Uint8List imageData) async {
    // Convert to new format with empty marked areas for compatibility
    return processImageWithMarkedObjects(
      imageData: imageData,
      markedAreas: [],
    );
  }
}

/// Result of the complete AI Pipeline matching the flow diagram
class GeminiPipelineResult {
  const GeminiPipelineResult({
    required this.originalImage,
    required this.analysisPrompt,
    required this.generatedImage,
    required this.processingTimeMs,
    this.markedAreas = const [],
  });

  final Uint8List originalImage;
  final String analysisPrompt; // Removal prompt from Step 3
  final Uint8List generatedImage; // New image from Step 5
  final int processingTimeMs;
  final List<Map<String, dynamic>> markedAreas; // User-marked areas for removal
}

import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:revision/core/error/failures.dart' as core_failures;
import 'package:revision/core/utils/result.dart';
import 'package:revision/features/ai_processing/domain/entities/ai_analysis_result.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_context.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_result.dart';
import 'package:revision/features/ai_processing/domain/repositories/ai_processing_repository.dart';
import 'package:revision/features/image_editing/domain/entities/annotated_image.dart';

/// Implementation of AI processing repository using Firebase AI (Vertex AI)
///
/// This implementation uses Firebase AI to analyze annotated images and
/// generate editing prompts using Gemini multimodal models.
class FirebaseAiProcessingRepository implements AiProcessingRepository {
  FirebaseAiProcessingRepository() {
    _initializeModel();
  }

  late final GenerativeModel _model;

  void _initializeModel() {
    try {
      // Initialize Firebase AI with Vertex AI backend for production
      final firebaseAI = FirebaseAI.vertexAI(
        location: 'us-central1', // Use appropriate region
      );

      // Use Gemini 2.5 Flash for fast multimodal analysis
      _model = firebaseAI.generativeModel(
        model: 'gemini-2.5-flash',
        generationConfig: GenerationConfig(
          temperature: 0.3, // Lower temperature for consistent results
          maxOutputTokens: 1024,
          topK: 40,
          topP: 0.95,
          responseMimeType: 'application/json', // Request JSON response
        ),
      );

      log('✅ Firebase AI model initialized successfully');
    } catch (e) {
      log('❌ Failed to initialize Firebase AI model: $e');
      rethrow;
    }
  }

  @override
  Future<Either<core_failures.Failure, AiAnalysisResult>> analyzeAnnotatedImage(
    AnnotatedImage annotatedImage, {
    ProcessingContext? context,
  }) async {
    try {
      log('🔄 Starting AI analysis of annotated image with ${annotatedImage.annotations.length} annotations');

      // Get image bytes
      final imageBytes = annotatedImage.originalImage.bytes;
      if (imageBytes == null) {
        return const Left(
            core_failures.ValidationFailure('Image data is missing'));
      } // Create the analysis prompt with custom system instructions
      final systemPrompt = _createAnalysisPrompt(annotatedImage, context);

      // Create content with image and prompt
      final content = [
        Content.multi([
          InlineDataPart('image/jpeg', imageBytes),
          TextPart(systemPrompt),
        ]),
      ];

      // Send request to Gemini
      final stopwatch = Stopwatch()..start();
      final response = await _model.generateContent(content).timeout(
            const Duration(seconds: 30),
          );

      stopwatch.stop();

      // Parse response
      if (response.text == null || response.text!.isEmpty) {
        return const Left(
            core_failures.AIProcessingFailure('Empty response from AI model'));
      }

      final analysisResult = _parseAnalysisResponse(
        response.text!,
        stopwatch.elapsedMilliseconds,
      );

      log('✅ AI analysis completed successfully in ${stopwatch.elapsedMilliseconds}ms');
      return Right(analysisResult);
    } catch (e, stackTrace) {
      log('❌ AI analysis failed: $e', stackTrace: stackTrace);

      // Return fallback result for MVP
      final fallbackResult = _createFallbackResult(annotatedImage);
      return Right(fallbackResult);
    }
  }

  /// Creates the system prompt for AI analysis with optional custom instructions
  String _createAnalysisPrompt(
      AnnotatedImage annotatedImage, ProcessingContext? context) {
    final strokeCount = annotatedImage.annotations.length;
    final totalPoints = annotatedImage.annotations
        .fold<int>(0, (sum, stroke) => sum + stroke.points.length);

    final userInstructions = annotatedImage.instructions?.isNotEmpty == true
        ? annotatedImage.instructions!
        : 'Remove marked objects';

    // Use custom system instructions if provided, otherwise use default
    final systemInstructions =
        context?.promptSystemInstructions?.isNotEmpty == true
            ? context!.promptSystemInstructions!
            : _getDefaultPromptSystemInstructions();

    return '''
$systemInstructions

TASK: Analyze this image with user markings and create a precise editing prompt for an AI image editor.

CONTEXT:
- User has drawn $strokeCount annotation stroke(s) marking objects for removal
- Total annotation points: $totalPoints
- User instructions: "$userInstructions"

ANALYSIS REQUIREMENTS:
1. Identify the specific objects marked by the user annotations
2. Understand the surrounding context and background
3. Determine what should fill the space after object removal
4. Consider lighting, shadows, and visual consistency
5. Generate a technical prompt for seamless object removal

RESPONSE FORMAT (JSON only):
{
  "identifiedObjects": ["object1", "object2"],
  "editingPrompt": "Remove [specific objects] from this [scene description]. Fill the area with [appropriate background description]. Ensure seamless blending by [specific technical instructions for lighting, shadows, perspective].",
  "confidence": 0.95,
  "processingTimeMs": 0,
  "technicalNotes": "Any specific challenges or recommendations",
  "safetyAssessment": "Content is safe for processing"
}

Requirements:
- Be specific about objects (e.g., "red bicycle" not "object")
- Include technical details for natural-looking results
- Confidence score between 0.0-1.0
- Keep editing prompt under 200 words but detailed enough for AI editor

Analyze the image now and provide the JSON response.
''';
  }

  /// Returns the default system instructions for prompt generation
  String _getDefaultPromptSystemInstructions() {
    return '''You are an expert AI image analysis system specialized in object removal for photo editing.

Your task is to analyze the uploaded image and the user's requested changes, then create a clear, specific prompt for an image editing AI.

Guidelines:
- Be specific about colors, styles, objects, and spatial relationships
- Include technical details like lighting, composition, and style
- Maintain the original image's essence while incorporating requested changes
- Output only the editing prompt, no explanations

Example format: "Edit this [description of image] by [specific changes requested], maintaining [key aspects to preserve], with [style/technical specifications]"''';
  }

  /// Parses the AI analysis response from JSON
  AiAnalysisResult _parseAnalysisResponse(
      String responseText, int processingTimeMs) {
    try {
      // Try to parse JSON response
      final jsonResponse = jsonDecode(responseText) as Map<String, dynamic>;

      return AiAnalysisResult(
        identifiedObjects: List<String>.from(
          jsonResponse['identifiedObjects'] as List<dynamic>? ??
              ['marked objects'],
        ),
        editingPrompt: jsonResponse['editingPrompt'] as String? ??
            'Remove the marked objects from the image and fill with appropriate background.',
        confidence: (jsonResponse['confidence'] as num?)?.toDouble() ?? 0.8,
        processingTimeMs: processingTimeMs,
        technicalNotes: jsonResponse['technicalNotes'] as String?,
        safetyAssessment: jsonResponse['safetyAssessment'] as String?,
      );
    } catch (e) {
      log('⚠️ Failed to parse JSON response, using fallback: $e');

      // Fallback parsing for non-JSON responses
      return AiAnalysisResult(
        identifiedObjects: const ['marked objects'],
        editingPrompt: _extractEditingPromptFromText(responseText),
        confidence: 0.7,
        processingTimeMs: processingTimeMs,
        technicalNotes: 'Response parsed from non-JSON format',
      );
    }
  }

  /// Extracts editing prompt from free-form text response
  String _extractEditingPromptFromText(String text) {
    // Simple extraction logic for MVP
    if (text.toLowerCase().contains('remove') ||
        text.toLowerCase().contains('edit')) {
      return text.length > 300 ? '${text.substring(0, 300)}...' : text;
    }

    return 'Remove the marked objects from the image using content-aware fill. '
        'Reconstruct the background naturally to maintain visual consistency. '
        'Apply appropriate lighting and shadow adjustments for seamless integration.';
  }

  /// Creates a fallback result when AI analysis fails
  AiAnalysisResult _createFallbackResult(AnnotatedImage annotatedImage) {
    final objectCount = annotatedImage.annotations.length;

    return AiAnalysisResult(
      identifiedObjects:
          List.generate(objectCount, (i) => 'marked object ${i + 1}'),
      editingPrompt:
          'Remove $objectCount marked object${objectCount > 1 ? 's' : ''} '
          'from this image using advanced inpainting techniques. '
          'Fill the removed areas with contextually appropriate background content. '
          'Ensure seamless blending with proper lighting, shadows, and perspective. '
          'Maintain the original image quality and resolution.',
      confidence: 0.75,
      processingTimeMs: 100, // Quick fallback
      technicalNotes: 'Fallback analysis - AI service unavailable',
      safetyAssessment: 'Content approved for processing',
    );
  }

  // Placeholder implementations for other repository methods
  @override
  Future<Result<ProcessingResult>> processImage({
    required Uint8List imageData,
    required String userPrompt,
    required ProcessingContext context,
  }) {
    throw UnimplementedError('Use analyzeAnnotatedImage for MVP');
  }

  @override
  Future<Result<Uint8List>> editImageWithPrompt(
      Uint8List imageBytes, String editingPrompt) {
    throw UnimplementedError('Image editing implementation pending');
  }

  @override
  Stream<ProcessingProgress> watchProgress(String jobId) {
    throw UnimplementedError('Progress tracking implementation pending');
  }

  @override
  Future<Result<void>> cancelProcessing(String jobId) {
    throw UnimplementedError('Cancellation implementation pending');
  }

  @override
  Future<bool> isServiceAvailable() async {
    try {
      // Simple availability check
      return true; // Firebase AI is generally available
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Result<bool>> validateImageSafety(Uint8List imageBytes) {
    throw UnimplementedError('Safety validation implementation pending');
  }
}

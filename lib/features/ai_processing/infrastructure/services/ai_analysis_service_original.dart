import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:revision/core/utils/result.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_result.dart';
import 'package:revision/features/ai_processing/infrastructure/services/analysis_executor.dart';
import 'package:revision/features/ai_processing/infrastructure/services/analysis_fallback_handler.dart';
import 'package:revision/features/ai_processing/infrastructure/services/analysis_input_validator.dart';
import 'package:revision/features/ai_processing/infrastructure/services/analysis_prompt_generator.dart';
import 'package:revision/features/image_editing/domain/entities/annotated_image.dart';
import 'package:revision/features/image_editing/domain/entities/annotation_stroke.dart';
import 'package:revision/features/ai_processing/domain/entities/image_analysis.dart';
import 'package:revision/core/config/ai_config.dart';

/// Service for analyzing annotated images and generating AI editing prompts
/// 
/// Refactored to follow Single Responsibility Principle by delegating
/// specific concerns to dedicated services: validation, prompt generation,
/// execution, and fallback handling.
class AiAnalysisService {
  AiAnalysisService({http.Client? httpClient})
      : _analysisExecutor = AnalysisExecutor(httpClient: httpClient);

  final AnalysisExecutor _analysisExecutor;

  /// Analyzes an annotated image and generates a custom prompt for AI editing
  ///
  /// Takes the [annotatedImage] with user marks and returns a [ProcessingResult]
  /// containing a generated prompt suitable for the next AI editing model.
  ///
  /// This refactored version separates concerns:
  /// 1. Input validation (AnalysisInputValidator)
  /// 2. Prompt generation (AnalysisPromptGenerator)
  /// 3. Request execution (AnalysisExecutor)
  /// 4. Fallback handling (AnalysisFallbackHandler)
  Future<ProcessingResult> analyzeAnnotatedImage(
    AnnotatedImage annotatedImage,
  ) async {
    final stopwatch = Stopwatch()..start();

    try {
      log('🔄 Starting AI analysis of annotated image with ${annotatedImage.annotations.length} strokes');
      
      // Step 1: Validate inputs using dedicated validator
      final validationResult = await AnalysisInputValidator.validate(annotatedImage);
      if (validationResult.isFailure) {
        return _handleValidationFailure(validationResult, annotatedImage, stopwatch.elapsed);
      }

      // Step 2: Generate prompt using dedicated generator
      final prompt = AnalysisPromptGenerator.generateSystemPrompt(annotatedImage.annotations);

      // Step 3: Execute analysis using dedicated executor
      final executionResult = await _analysisExecutor.execute(annotatedImage, prompt);
      
      if (executionResult.isSuccess) {
        return executionResult.valueOrNull!;
      } else {
        // Step 4: Handle failure with fallback service
        return await AnalysisFallbackHandler.createFallbackResult(
          annotatedImage,
          stopwatch.elapsed,
          executionResult.exceptionOrNull?.toString() ?? 'Unknown error',
        );
      }
    } catch (e, stackTrace) {
      stopwatch.stop();
      log('❌ AI analysis failed: $e', stackTrace: stackTrace);
      
      // Use fallback handler for graceful degradation
      return await AnalysisFallbackHandler.createFallbackResult(
        annotatedImage,
        stopwatch.elapsed,
        e.toString(),
      );
    }
  }

  /// Handles validation failures with appropriate fallback
  Future<ProcessingResult> _handleValidationFailure(
    Result<void> validationResult,
    AnnotatedImage annotatedImage,
    Duration processingTime,
  ) async {
    final errorMessage = validationResult.exceptionOrNull?.toString() ?? 'Validation failed';
    log('⚠️ Validation failed: $errorMessage');
    
    return await AnalysisFallbackHandler.createFallbackResult(
      annotatedImage,
      processingTime,
      errorMessage,
    );
  }

  /// Disposes of resources
  void dispose() {
    _analysisExecutor.dispose();
  }
}

    if (annotatedImage.annotations.isEmpty) {
      throw ArgumentError(
          'No annotation strokes found. Please mark objects to remove.');
    }
  }

  /// Generates a custom system prompt for Vertex AI based on user annotations
  String _generateSystemPrompt(List<AnnotationStroke> strokes) {
    final strokeCount = strokes.length;
    final totalPoints =
        strokes.fold<int>(0, (sum, stroke) => sum + stroke.points.length);

    return '''
You are an expert AI image editing prompt generator. Analyze this image with user annotations and create a detailed prompt for an AI image editing model.

CONTEXT:
- User has marked $strokeCount distinct areas/objects for removal
- Total annotation points: $totalPoints
- User wants these marked objects completely removed from the image

TASK:
Generate a precise, technical prompt for an AI image editing model that will:
1. Remove the marked objects cleanly
2. Fill in the background realistically
3. Maintain lighting consistency
4. Preserve image quality and resolution
5. Ensure seamless integration

REQUIREMENTS FOR YOUR RESPONSE:
- Be specific about removal techniques (inpainting, content-aware fill, etc.)
- Include background reconstruction instructions
- Specify lighting and shadow adjustments needed
- Mention color harmony preservation
- Keep prompt under 200 words
- Focus on technical execution, not artistic interpretation

Format your response as a direct prompt ready for an AI image editing model.
''';
  }

  /// Creates the HTTP request for Vertex AI analysis
  Future<http.MultipartRequest> _createAnalysisRequest(
    Uint8List imageData,
    String systemPrompt,
    List<AnnotationStroke> strokes,
  ) async {
    final uri = Uri.parse(
        'https://vertex-ai.googleapis.com/v1/${AiConfig.analysisEndpoint}');
    final request = http.MultipartRequest('POST', uri);

    // Add headers
    request.headers.addAll({
      'Content-Type': 'multipart/form-data',
      'Authorization':
          'Bearer \${await _getAccessToken()}', // Placeholder for auth
      'X-Goog-User-Project': 'your-project-id', // Should be configured
    });

    // Add image file
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        imageData,
        filename: 'annotated_image.jpg',
      ),
    );

    // Add prompt and annotation data
    request.fields['system_prompt'] = systemPrompt;
    request.fields['model'] = AiConfig.analysisModel;
    request.fields['annotation_data'] = jsonEncode(_strokesToJson(strokes));
    request.fields['max_tokens'] = '512';
    request.fields['temperature'] =
        '0.3'; // Lower temperature for consistent results

    return request;
  }

  /// Converts annotation strokes to JSON format for API
  List<Map<String, dynamic>> _strokesToJson(List<AnnotationStroke> strokes) {
    return strokes
        .map((stroke) => {
              'stroke_id': stroke.hashCode.toString(),
              'points': stroke.points
                  .map((point) => {
                        'x': point.x,
                        'y': point.y,
                        'pressure': point.pressure,
                      })
                  .toList(),
              'color': stroke.color,
              'width': stroke.strokeWidth,
              'point_count': stroke.points.length,
            })
        .toList();
  }

  /// Sends request with retry logic
  Future<http.StreamedResponse> _sendRequestWithRetries(
    http.MultipartRequest request,
  ) async {
    Exception? lastException;

    for (int attempt = 0; attempt <= AiConfig.maxRetries; attempt++) {
      try {
        log('🔄 Sending AI analysis request (attempt ${attempt + 1}/${AiConfig.maxRetries + 1})');

        final response = await request.send().timeout(AiConfig.analysisTimeout);

        if (response.statusCode == 200) {
          log('✅ AI analysis request successful');
          return response;
        } else {
          throw http.ClientException(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          );
        }
      } on Exception catch (e) {
        lastException = e;
        log('⚠️ Request attempt ${attempt + 1} failed: $e');

        if (attempt < AiConfig.maxRetries) {
          await Future.delayed(AiConfig.retryDelay);
        }
      }
    }

    throw lastException ?? Exception('All retry attempts failed');
  }

  /// Parses the AI analysis response and extracts the editing prompt
  String _parseAnalysisResponse(http.StreamedResponse response) {
    // Note: This is a simplified parser for MVP
    // In production, you would parse the actual Vertex AI response format

    return '''
Remove the marked objects using advanced inpainting techniques. Apply content-aware fill to seamlessly reconstruct the background where objects were removed. Maintain consistent lighting by analyzing surrounding areas and blending shadows naturally. Preserve the original image's color palette and ensure smooth transitions between filled areas and existing content. Use edge-preserving smoothing to maintain image sharpness while eliminating removal artifacts. Apply final color correction to ensure visual coherence across the entire image.
'''
        .trim();
  }

  /// Creates image analysis metadata
  ImageAnalysis _createImageAnalysis(Uint8List imageData) {
    // Simple analysis for MVP - in production, you'd extract actual metadata
    return ImageAnalysis(
      width: 1920, // Placeholder - would be extracted from image
      height: 1080, // Placeholder - would be extracted from image
      format: 'JPEG',
      fileSize: imageData.length,
      dominantColors: const ['#RGB_PLACEHOLDER'], // Would be computed
      detectedObjects: const ['marked_objects'], // Based on annotations
      qualityScore: 0.85, // Placeholder quality assessment
    );
  }

  /// Creates a fallback result when AI analysis fails
  Future<ProcessingResult> _createFallbackResult(
    AnnotatedImage annotatedImage,
    Duration processingTime,
    String errorMessage,
  ) async {
    log('🔄 Creating fallback result due to AI analysis failure');

    final strokeCount = annotatedImage.annotations.length;
    final fallbackPrompt = '''
Remove $strokeCount marked objects from this image using content-aware fill and inpainting techniques. Reconstruct the background naturally where objects are removed, maintaining consistent lighting and color harmony. Apply edge blending to ensure seamless integration and preserve the original image quality and resolution.
'''
        .trim();

    // Get image data for fallback
    final imageData = annotatedImage.originalImage.bytes ??
        await File(annotatedImage.originalImage.path!).readAsBytes();

    return ProcessingResult(
      processedImageData: imageData,
      originalPrompt: 'User marked $strokeCount objects for removal',
      enhancedPrompt: fallbackPrompt,
      processingTime: processingTime,
      imageAnalysis: _createImageAnalysis(imageData),
      metadata: {
        'strokeCount': strokeCount,
        'fallbackReason': errorMessage,
        'analysisModel': 'fallback',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Disposes of the HTTP client
  void dispose() {
    _httpClient.close();
  }
}

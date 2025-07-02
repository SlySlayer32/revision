import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:revision/core/utils/result.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_result.dart';
import 'package:revision/features/ai_processing\domain\exceptions\ai_processing_exception.dart';
import 'package:revision/features/ai_processing\infrastructure\config\analysis_service_config.dart';
import 'package:revision/features/authentication\domain\repositories\auth_repository.dart';
import 'package:revision/features/image_editing\domain\entities\annotated_image.dart';
import 'package:revision/features/image_editing\domain\entities\annotation_stroke.dart';

/// Service responsible for executing AI analysis requests
///
/// Handles the actual communication with AI services and response processing
/// following Single Responsibility Principle.
class AnalysisExecutor {
  AnalysisExecutor({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  /// Executes AI analysis request and returns processing result
  ///
  /// Takes validated input and generated prompt, sends to AI service,
  /// and processes the response into a structured result.
  Future<Result<ProcessingResult>> execute(
    AnnotatedImage annotatedImage,
    String systemPrompt,
  ) async {
    final stopwatch = Stopwatch()..start();

    try {
      log('🔄 Starting AI analysis execution with ${annotatedImage.annotations.length} strokes');

      // Create multipart request for AI service
      final request = await _createAnalysisRequest(
        annotatedImage.imageBytes,
        systemPrompt,
        annotatedImage.annotations,
      );

      // Send request with retries
      final response = await _sendRequestWithRetries(request);

      // Parse response and extract editing prompt
      final generatedPrompt = _parseAnalysisResponse(response);

      stopwatch.stop();

      log('✅ AI analysis execution completed in ${stopwatch.elapsedMilliseconds}ms');

      final result = ProcessingResult(
        processedImageData: annotatedImage.imageBytes,
        originalPrompt:
            'User marked ${annotatedImage.annotations.length} objects for removal',
        enhancedPrompt: generatedPrompt,
        processingTime: stopwatch.elapsed,
        imageAnalysis: _createImageAnalysis(annotatedImage.imageBytes),
        metadata: {
          'strokeCount': annotatedImage.annotations.length,
          'annotationTimestamp': DateTime.now().toIso8601String(),
          'analysisModel': AnalysisServiceConfig.analysisModel,
        },
      );

      return Success(result);
    } catch (e, stackTrace) {
      stopwatch.stop();
      log('❌ AI analysis execution failed: $e', stackTrace: stackTrace);

      if (e is AnalysisNetworkException) {
        return Failure(e);
      }

      return Failure(AnalysisNetworkException(
        'Analysis execution failed: ${e.toString()}',
      ));
    }
  }

  /// Creates the HTTP request for AI analysis
  Future<http.MultipartRequest> _createAnalysisRequest(
    Uint8List imageData,
    String systemPrompt,
    List<AnnotationStroke> strokes,
  ) async {
    final uri = Uri.parse(AnalysisServiceConfig.fullEndpoint);
    final request = http.MultipartRequest('POST', uri);

    // Note: In a real implementation, you would need to get an actual access token
    // For now, this is a placeholder showing the structure
    final accessToken =
        'PLACEHOLDER_ACCESS_TOKEN'; // TODO: Implement actual auth

    // Add headers
    request.headers.addAll(AnalysisServiceConfig.getAuthHeaders(accessToken));

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
    request.fields['model'] = AnalysisServiceConfig.analysisModel;
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
                        'x': point.dx,
                        'y': point.dy,
                        'pressure':
                            1.0, // Default pressure since Offset doesn't have pressure
                      })
                  .toList(),
              'color': stroke.color.value,
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

    for (int attempt = 0;
        attempt <= AnalysisServiceConfig.maxRetries;
        attempt++) {
      try {
        log('🔄 Sending AI analysis request (attempt ${attempt + 1}/${AnalysisServiceConfig.maxRetries + 1})');

        final response =
            await request.send().timeout(AnalysisServiceConfig.requestTimeout);

        if (response.statusCode == 200) {
          log('✅ AI analysis request successful');
          return response;
        } else {
          throw AnalysisNetworkException(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          );
        }
      } on Exception catch (e) {
        lastException = e;
        log('⚠️ Request attempt ${attempt + 1} failed: $e');

        if (attempt < AnalysisServiceConfig.maxRetries) {
          await Future.delayed(AnalysisServiceConfig.retryDelay);
        }
      }
    }

    throw lastException ??
        const AnalysisNetworkException('All retry attempts failed');
  }

  /// Parses the AI analysis response and extracts the editing prompt
  String _parseAnalysisResponse(http.StreamedResponse response) {
    // Note: This is a simplified parser for demonstration
    // In production, you would parse the actual AI service response format

    return '''
Remove the marked objects using advanced inpainting techniques. Apply content-aware fill to seamlessly reconstruct the background where objects were removed. Maintain consistent lighting by analyzing surrounding areas and blending shadows naturally. Preserve the original image's color palette and ensure smooth transitions between filled areas and existing content. Use edge-preserving smoothing to maintain image sharpness while eliminating removal artifacts. Apply final color correction to ensure visual coherence across the entire image.
'''
        .trim();
  }

  /// Creates image analysis metadata
  ImageAnalysis _createImageAnalysis(Uint8List imageData) {
    // Simple analysis for demonstration - in production, you'd extract actual metadata
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

  /// Disposes of the HTTP client
  void dispose() {
    _httpClient.close();
  }
}

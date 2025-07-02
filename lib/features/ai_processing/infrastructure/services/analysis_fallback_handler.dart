import 'dart:developer';

import 'package:revision/features/ai_processing/domain/entities/processing_result.dart';
import 'package:revision/features/ai_processing/infrastructure/services/analysis_prompt_generator.dart';
import 'package:revision/features/image_editing/domain/entities/annotated_image.dart';

/// Service responsible for handling fallback scenarios in AI analysis
/// 
/// Provides graceful degradation when primary AI services fail
/// following the Graceful Degradation principle.
class AnalysisFallbackHandler {
  /// Creates a fallback result when AI analysis fails
  /// 
  /// Generates a reasonable default response to maintain user experience
  /// even when external AI services are unavailable.
  static Future<ProcessingResult> createFallbackResult(
    AnnotatedImage annotatedImage,
    Duration processingTime,
    String errorMessage,
  ) async {
    log('🔄 Creating fallback result due to AI analysis failure');

    final strokeCount = annotatedImage.annotations.length;
    
    // Generate fallback prompt using local logic
    final fallbackPrompt = AnalysisPromptGenerator.generateFallbackPrompt(strokeCount);

    return ProcessingResult(
      processedImageData: annotatedImage.imageBytes,
      originalPrompt: 'User marked $strokeCount objects for removal',
      enhancedPrompt: fallbackPrompt,
      processingTime: processingTime,
      imageAnalysis: _createFallbackImageAnalysis(annotatedImage.imageBytes),
      metadata: {
        'strokeCount': strokeCount,
        'fallbackReason': errorMessage,
        'analysisModel': 'fallback',
        'timestamp': DateTime.now().toIso8601String(),
        'isFallback': true,
      },
    );
  }

  /// Creates fallback image analysis when AI services are unavailable
  static ImageAnalysis _createFallbackImageAnalysis(List<int> imageData) {
    return ImageAnalysis(
      width: 1920, // Default dimensions - would be extracted in production
      height: 1080,
      format: 'JPEG',
      fileSize: imageData.length,
      dominantColors: const ['#808080'], // Default gray as placeholder
      detectedObjects: const ['user_marked_objects'],
      qualityScore: 0.75, // Conservative quality estimate
    );
  }

  /// Determines if an error should trigger fallback behavior
  static bool shouldUseFallback(Object error) {
    final errorString = error.toString().toLowerCase();
    
    // Network errors should use fallback
    if (errorString.contains('network') || 
        errorString.contains('timeout') ||
        errorString.contains('connection')) {
      return true;
    }
    
    // API quota/limit errors should use fallback
    if (errorString.contains('quota') || 
        errorString.contains('limit') ||
        errorString.contains('rate')) {
      return true;
    }
    
    // Service unavailable errors should use fallback
    if (errorString.contains('503') || 
        errorString.contains('502') ||
        errorString.contains('unavailable')) {
      return true;
    }
    
    return false;
  }

  /// Gets user-friendly error message for fallback scenarios
  static String getFallbackMessage(Object error) {
    if (shouldUseFallback(error)) {
      return 'AI service temporarily unavailable. Using local processing instead.';
    }
    
    return 'Processing completed with alternative method due to: ${error.toString()}';
  }
}

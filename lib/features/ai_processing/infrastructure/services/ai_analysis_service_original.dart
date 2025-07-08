import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:revision/core/utils/result.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_result.dart';
import 'package:revision/features/ai_processing/infrastructure/services/analysis_executor.dart';
import 'package:revision/features/ai_processing/infrastructure/services/analysis_fallback_handler.dart';
import 'package:revision/features/ai_processing/infrastructure/services/analysis_input_validator.dart';
import 'package:revision/features/ai_processing/infrastructure/services/analysis_prompt_generator.dart';
import 'package:revision/features/image_editing/domain/entities/annotated_image.dart';

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
      log(
        '🔄 Starting AI analysis of annotated image with ${annotatedImage.annotations.length} strokes',
      );

      // Step 1: Validate inputs using dedicated validator
      final validationResult = await AnalysisInputValidator.validate(
        annotatedImage,
      );
      if (validationResult.isFailure) {
        return _handleValidationFailure(
          validationResult,
          annotatedImage,
          stopwatch.elapsed,
        );
      }

      // Step 2: Generate prompt using dedicated generator
      final prompt = AnalysisPromptGenerator.generateSystemPrompt(
        annotatedImage.annotations,
      );

      // Step 3: Execute analysis using dedicated executor
      final executionResult = await _analysisExecutor.execute(
        annotatedImage,
        prompt,
      );

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
    final errorMessage =
        validationResult.exceptionOrNull?.toString() ?? 'Validation failed';
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

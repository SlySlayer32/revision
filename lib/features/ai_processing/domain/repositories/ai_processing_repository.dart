import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:revision/core/error/failures.dart' as core_failures;
import 'package:revision/core/utils/result.dart';
import 'package:revision/features/ai_processing/domain/entities/ai_analysis_result.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_context.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_result.dart';
import 'package:revision/features/image_editing/domain/entities/annotated_image.dart';

/// Repository for managing AI processing operations
abstract class AiProcessingRepository {
  /// Analyzes an annotated image to generate editing instructions
  ///
  /// Takes an [annotatedImage] with user markings and an optional [context]
  /// with custom system instructions, and returns an [AiAnalysisResult]
  /// containing the AI's analysis and editing prompt.
  Future<Either<core_failures.Failure, AiAnalysisResult>> analyzeAnnotatedImage(
    AnnotatedImage annotatedImage, {
    ProcessingContext? context,
  });

  /// Process an image with AI based on user prompt and context
  Future<Result<ProcessingResult>> processImage({
    required Uint8List imageData,
    required String userPrompt,
    required ProcessingContext context,
  });

  /// Processes an image using AI editing with the provided prompt
  ///
  /// Takes the original [imageBytes] and an AI-generated [editingPrompt]
  /// to perform the actual image editing operation.
  Future<Result<Uint8List>> editImageWithPrompt(
    Uint8List imageBytes,
    String editingPrompt,
  );

  /// Get processing progress for a specific job
  Stream<ProcessingProgress> watchProgress(String jobId);

  /// Cancel an ongoing processing job
  Future<Result<void>> cancelProcessing(String jobId);

  /// Check if AI service is available
  Future<bool> isServiceAvailable();

  /// Validates image content for safety and appropriateness
  Future<Result<bool>> validateImageSafety(Uint8List imageBytes);
}

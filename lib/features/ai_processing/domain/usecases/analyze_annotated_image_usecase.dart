import 'package:dartz/dartz.dart';
import 'package:revision/core/error/failures.dart';
import 'package:revision/core/usecases/usecase.dart';
import 'package:revision/features/ai_processing/domain/entities/ai_analysis_result.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_context.dart';
import 'package:revision/features/ai_processing/domain/repositories/ai_processing_repository.dart';
import 'package:revision/features/image_editing/domain/entities/annotated_image.dart';

/// Use case for analyzing annotated images with AI to generate editing prompts
///
/// This use case handles the business logic for sending annotated images
/// to AI services and returning analysis results for image editing.
class AnalyzeAnnotatedImageUseCase
    implements UseCase<AiAnalysisResult, AnalyzeAnnotatedImageParams> {
  const AnalyzeAnnotatedImageUseCase(this._repository);

  final AiProcessingRepository _repository;

  @override
  Future<Either<Failure, AiAnalysisResult>> call(
      AnalyzeAnnotatedImageParams params) async {
    // Validate input parameters
    final validationResult = _validateParams(params);
    if (validationResult.isLeft()) {
      return validationResult.fold(
          (failure) => Left(failure), (_) => throw Exception());
    } // Perform AI analysis
    final result = await _repository.analyzeAnnotatedImage(
      params.annotatedImage,
      context: params.processingContext,
    );
    return result;
  }

  /// Validates the use case parameters
  Either<Failure, void> _validateParams(AnalyzeAnnotatedImageParams params) {
    // Check if image has annotations
    if (params.annotatedImage.annotations.isEmpty) {
      return const Left(
        ValidationFailure(
            'No objects marked for analysis. Please mark objects to remove.'),
      );
    }

    // Check if image data exists
    final imageBytes = params.annotatedImage.originalImage.bytes;
    if (imageBytes == null || imageBytes.isEmpty) {
      return const Left(
        ValidationFailure('Image data is empty or missing.'),
      );
    }

    // Check image size constraints (max 7MB for Gemini)
    const maxSizeBytes = 7 * 1024 * 1024; // 7MB
    if (imageBytes.length > maxSizeBytes) {
      return Left(
        ValidationFailure(
          'Image size (${(imageBytes.length / (1024 * 1024)).toStringAsFixed(1)}MB) '
          'exceeds maximum allowed size (7MB).',
        ),
      );
    }

    // Check for minimum number of annotation points
    final totalPoints = params.annotatedImage.annotations
        .fold<int>(0, (sum, stroke) => sum + stroke.points.length);

    if (totalPoints < 2) {
      return const Left(
        ValidationFailure(
            'Insufficient annotation data. Please draw more detailed marks.'),
      );
    }

    return const Right(null);
  }
}

/// Parameters for the analyze annotated image use case
class AnalyzeAnnotatedImageParams {
  const AnalyzeAnnotatedImageParams({
    required this.annotatedImage,
    this.options,
    this.processingContext,
  });

  /// The annotated image to analyze
  final AnnotatedImage annotatedImage;

  /// Optional analysis options
  final AnalysisOptions? options;

  /// Optional processing context with custom system instructions
  final ProcessingContext? processingContext;
}

/// Options for AI analysis
class AnalysisOptions {
  const AnalysisOptions({
    this.prioritizeSpeed = false,
    this.enableDetailedAnalysis = true,
    this.includeConfidenceScores = true,
    this.maxResponseTokens = 1024,
  });

  /// Whether to prioritize speed over accuracy
  final bool prioritizeSpeed;

  /// Whether to include detailed technical analysis
  final bool enableDetailedAnalysis;

  /// Whether to include confidence scores in results
  final bool includeConfidenceScores;

  /// Maximum number of tokens in the AI response
  final int maxResponseTokens;
}

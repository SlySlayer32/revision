import 'dart:typed_data';

import 'package:revision/core/utils/result.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_context.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_result.dart';
import 'package:revision/features/ai_processing/domain/repositories/ai_processing_repository.dart';

/// Use case for processing images with AI
class ProcessImageWithAiUseCase {
  const ProcessImageWithAiUseCase(this._repository);

  final AiProcessingRepository _repository;

  /// Process an image with AI
  Future<Result<ProcessingResult>> call({
    required Uint8List imageData,
    required String userPrompt,
    required ProcessingContext context,
  }) async {
    // Validate inputs
    if (imageData.isEmpty) {
      return const Failure(ProcessingException('Image data cannot be empty'));
    }

    if (userPrompt.trim().isEmpty) {
      return const Failure(ProcessingException('User prompt cannot be empty'));
    }

    // Check if service is available
    final isAvailable = await _repository.isServiceAvailable();
    if (!isAvailable) {
      return const Failure(
          ProcessingException('AI service is currently unavailable'));
    }

    // Process the image
    return _repository.processImage(
      imageData: imageData,
      userPrompt: userPrompt,
      context: context,
    );
  }
}

/// Exception thrown during AI processing
class ProcessingException implements Exception {
  const ProcessingException(this.message);

  final String message;

  @override
  String toString() => 'ProcessingException: $message';
}

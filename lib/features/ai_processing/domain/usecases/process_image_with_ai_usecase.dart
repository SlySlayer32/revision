import 'package:revision/features/ai_processing/domain/entities/processing_context.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_result.dart';
import 'package:revision/features/ai_processing/domain/repositories/ai_processing_repository.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';

/// Use case for processing images with AI
class ProcessImageWithAiUseCase {
  const ProcessImageWithAiUseCase(this._repository);

  final AiProcessingRepository _repository;

  /// Process an image with AI using the provided prompt and context
  Stream<ProcessingProgress> call({
    required SelectedImage image,
    required String userPrompt,
    required ProcessingContext context,
  }) {
    return _repository.processImage(
      image: image,
      userPrompt: userPrompt,
      context: context,
    );
  }

  /// Cancel any ongoing processing
  Future<void> cancelProcessing() => _repository.cancelProcessing();

  /// Reset processing state
  Future<void> reset() => _repository.reset();
}

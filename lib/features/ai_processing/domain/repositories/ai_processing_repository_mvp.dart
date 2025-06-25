import 'package:revision/features/ai_processing/domain/entities/ai_processing_result.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';

/// Simple repository interface for MVP AI processing
abstract class AiProcessingRepositoryMvp {
  /// Process an image and return the result
  Future<AiProcessingResult> processImage(SelectedImage image);

  /// Get processing progress updates
  Stream<double> getProcessingProgress(String processingId);

  /// Get processing history
  Future<List<AiProcessingResult>> getProcessingHistory();
}

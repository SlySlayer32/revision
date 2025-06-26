import 'dart:typed_data';

import 'package:revision/features/ai_processing/domain/entities/processing_context.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_result.dart';
import 'package:revision/features/image_editing/domain/entities/annotated_image.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';

/// Repository interface for AI processing operations
abstract class AiProcessingRepository {
  /// Process an image with AI using the provided context and prompt
  Stream<ProcessingProgress> processImage({
    required SelectedImage image,
    required String userPrompt,
    required ProcessingContext context,
  });

  /// Cancel any ongoing processing
  Future<void> cancelProcessing();

  /// Get processing capabilities
  Future<List<String>> getAvailableCapabilities();

  /// Get processing status
  Future<bool> isProcessing();

  /// Reset repository state
  Future<void> reset();

  /// Analyze an annotated image
  Future<ProcessingResult> analyzeAnnotatedImage(AnnotatedImage annotatedImage);

  /// Process image with specific analysis type
  Future<ProcessingResult> processImageWithAnalysis({
    required Uint8List imageData,
    required String analysisType,
    String? prompt,
  });
}

/// Processing progress information
class ProcessingProgress {
  const ProcessingProgress({
    required this.stage,
    required this.progress,
    this.message,
    this.canCancel = true,
  });

  final ProcessingStage stage;
  final double progress; // 0.0 to 1.0
  final String? message;
  final bool canCancel;

  @override
  String toString() => 'ProcessingProgress(stage: $stage, progress: $progress, message: $message)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProcessingProgress &&
          runtimeType == other.runtimeType &&
          stage == other.stage &&
          progress == other.progress &&
          message == other.message &&
          canCancel == other.canCancel;

  @override
  int get hashCode => stage.hashCode ^ progress.hashCode ^ message.hashCode ^ canCancel.hashCode;
}

/// Processing stages
enum ProcessingStage {
  analyzing,
  generating,
  postProcessing,
  complete,
  error,
}

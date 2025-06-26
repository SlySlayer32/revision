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

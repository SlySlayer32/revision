import 'package:equatable/equatable.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_status.dart';

/// Result of AI image processing
class AiProcessingResult extends Equatable {
  const AiProcessingResult({
    required this.id,
    required this.originalImagePath,
    required this.processedImagePath,
    required this.status,
    required this.processingTimeMs,
    required this.prompt,
    required this.timestamp,
  });

  final String id;
  final String originalImagePath;
  final String processedImagePath;
  final ProcessingStatus status;
  final int processingTimeMs;
  final String prompt;
  final DateTime timestamp;

  @override
  List<Object?> get props => [
        id,
        originalImagePath,
        processedImagePath,
        status,
        processingTimeMs,
        prompt,
        timestamp,
      ];
}

import 'package:equatable/equatable.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_result.dart';

/// Base class for AI processing states
sealed class AiProcessingState extends Equatable {
  const AiProcessingState();

  @override
  List<Object?> get props => [];
}

/// Initial state - no processing has started
final class AiProcessingInitial extends AiProcessingState {
  const AiProcessingInitial();
}

/// Processing is in progress with progress updates
final class AiProcessingInProgress extends AiProcessingState {
  const AiProcessingInProgress({
    required this.progress,
    this.canCancel = true,
  });

  final ProcessingProgress progress;
  final bool canCancel;

  @override
  List<Object?> get props => [progress, canCancel];

  AiProcessingInProgress copyWith({
    ProcessingProgress? progress,
    bool? canCancel,
  }) {
    return AiProcessingInProgress(
      progress: progress ?? this.progress,
      canCancel: canCancel ?? this.canCancel,
    );
  }
}

/// Processing completed successfully
final class AiProcessingSuccess extends AiProcessingState {
  const AiProcessingSuccess({
    required this.result,
    required this.originalImage,
  });

  final ProcessingResult result;
  final SelectedImage originalImage;

  @override
  List<Object?> get props => [result, originalImage];
}

/// Processing failed with error
final class AiProcessingError extends AiProcessingState {
  const AiProcessingError({
    required this.message,
    required this.originalImage,
  });

  final String message;
  final SelectedImage originalImage;

  @override
  List<Object?> get props => [message, originalImage];
}

/// Processing was cancelled by user
final class AiProcessingCancelled extends AiProcessingState {
  const AiProcessingCancelled();
}

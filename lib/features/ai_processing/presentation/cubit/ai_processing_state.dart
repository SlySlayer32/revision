import 'package:equatable/equatable.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_result.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';

/// Base class for all AI processing states
abstract class AiProcessingState extends Equatable {
  const AiProcessingState();

  @override
  List<Object?> get props => [];
}

/// Initial state when no processing has started
class AiProcessingInitial extends AiProcessingState {
  const AiProcessingInitial();
}

/// State when AI processing is in progress
class AiProcessingInProgress extends AiProcessingState {
  const AiProcessingInProgress({
    required this.progress,
    this.canCancel = true,
  });

  final ProcessingProgress progress;
  final bool canCancel;

  @override
  List<Object?> get props => [progress, canCancel];
}

/// State when AI processing has completed successfully
class AiProcessingSuccess extends AiProcessingState {
  const AiProcessingSuccess({
    required this.result,
    required this.originalImage,
  });

  final ProcessingResult result;
  final SelectedImage originalImage;

  @override
  List<Object?> get props => [result, originalImage];
}

/// State when AI processing has failed
class AiProcessingError extends AiProcessingState {
  const AiProcessingError({
    required this.message,
    this.originalImage,
    this.stackTrace,
  });

  final String message;
  final SelectedImage? originalImage;
  final StackTrace? stackTrace;

  @override
  List<Object?> get props => [message, originalImage, stackTrace];
}

/// State when AI processing has been cancelled
class AiProcessingCancelled extends AiProcessingState {
  const AiProcessingCancelled({
    this.originalImage,
  });

  final SelectedImage? originalImage;

  @override
  List<Object?> get props => [originalImage];
}

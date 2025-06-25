import 'package:equatable/equatable.dart';
import 'package:revision/features/image_editing/domain/entities/annotated_image.dart';
import 'package:revision/features/image_editing/domain/entities/annotation_stroke.dart';

/// States for image annotation functionality.
sealed class ImageAnnotationState extends Equatable {
  const ImageAnnotationState();

  @override
  List<Object?> get props => [];
}

/// Initial state - no image loaded for annotation.
final class ImageAnnotationInitial extends ImageAnnotationState {
  const ImageAnnotationInitial();
}

/// Image is ready for annotation.
final class ImageAnnotationReady extends ImageAnnotationState {
  const ImageAnnotationReady({
    required this.annotatedImage,
    this.currentStroke,
    this.isDrawing = false,
  });

  /// The image with current annotations
  final AnnotatedImage annotatedImage;

  /// Currently active stroke being drawn (if any)
  final AnnotationStroke? currentStroke;

  /// Whether user is currently drawing
  final bool isDrawing;

  @override
  List<Object?> get props => [annotatedImage, currentStroke, isDrawing];

  ImageAnnotationReady copyWith({
    AnnotatedImage? annotatedImage,
    AnnotationStroke? currentStroke,
    bool? isDrawing,
    bool clearCurrentStroke = false,
  }) {
    return ImageAnnotationReady(
      annotatedImage: annotatedImage ?? this.annotatedImage,
      currentStroke:
          clearCurrentStroke ? null : (currentStroke ?? this.currentStroke),
      isDrawing: isDrawing ?? this.isDrawing,
    );
  }
}

/// Processing annotation data for AI.
final class ImageAnnotationProcessing extends ImageAnnotationState {
  const ImageAnnotationProcessing({
    required this.annotatedImage,
    required this.progress,
    this.message,
  });

  final AnnotatedImage annotatedImage;
  final double progress; // 0.0 to 1.0
  final String? message;

  @override
  List<Object?> get props => [annotatedImage, progress, message];
}

/// Error occurred during annotation.
final class ImageAnnotationError extends ImageAnnotationState {
  const ImageAnnotationError({
    required this.message,
    this.annotatedImage,
  });

  final String message;
  final AnnotatedImage? annotatedImage;

  @override
  List<Object?> get props => [message, annotatedImage];
}

/// Annotation processing complete, ready for AI processing.
final class ImageAnnotationReadyForAI extends ImageAnnotationState {
  const ImageAnnotationReadyForAI({
    required this.annotatedImage,
  });

  final AnnotatedImage annotatedImage;

  @override
  List<Object?> get props => [annotatedImage];
}

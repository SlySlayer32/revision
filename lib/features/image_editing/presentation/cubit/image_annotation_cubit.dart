import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/features/image_editing/domain/entities/annotated_image.dart';
import 'package:revision/features/image_editing/domain/entities/annotation_point.dart';
import 'package:revision/features/image_editing/domain/entities/annotation_stroke.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';

import 'image_annotation_state.dart';

/// Cubit for managing image annotation functionality.
class ImageAnnotationCubit extends Cubit<ImageAnnotationState> {
  ImageAnnotationCubit() : super(const ImageAnnotationInitial());

  static int _strokeIdCounter = 0;

  /// Generate a unique stroke ID.
  String _generateStrokeId() {
    return 'stroke_${++_strokeIdCounter}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Load an image for annotation.
  void loadImageForAnnotation(SelectedImage selectedImage) {
    try {
      final annotatedImage = AnnotatedImage(
        originalImage: selectedImage,
        annotations: const [],
        createdAt: DateTime.now(),
      );

      emit(ImageAnnotationReady(annotatedImage: annotatedImage));
    } catch (e) {
      emit(ImageAnnotationError(message: 'Failed to load image: $e'));
    }
  }

  /// Start drawing a new stroke.
  void startStroke(AnnotationPoint point) {
    final currentState = state;
    if (currentState is! ImageAnnotationReady) return;
    final newStroke = AnnotationStroke(
      id: _generateStrokeId(),
      points: [point],
      color: const Color(0xFFFF0000).value, // Default marking color (red)
      strokeWidth: 4.0,
      timestamp: DateTime.now(),
    );

    emit(currentState.copyWith(
      currentStroke: newStroke,
      isDrawing: true,
    ));
  }

  /// Add a point to the current stroke.
  void addPointToStroke(AnnotationPoint point) {
    final currentState = state;
    if (currentState is! ImageAnnotationReady ||
        currentState.currentStroke == null) {
      return;
    }

    final updatedStroke = currentState.currentStroke!.addPoint(point);
    emit(currentState.copyWith(currentStroke: updatedStroke));
  }

  /// Finish the current stroke and add it to annotations.
  void finishStroke() {
    final currentState = state;
    if (currentState is! ImageAnnotationReady ||
        currentState.currentStroke == null) {
      return;
    }

    final finishedStroke = currentState.currentStroke!;
    final updatedAnnotatedImage =
        currentState.annotatedImage.addAnnotation(finishedStroke);

    emit(currentState.copyWith(
      annotatedImage: updatedAnnotatedImage,
      isDrawing: false,
      clearCurrentStroke: true,
    ));
  }

  /// Remove a specific annotation stroke.
  void removeAnnotation(String strokeId) {
    final currentState = state;
    if (currentState is! ImageAnnotationReady) return;

    final updatedAnnotatedImage =
        currentState.annotatedImage.removeAnnotation(strokeId);
    emit(currentState.copyWith(annotatedImage: updatedAnnotatedImage));
  }

  /// Clear all annotations.
  void clearAllAnnotations() {
    final currentState = state;
    if (currentState is! ImageAnnotationReady) return;

    final updatedAnnotatedImage =
        currentState.annotatedImage.clearAnnotations();
    emit(currentState.copyWith(annotatedImage: updatedAnnotatedImage));
  }

  /// Update instruction text for AI processing.
  void updateInstructions(String instructions) {
    final currentState = state;
    if (currentState is! ImageAnnotationReady) return;

    final updatedAnnotatedImage = currentState.annotatedImage.copyWith(
      instructions: instructions.isEmpty ? null : instructions,
    );
    emit(currentState.copyWith(annotatedImage: updatedAnnotatedImage));
  }

  /// Process the annotated image and navigate to AI processing.
  Future<void> processAnnotatedImage() async {
    final currentState = state;
    if (currentState is! ImageAnnotationReady) return;

    if (!currentState.annotatedImage.hasAnnotations) {
      emit(const ImageAnnotationError(
        message:
            'Please mark the objects you want to remove before processing.',
      ));
      return;
    }

    try {
      emit(ImageAnnotationProcessing(
        annotatedImage: currentState.annotatedImage,
        progress: 0.0,
        message: 'Preparing annotation data...',
      ));

      // Simulate preparing the data for AI processing
      await Future.delayed(const Duration(milliseconds: 500));
      emit(ImageAnnotationProcessing(
        annotatedImage: currentState.annotatedImage,
        progress: 0.5,
        message: 'Converting annotations to AI markers...',
      ));

      await Future.delayed(const Duration(milliseconds: 500));
      emit(ImageAnnotationProcessing(
        annotatedImage: currentState.annotatedImage,
        progress: 1.0,
        message: 'Ready for AI processing!',
      ));

      // Mark as ready for AI processing navigation
      // The UI will handle navigation to AI processing page
      await Future.delayed(const Duration(milliseconds: 500));
      emit(ImageAnnotationReadyForAI(
        annotatedImage: currentState.annotatedImage,
      ));
    } catch (e) {
      emit(ImageAnnotationError(
        message: 'Failed to process annotations: $e',
        annotatedImage: currentState.annotatedImage,
      ));
    }
  }

  /// Reset to initial state.
  void reset() {
    emit(const ImageAnnotationInitial());
  }
}

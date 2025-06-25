import 'package:equatable/equatable.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';

import 'annotation_stroke.dart';

/// Represents an image with user annotations for AI processing.
class AnnotatedImage extends Equatable {
  const AnnotatedImage({
    required this.originalImage,
    required this.annotations,
    required this.createdAt,
    this.instructions,
  });

  /// The original selected image
  final SelectedImage originalImage;

  /// List of annotation strokes marking objects for removal
  final List<AnnotationStroke> annotations;

  /// When this annotation was created
  final DateTime createdAt;

  /// Optional text instructions for the AI
  final String? instructions;

  @override
  List<Object?> get props =>
      [originalImage, annotations, createdAt, instructions];

  /// Creates a copy with updated annotations
  AnnotatedImage copyWith({
    SelectedImage? originalImage,
    List<AnnotationStroke>? annotations,
    DateTime? createdAt,
    String? instructions,
  }) {
    return AnnotatedImage(
      originalImage: originalImage ?? this.originalImage,
      annotations: annotations ?? this.annotations,
      createdAt: createdAt ?? this.createdAt,
      instructions: instructions ?? this.instructions,
    );
  }

  /// Add an annotation stroke
  AnnotatedImage addAnnotation(AnnotationStroke stroke) {
    return copyWith(annotations: [...annotations, stroke]);
  }

  /// Remove an annotation stroke by ID
  AnnotatedImage removeAnnotation(String strokeId) {
    return copyWith(
      annotations:
          annotations.where((stroke) => stroke.id != strokeId).toList(),
    );
  }

  /// Clear all annotations
  AnnotatedImage clearAnnotations() {
    return copyWith(annotations: []);
  }

  /// Check if there are any annotations
  bool get hasAnnotations => annotations.isNotEmpty;
}

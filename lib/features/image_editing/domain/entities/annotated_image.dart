import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:revision/features/image_editing/domain/entities/annotation_stroke.dart';

class AnnotatedImage extends Equatable {
  const AnnotatedImage({required this.imageBytes, required this.annotations});

  final Uint8List imageBytes;
  final List<AnnotationStroke> annotations;

  @override
  List<Object?> get props => [imageBytes, annotations];

  bool get hasAnnotations => annotations.isNotEmpty;
}

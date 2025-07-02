import 'dart:ui';

import 'package:equatable/equatable.dart';

class AnnotationStroke extends Equatable {
  const AnnotationStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });

  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  @override
  List<Object?> get props => [points, color, strokeWidth];
}

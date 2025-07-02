import 'dart:ui';

import 'package:revision/features/image_editing/domain/entities/annotation_stroke.dart';

class AnnotationConverter {
  static List<Map<String, dynamic>> toListOfMaps(
      List<AnnotationStroke> annotations) {
    return annotations.map((stroke) {
      return {
        'points': stroke.points.map((point) {
          return {'x': point.dx, 'y': point.dy};
        }).toList(),
        'color': stroke.color.value,
        'strokeWidth': stroke.strokeWidth,
      };
    }).toList();
  }
}

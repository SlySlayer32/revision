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

  static String generatePromptFromAnnotations(
      List<AnnotationStroke> annotations, String userPrompt) {
    if (annotations.isEmpty) {
      return userPrompt;
    }

    final promptParts = [userPrompt];
    promptParts.add('The user has marked the following areas:');

    for (var i = 0; i < annotations.length; i++) {
      final stroke = annotations[i];
      final color = stroke.color;
      final colorName =
          '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
      promptParts.add(
          '  - Area ${i + 1}: A stroke with color $colorName and width ${stroke.strokeWidth.toStringAsFixed(2)}');
    }

    return promptParts.join('\n');
  }

  static List<String> annotationsToMarkers(
      List<AnnotationStroke> annotations) {
    return annotations.map((stroke) {
      final color = stroke.color;
      final colorName =
          '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
      return 'Area marked with color $colorName and width ${stroke.strokeWidth.toStringAsFixed(2)}';
    }).toList();
  }
}

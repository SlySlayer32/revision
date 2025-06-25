import 'package:revision/features/ai_processing/domain/entities/processing_context.dart';
import 'package:revision/features/image_editing/domain/entities/annotated_image.dart';
import 'package:revision/features/image_editing/domain/entities/annotation_stroke.dart';

/// Utility to convert annotation data to AI processing markers.
class AnnotationConverter {
  /// Convert an AnnotatedImage to a list of ImageMarkers for AI processing.
  static List<ImageMarker> annotationsToMarkers(AnnotatedImage annotatedImage) {
    print('🔄 AnnotationConverter: Converting ${annotatedImage.annotations.length} annotations to markers');
    
    final markers = <ImageMarker>[];

    for (final stroke in annotatedImage.annotations) {
      print('🔄 Processing stroke: id=${stroke.id}, points=${stroke.points.length}');
      
      // For each stroke, create markers at key points
      // For MVP, we'll create one marker per stroke at the center point
      final centerPoint = _calculateStrokeCenter(stroke);
      
      print('🔄 Calculated center point: x=${centerPoint.x}, y=${centerPoint.y}');

      final marker = ImageMarker(
        id: stroke.id,
        x: centerPoint.x,
        y: centerPoint.y,
        label: 'marked_object',
      );
      
      markers.add(marker);
      print('✅ Created marker: id=${marker.id}, x=${marker.x}, y=${marker.y}, label=${marker.label}');
    }

    print('✅ AnnotationConverter: Generated ${markers.length} markers');
    return markers;
  }

  /// Calculate the center point of a stroke for marker placement.
  static ({double x, double y}) _calculateStrokeCenter(
      AnnotationStroke stroke) {
    if (stroke.points.isEmpty) {
      print('⚠️ AnnotationConverter: Stroke has no points, using default center');
      return (x: 0.5, y: 0.5); // Default center
    }

    // Calculate the average position of all points in the stroke
    double totalX = 0.0;
    double totalY = 0.0;

    for (final point in stroke.points) {
      totalX += point.x;
      totalY += point.y;
    }

    final centerX = totalX / stroke.points.length;
    final centerY = totalY / stroke.points.length;
    
    print('🔄 Calculated center from ${stroke.points.length} points: x=$centerX, y=$centerY');

    return (
      x: centerX,
      y: centerY,
    );
  }

  /// Generate a descriptive prompt based on annotations.
  static String generatePromptFromAnnotations(
    AnnotatedImage annotatedImage, {
    String basePrompt = 'Remove the marked objects from this image',
  }) {
    final markerCount = annotatedImage.annotations.length;

    if (markerCount == 0) {
      return basePrompt;
    }

    final prompt = StringBuffer();
    prompt.writeln(basePrompt);
    prompt.writeln();
    prompt.writeln('Marked areas to remove: $markerCount object(s)');

    // Add any custom instructions if provided
    if (annotatedImage.instructions != null &&
        annotatedImage.instructions!.trim().isNotEmpty) {
      prompt.writeln();
      prompt.writeln('Additional instructions: ${annotatedImage.instructions}');
    }

    prompt.writeln();
    prompt.writeln('Please remove the marked objects while maintaining:');
    prompt.writeln('- Natural background continuity');
    prompt.writeln('- Consistent lighting and shadows');
    prompt.writeln('- Seamless texture matching');
    prompt.writeln('- Overall image quality');

    return prompt.toString();
  }
}

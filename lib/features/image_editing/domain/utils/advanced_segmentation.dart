import 'dart:math' as dart_math;
import 'package:revision/features/image_editing/domain/entities/annotation_stroke.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_context.dart';

/// Advanced object segmentation utilities for better AI processing
class AdvancedSegmentation {
  /// Create enhanced markers with intelligent grouping and size estimation
  static List<ImageMarker> createIntelligentMarkers(
    List<AnnotationStroke> strokes, {
    double groupingThreshold = 0.15, // 15% of image size
    double minimumSize = 0.05, // 5% minimum size
  }) {
    if (strokes.isEmpty) return [];

    // Group nearby strokes into single objects
    final groups = _groupNearbyStrokes(strokes, groupingThreshold);
    final markers = <ImageMarker>[];

    for (int i = 0; i < groups.length; i++) {
      final group = groups[i];
      final boundingBox = _calculateGroupBoundingBox(group);
      final center = _calculateGroupCenter(group);
      
      // Estimate object size based on stroke coverage
      final estimatedSize = _estimateObjectSize(group, boundingBox);
      
      final marker = ImageMarker(
        id: 'object_$i',
        x: center.x,
        y: center.y,
        width: estimatedSize.width,
        height: estimatedSize.height,
        label: 'marked_object_$i',
        description: _generateObjectDescription(group, center, estimatedSize),
      );

      markers.add(marker);
    }

    return markers;
  }

  /// Group nearby strokes that likely belong to the same object
  static List<List<AnnotationStroke>> _groupNearbyStrokes(
    List<AnnotationStroke> strokes,
    double threshold,
  ) {
    final groups = <List<AnnotationStroke>>[];
    final processed = <bool>[for (int i = 0; i < strokes.length; i++) false];

    for (int i = 0; i < strokes.length; i++) {
      if (processed[i]) continue;

      final currentGroup = <AnnotationStroke>[strokes[i]];
      processed[i] = true;

      // Find nearby strokes
      for (int j = i + 1; j < strokes.length; j++) {
        if (processed[j]) continue;

        if (_strokesAreNearby(strokes[i], strokes[j], threshold)) {
          currentGroup.add(strokes[j]);
          processed[j] = true;
        }
      }

      groups.add(currentGroup);
    }

    return groups;
  }

  /// Check if two strokes are close enough to be part of the same object
  static bool _strokesAreNearby(
    AnnotationStroke stroke1,
    AnnotationStroke stroke2,
    double threshold,
  ) {
    final center1 = _calculateStrokeCenter(stroke1);
    final center2 = _calculateStrokeCenter(stroke2);

    final distance = _calculateDistance(center1, center2);
    return distance <= threshold;
  }

  /// Calculate distance between two points
  static double _calculateDistance(
    ({double x, double y}) point1,
    ({double x, double y}) point2,
  ) {
    final dx = point1.x - point2.x;
    final dy = point1.y - point2.y;
    return (dx * dx + dy * dy).sqrt();
  }

  /// Calculate center of a stroke
  static ({double x, double y}) _calculateStrokeCenter(AnnotationStroke stroke) {
    if (stroke.points.isEmpty) return (x: 0.5, y: 0.5);

    double totalX = 0.0;
    double totalY = 0.0;

    for (final point in stroke.points) {
      totalX += point.x;
      totalY += point.y;
    }

    return (
      x: totalX / stroke.points.length,
      y: totalY / stroke.points.length,
    );
  }

  /// Calculate bounding box for a group of strokes
  static ({double left, double top, double right, double bottom}) _calculateGroupBoundingBox(
    List<AnnotationStroke> group,
  ) {
    if (group.isEmpty) return (left: 0.0, top: 0.0, right: 1.0, bottom: 1.0);

    double minX = 1.0;
    double maxX = 0.0;
    double minY = 1.0;
    double maxY = 0.0;

    for (final stroke in group) {
      for (final point in stroke.points) {
        minX = minX < point.x ? minX : point.x;
        maxX = maxX > point.x ? maxX : point.x;
        minY = minY < point.y ? minY : point.y;
        maxY = maxY > point.y ? maxY : point.y;
      }
    }

    return (left: minX, top: minY, right: maxX, bottom: maxY);
  }

  /// Calculate center of a group of strokes
  static ({double x, double y}) _calculateGroupCenter(List<AnnotationStroke> group) {
    if (group.isEmpty) return (x: 0.5, y: 0.5);

    double totalX = 0.0;
    double totalY = 0.0;
    int totalPoints = 0;

    for (final stroke in group) {
      for (final point in stroke.points) {
        totalX += point.x;
        totalY += point.y;
        totalPoints++;
      }
    }

    if (totalPoints == 0) return (x: 0.5, y: 0.5);

    return (
      x: totalX / totalPoints,
      y: totalY / totalPoints,
    );
  }

  /// Estimate object size based on stroke coverage and patterns
  static ({double width, double height}) _estimateObjectSize(
    List<AnnotationStroke> group,
    ({double left, double top, double right, double bottom}) boundingBox,
  ) {
    // Base size from bounding box
    final baseWidth = boundingBox.right - boundingBox.left;
    final baseHeight = boundingBox.bottom - boundingBox.top;

    // Analyze stroke density to estimate actual object size
    final density = _calculateStrokeDensity(group, boundingBox);
    
    // Scale based on density (more strokes = larger object likely)
    final densityMultiplier = (1.0 + density * 0.5).clamp(1.0, 2.0);
    
    // Minimum viable object size
    final minSize = 0.08; // 8% of image
    
    final estimatedWidth = (baseWidth * densityMultiplier).clamp(minSize, 0.5);
    final estimatedHeight = (baseHeight * densityMultiplier).clamp(minSize, 0.5);

    // Add intelligent padding based on object characteristics
    final paddingFactor = _calculatePaddingFactor(group);
    
    return (
      width: (estimatedWidth * paddingFactor).clamp(minSize, 0.8),
      height: (estimatedHeight * paddingFactor).clamp(minSize, 0.8),
    );
  }

  /// Calculate stroke density within bounding box
  static double _calculateStrokeDensity(
    List<AnnotationStroke> group,
    ({double left, double top, double right, double bottom}) boundingBox,
  ) {
    final area = (boundingBox.right - boundingBox.left) * (boundingBox.bottom - boundingBox.top);
    if (area == 0) return 0.0;

    int totalPoints = 0;
    for (final stroke in group) {
      totalPoints += stroke.points.length;
    }

    return (totalPoints / (area * 10000)).clamp(0.0, 1.0); // Normalize to 0-1
  }

  /// Calculate padding factor based on stroke characteristics
  static double _calculatePaddingFactor(List<AnnotationStroke> group) {
    if (group.isEmpty) return 1.2;

    // More complex strokes need more padding
    final avgStrokeLength = group.map((s) => s.points.length).reduce((a, b) => a + b) / group.length;
    
    // Longer strokes = more detailed marking = need more padding
    if (avgStrokeLength > 20) return 1.5; // Complex object
    if (avgStrokeLength > 10) return 1.3; // Medium complexity
    return 1.2; // Simple object
  }

  /// Generate descriptive text for the object
  static String _generateObjectDescription(
    List<AnnotationStroke> group,
    ({double x, double y}) center,
    ({double width, double height}) size,
  ) {
    final position = _getPositionDescription(center);
    final sizeDesc = _getSizeDescription(size);
    final complexity = _getComplexityDescription(group);

    return 'Object to remove: $sizeDesc $complexity object located $position';
  }

  /// Get position description in natural language
  static String _getPositionDescription(({double x, double y}) center) {
    final x = center.x;
    final y = center.y;

    String horizontal;
    if (x < 0.33) horizontal = 'on the left';
    else if (x > 0.67) horizontal = 'on the right';
    else horizontal = 'in the center';

    String vertical;
    if (y < 0.33) vertical = 'top';
    else if (y > 0.67) vertical = 'bottom';
    else vertical = 'middle';

    return '$vertical $horizontal of the image';
  }

  /// Get size description in natural language
  static String _getSizeDescription(({double width, double height}) size) {
    final area = size.width * size.height;
    
    if (area > 0.25) return 'large';
    if (area > 0.1) return 'medium-sized';
    if (area > 0.04) return 'small';
    return 'tiny';
  }

  /// Get complexity description based on stroke analysis
  static String _getComplexityDescription(List<AnnotationStroke> group) {
    if (group.length > 3) return 'complex';
    if (group.length > 1) return 'detailed';
    
    final avgPoints = group.isEmpty ? 0 : 
        group.map((s) => s.points.length).reduce((a, b) => a + b) / group.length;
    
    if (avgPoints > 20) return 'intricate';
    if (avgPoints > 10) return 'detailed';
    return 'simple';
  }

  /// Convert enhanced markers to AI-ready format with rich descriptions
  static List<Map<String, dynamic>> markersToAIFormat(List<ImageMarker> markers) {
    return markers.map((marker) => {
      'x': marker.x,
      'y': marker.y,
      'width': marker.width,
      'height': marker.height,
      'description': marker.description ?? marker.label ?? 'Object to remove',
      'coordinates': {
        'center_x_percent': (marker.x * 100).round(),
        'center_y_percent': (marker.y * 100).round(),
        'width_percent': (marker.width * 100).round(),
        'height_percent': (marker.height * 100).round(),
      },
      'bounding_box': {
        'left': ((marker.x - marker.width / 2) * 100).clamp(0, 100).round(),
        'top': ((marker.y - marker.height / 2) * 100).clamp(0, 100).round(),
        'right': ((marker.x + marker.width / 2) * 100).clamp(0, 100).round(),
        'bottom': ((marker.y + marker.height / 2) * 100).clamp(0, 100).round(),
      },
    }).toList();
  }
}

extension _Math on double {
  double sqrt() => this < 0 ? 0 : dart_math.sqrt(this);
}

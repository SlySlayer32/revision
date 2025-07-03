import 'package:equatable/equatable.dart';
import 'package:revision/features/ai_processing/domain/entities/segmentation_mask.dart';

/// Represents a user-defined marker or AI-detected segmentation on an image
///
/// Can represent either:
/// 1. User-placed markers for manual object selection
/// 2. AI-generated segmentation masks from Gemini 2.5
class ImageMarker extends Equatable {
  const ImageMarker({
    required this.id,
    required this.label,
    this.markerType = MarkerType.userDefined,
    this.boundingBox,
    this.segmentationMask,
    this.confidence,
    this.coordinates,
  });

  final String id;
  final String label;
  final MarkerType markerType;
  
  /// Bounding box for the marker (required for AI-generated markers)
  final BoundingBox2D? boundingBox;
  
  /// Associated segmentation mask (for AI-generated segmentation)
  final SegmentationMask? segmentationMask;
  
  /// Confidence score (for AI-generated markers)
  final double? confidence;
  
  /// Simple x,y coordinates (for user-defined point markers)
  final (double x, double y)? coordinates;

  @override
  List<Object?> get props => [
        id,
        label,
        markerType,
        boundingBox,
        segmentationMask,
        confidence,
        coordinates,
      ];

  /// Factory constructor for user-defined point markers
  factory ImageMarker.userPoint({
    required String id,
    required String label,
    required double x,
    required double y,
  }) {
    return ImageMarker(
      id: id,
      label: label,
      markerType: MarkerType.userDefined,
      coordinates: (x, y),
    );
  }

  /// Factory constructor for AI-generated segmentation
  factory ImageMarker.fromSegmentation({
    required String id,
    required SegmentationMask segmentationMask,
  }) {
    return ImageMarker(
      id: id,
      label: segmentationMask.label,
      markerType: MarkerType.aiSegmentation,
      boundingBox: segmentationMask.boundingBox,
      segmentationMask: segmentationMask,
      confidence: segmentationMask.confidence,
    );
  }

  /// Factory constructor for AI-detected objects with bounding boxes
  factory ImageMarker.fromObjectDetection({
    required String id,
    required String label,
    required BoundingBox2D boundingBox,
    required double confidence,
  }) {
    return ImageMarker(
      id: id,
      label: label,
      markerType: MarkerType.aiDetection,
      boundingBox: boundingBox,
      confidence: confidence,
    );
  }

  /// Convert to map for AI processing (backward compatibility)
  Map<String, dynamic> toAIMap() {
    final map = <String, dynamic>{
      'id': id,
      'label': label,
      'type': markerType.name,
    };

    if (coordinates != null) {
      map['x'] = coordinates!.$1;
      map['y'] = coordinates!.$2;
    }

    if (boundingBox != null) {
      map['box_2d'] = [
        boundingBox!.y0,
        boundingBox!.x0,
        boundingBox!.y1,
        boundingBox!.x1,
      ];
    }

    if (confidence != null) {
      map['confidence'] = confidence;
    }

    if (segmentationMask != null) {
      map['mask'] = segmentationMask!.toJson();
    }

    return map;
  }

  /// Get the center point of this marker
  (double x, double y)? get centerPoint {
    if (coordinates != null) {
      return coordinates;
    } else if (boundingBox != null) {
      return boundingBox!.center;
    }
    return null;
  }

  /// Check if this marker contains a given point
  bool containsPoint(double x, double y, int imageWidth, int imageHeight) {
    switch (markerType) {
      case MarkerType.userDefined:
        if (coordinates == null) return false;
        // Simple distance check for point markers
        const threshold = 20.0; // pixels
        final dx = (coordinates!.$1 - x).abs();
        final dy = (coordinates!.$2 - y).abs();
        return (dx * dx + dy * dy) <= (threshold * threshold);

      case MarkerType.aiDetection:
        if (boundingBox == null) return false;
        final absoluteBox = boundingBox!.toAbsoluteCoordinates(imageWidth, imageHeight);
        return x >= absoluteBox.x0 && x <= absoluteBox.x1 &&
               y >= absoluteBox.y0 && y <= absoluteBox.y1;

      case MarkerType.aiSegmentation:
        if (segmentationMask == null) return false;
        return segmentationMask!.containsPoint(x.round(), y.round(), imageWidth, imageHeight);
    }
  }

  @override
  String toString() {
    switch (markerType) {
      case MarkerType.userDefined:
        return 'UserMarker($id: $label at ${coordinates})';
      case MarkerType.aiDetection:
        return 'AIDetection($id: $label, confidence: ${confidence?.toStringAsFixed(2)})';
      case MarkerType.aiSegmentation:
        return 'AISegmentation($id: $label, confidence: ${confidence?.toStringAsFixed(2)})';
    }
  }
}

/// Extension for BoundingBox2D to support absolute coordinate conversion
extension BoundingBox2DExtension on BoundingBox2D {
  /// Convert normalized coordinates (0-1000) to absolute pixel coordinates
  BoundingBox2D toAbsoluteCoordinates(int imageWidth, int imageHeight) {
    return BoundingBox2D(
      y0: (y0 / 1000) * imageHeight,
      x0: (x0 / 1000) * imageWidth,
      y1: (y1 / 1000) * imageHeight,
      x1: (x1 / 1000) * imageWidth,
    );
  }
}

/// Type of image marker
enum MarkerType {
  /// User-defined marker (point or area selection)
  userDefined,
  
  /// AI-detected object with bounding box
  aiDetection,
  
  /// AI-generated segmentation mask
  aiSegmentation,
}

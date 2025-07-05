import 'dart:math' as math;

import 'package:revision/features/ai_processing/domain/entities/spatial_point.dart';

/// Represents a spatial region containing an object or area of interest
///
/// Used for object detection and spatial analysis results
class SpatialRegion {
  const SpatialRegion({
    required this.id,
    required this.name,
    required this.centerPoint,
    required this.boundingBox,
    required this.confidence,
    this.description,
    this.objectType,
    this.metadata,
  });

  /// Unique identifier for the region
  final String id;

  /// Name or label of the detected object/region
  final String name;

  /// Center point of the region
  final SpatialPoint centerPoint;

  /// Bounding box coordinates
  final SpatialBoundingBox boundingBox;

  /// Confidence score (0.0 to 1.0)
  final double confidence;

  /// Optional description of the region
  final String? description;

  /// Type/category of the object
  final String? objectType;

  /// Additional metadata
  final Map<String, dynamic>? metadata;

  /// Calculates area of the region
  double get area => boundingBox.width * boundingBox.height;

  /// Checks if this region overlaps with another
  bool overlapsWith(SpatialRegion other) {
    return boundingBox.overlapsWith(other.boundingBox);
  }

  /// Calculates overlap percentage with another region
  double overlapPercentage(SpatialRegion other) {
    return boundingBox.overlapPercentage(other.boundingBox);
  }

  /// Checks if a point is within this region
  bool containsPoint(SpatialPoint point) {
    return boundingBox.containsPoint(point);
  }

  /// Gets the spatial relationship to another region
  String getRelationshipTo(SpatialRegion other) {
    final thisCenter = centerPoint;
    final otherCenter = other.centerPoint;

    // Check containment first
    if (boundingBox.contains(other.boundingBox)) {
      return 'contains';
    }
    if (other.boundingBox.contains(boundingBox)) {
      return 'inside';
    }

    // Check relative positions
    final dx = thisCenter.x - otherCenter.x;
    final dy = thisCenter.y - otherCenter.y;

    // Determine primary direction
    if (dy.abs() > dx.abs()) {
      return dy > 0 ? 'below' : 'above';
    } else {
      return dx > 0 ? 'right_of' : 'left_of';
    }
  }

  /// Creates a copy with modified properties
  SpatialRegion copyWith({
    String? id,
    String? name,
    SpatialPoint? centerPoint,
    SpatialBoundingBox? boundingBox,
    double? confidence,
    String? description,
    String? objectType,
    Map<String, dynamic>? metadata,
  }) {
    return SpatialRegion(
      id: id ?? this.id,
      name: name ?? this.name,
      centerPoint: centerPoint ?? this.centerPoint,
      boundingBox: boundingBox ?? this.boundingBox,
      confidence: confidence ?? this.confidence,
      description: description ?? this.description,
      objectType: objectType ?? this.objectType,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'SpatialRegion(id: $id, name: $name, center: $centerPoint, confidence: ${confidence.toStringAsFixed(2)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpatialRegion &&
        other.id == id &&
        other.name == name &&
        other.centerPoint == centerPoint &&
        other.boundingBox == boundingBox &&
        other.confidence == confidence;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, centerPoint, boundingBox, confidence);
  }

  /// Converts to JSON representation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'centerPoint': centerPoint.toJson(),
      'boundingBox': boundingBox.toJson(),
      'confidence': confidence,
      if (description != null) 'description': description,
      if (objectType != null) 'objectType': objectType,
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Creates from JSON representation
  factory SpatialRegion.fromJson(Map<String, dynamic> json) {
    return SpatialRegion(
      id: json['id'] as String,
      name: json['name'] as String,
      centerPoint:
          SpatialPoint.fromJson(json['centerPoint'] as Map<String, dynamic>),
      boundingBox: SpatialBoundingBox.fromJson(
          json['boundingBox'] as Map<String, dynamic>),
      confidence: (json['confidence'] as num).toDouble(),
      description: json['description'] as String?,
      objectType: json['objectType'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// Bounding box for spatial regions
class SpatialBoundingBox {
  const SpatialBoundingBox({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => right - left;
  double get height => bottom - top;
  double get centerX => left + (width / 2);
  double get centerY => top + (height / 2);
  double get area => width * height;

  /// Checks if this bounding box contains another
  bool contains(SpatialBoundingBox other) {
    return left <= other.left &&
        top <= other.top &&
        right >= other.right &&
        bottom >= other.bottom;
  }

  /// Checks if this bounding box overlaps with another
  bool overlapsWith(SpatialBoundingBox other) {
    return left < other.right &&
        right > other.left &&
        top < other.bottom &&
        bottom > other.top;
  }

  /// Calculates overlap percentage with another bounding box
  double overlapPercentage(SpatialBoundingBox other) {
    if (!overlapsWith(other)) return 0.0;

    final overlapLeft = math.max(left, other.left);
    final overlapTop = math.max(top, other.top);
    final overlapRight = math.min(right, other.right);
    final overlapBottom = math.min(bottom, other.bottom);

    final overlapArea =
        (overlapRight - overlapLeft) * (overlapBottom - overlapTop);
    final unionArea = area + other.area - overlapArea;

    return unionArea > 0 ? overlapArea / unionArea : 0.0;
  }

  /// Checks if a point is within this bounding box
  bool containsPoint(SpatialPoint point) {
    return point.x >= left &&
        point.x <= right &&
        point.y >= top &&
        point.y <= bottom;
  }

  /// Expands the bounding box by a given margin
  SpatialBoundingBox expand(double margin) {
    return SpatialBoundingBox(
      left: math.max(0.0, left - margin),
      top: math.max(0.0, top - margin),
      right: math.min(1.0, right + margin),
      bottom: math.min(1.0, bottom + margin),
    );
  }

  /// Creates a copy with modified properties
  SpatialBoundingBox copyWith({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    return SpatialBoundingBox(
      left: left ?? this.left,
      top: top ?? this.top,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
    );
  }

  @override
  String toString() {
    return 'SpatialBoundingBox(left: ${left.toStringAsFixed(3)}, top: ${top.toStringAsFixed(3)}, right: ${right.toStringAsFixed(3)}, bottom: ${bottom.toStringAsFixed(3)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpatialBoundingBox &&
        other.left == left &&
        other.top == top &&
        other.right == right &&
        other.bottom == bottom;
  }

  @override
  int get hashCode {
    return Object.hash(left, top, right, bottom);
  }

  /// Converts to JSON representation
  Map<String, dynamic> toJson() {
    return {
      'left': left,
      'top': top,
      'right': right,
      'bottom': bottom,
    };
  }

  /// Creates from JSON representation
  factory SpatialBoundingBox.fromJson(Map<String, dynamic> json) {
    return SpatialBoundingBox(
      left: (json['left'] as num).toDouble(),
      top: (json['top'] as num).toDouble(),
      right: (json['right'] as num).toDouble(),
      bottom: (json['bottom'] as num).toDouble(),
    );
  }
}

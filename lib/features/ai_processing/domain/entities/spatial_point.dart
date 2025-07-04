/// Represents a point in spatial coordinate system
///
/// Used for marking specific locations in images for spatial analysis
class SpatialPoint {
  const SpatialPoint({
    required this.x,
    required this.y,
    this.label,
    this.confidence,
  });

  /// X coordinate (0.0 to 1.0 as percentage of image width)
  final double x;

  /// Y coordinate (0.0 to 1.0 as percentage of image height)
  final double y;

  /// Optional label for the point
  final String? label;

  /// Confidence score for the point detection
  final double? confidence;

  /// Calculates distance to another point
  double distanceTo(SpatialPoint other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return (dx * dx + dy * dy).abs();
  }

  /// Checks if point is within a rectangular region
  bool isWithinRegion({
    required double left,
    required double top,
    required double right,
    required double bottom,
  }) {
    return x >= left && x <= right && y >= top && y <= bottom;
  }

  /// Creates a copy with modified properties
  SpatialPoint copyWith({
    double? x,
    double? y,
    String? label,
    double? confidence,
  }) {
    return SpatialPoint(
      x: x ?? this.x,
      y: y ?? this.y,
      label: label ?? this.label,
      confidence: confidence ?? this.confidence,
    );
  }

  @override
  String toString() {
    final confidenceStr =
        confidence != null ? ' (${confidence!.toStringAsFixed(2)})' : '';
    final labelStr = label != null ? ' "$label"' : '';
    return 'SpatialPoint(${x.toStringAsFixed(3)}, ${y.toStringAsFixed(3)})$labelStr$confidenceStr';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpatialPoint &&
        other.x == x &&
        other.y == y &&
        other.label == label &&
        other.confidence == confidence;
  }

  @override
  int get hashCode {
    return Object.hash(x, y, label, confidence);
  }

  /// Converts to JSON representation
  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      if (label != null) 'label': label,
      if (confidence != null) 'confidence': confidence,
    };
  }

  /// Creates from JSON representation
  factory SpatialPoint.fromJson(Map<String, dynamic> json) {
    return SpatialPoint(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      label: json['label'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
    );
  }
}

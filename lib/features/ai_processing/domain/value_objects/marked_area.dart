/// Type-safe representation of a marked area for object removal
///
/// Provides validation and serialization for marked areas to replace
/// the generic Map<String, dynamic> usage
class MarkedArea {
  const MarkedArea({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.description,
  });

  /// X coordinate (normalized 0.0 to 1.0)
  final double x;
  
  /// Y coordinate (normalized 0.0 to 1.0)
  final double y;
  
  /// Width (normalized 0.0 to 1.0)
  final double width;
  
  /// Height (normalized 0.0 to 1.0)
  final double height;
  
  /// Optional description of the marked area
  final String? description;

  /// Creates a MarkedArea from a map with validation
  factory MarkedArea.fromMap(Map<String, dynamic> map) {
    return MarkedArea(
      x: (map['x'] as num?)?.toDouble() ?? 0.0,
      y: (map['y'] as num?)?.toDouble() ?? 0.0,
      width: (map['width'] as num?)?.toDouble() ?? 0.0,
      height: (map['height'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] as String?,
    );
  }

  /// Converts to a map for serialization
  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      if (description != null) 'description': description,
    };
  }

  /// Validates that the marked area has valid dimensions
  bool get isValid {
    return x >= 0.0 && x <= 1.0 &&
           y >= 0.0 && y <= 1.0 &&
           width > 0.0 && width <= 1.0 &&
           height > 0.0 && height <= 1.0 &&
           (x + width) <= 1.0 &&
           (y + height) <= 1.0;
  }

  /// Gets the area as a percentage of the total image
  double get areaPercentage => width * height;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is MarkedArea &&
        other.x == x &&
        other.y == y &&
        other.width == width &&
        other.height == height &&
        other.description == description;
  }

  @override
  int get hashCode {
    return x.hashCode ^
        y.hashCode ^
        width.hashCode ^
        height.hashCode ^
        description.hashCode;
  }

  @override
  String toString() {
    return 'MarkedArea(x: $x, y: $y, width: $width, height: $height, description: $description)';
  }
}

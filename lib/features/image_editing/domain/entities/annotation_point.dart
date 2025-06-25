import 'package:equatable/equatable.dart';

/// Represents a point in an annotation path.
class AnnotationPoint extends Equatable {
  const AnnotationPoint({
    required this.x,
    required this.y,
    this.pressure = 1.0,
  });

  /// X coordinate (0.0 to 1.0, normalized to image dimensions)
  final double x;

  /// Y coordinate (0.0 to 1.0, normalized to image dimensions)
  final double y;

  /// Pressure of the touch (for variable line width)
  final double pressure;

  @override
  List<Object?> get props => [x, y, pressure];

  /// Convert to absolute coordinates based on image dimensions
  AnnotationPoint toAbsolute(double imageWidth, double imageHeight) {
    return AnnotationPoint(
      x: x * imageWidth,
      y: y * imageHeight,
      pressure: pressure,
    );
  }

  /// Create from absolute coordinates
  factory AnnotationPoint.fromAbsolute(
    double absoluteX,
    double absoluteY,
    double imageWidth,
    double imageHeight, {
    double pressure = 1.0,
  }) {
    return AnnotationPoint(
      x: absoluteX / imageWidth,
      y: absoluteY / imageHeight,
      pressure: pressure,
    );
  }
}

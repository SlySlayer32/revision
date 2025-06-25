import 'package:equatable/equatable.dart';
import 'annotation_point.dart';

/// Represents a stroke/path drawn by the user to mark objects for removal.
class AnnotationStroke extends Equatable {
  const AnnotationStroke({
    required this.id,
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.timestamp,
  });

  /// Unique identifier for this stroke
  final String id;

  /// List of points that make up this stroke
  final List<AnnotationPoint> points;

  /// Color of the stroke (for UI display)
  final int color; // Color.value

  /// Width of the stroke
  final double strokeWidth;

  /// When this stroke was created
  final DateTime timestamp;

  @override
  List<Object?> get props => [id, points, color, strokeWidth, timestamp];

  /// Creates a copy with updated points
  AnnotationStroke copyWith({
    String? id,
    List<AnnotationPoint>? points,
    int? color,
    double? strokeWidth,
    DateTime? timestamp,
  }) {
    return AnnotationStroke(
      id: id ?? this.id,
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Add a point to this stroke
  AnnotationStroke addPoint(AnnotationPoint point) {
    return copyWith(points: [...points, point]);
  }
}

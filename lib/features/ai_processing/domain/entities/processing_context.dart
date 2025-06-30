import 'package:equatable/equatable.dart';

/// Represents the context for AI image processing
class ProcessingContext extends Equatable {
  const ProcessingContext({
    required this.processingType,
    required this.qualityLevel,
    required this.performancePriority,
    this.markers = const [],
    this.customInstructions,
    this.targetFormat,
    this.promptSystemInstructions,
    this.editSystemInstructions,
  });

  final ProcessingType processingType;
  final QualityLevel qualityLevel;
  final PerformancePriority performancePriority;
  final List<ImageMarker> markers;
  final String? customInstructions;
  final String? targetFormat;

  /// Custom system instructions for the prompt generation AI model (Gemini)
  final String? promptSystemInstructions;

  /// Custom system instructions for the image editing AI model (Imagen)
  final String? editSystemInstructions;
  @override
  List<Object?> get props => [
        processingType,
        qualityLevel,
        performancePriority,
        markers,
        customInstructions,
        targetFormat,
        promptSystemInstructions,
        editSystemInstructions,
      ];
  ProcessingContext copyWith({
    ProcessingType? processingType,
    QualityLevel? qualityLevel,
    PerformancePriority? performancePriority,
    List<ImageMarker>? markers,
    String? customInstructions,
    String? targetFormat,
    String? promptSystemInstructions,
    String? editSystemInstructions,
  }) {
    return ProcessingContext(
      processingType: processingType ?? this.processingType,
      qualityLevel: qualityLevel ?? this.qualityLevel,
      performancePriority: performancePriority ?? this.performancePriority,
      markers: markers ?? this.markers,
      customInstructions: customInstructions ?? this.customInstructions,
      targetFormat: targetFormat ?? this.targetFormat,
      promptSystemInstructions:
          promptSystemInstructions ?? this.promptSystemInstructions,
      editSystemInstructions:
          editSystemInstructions ?? this.editSystemInstructions,
    );
  }
}

enum ProcessingType {
  enhance,
  artistic,
  restoration,
  colorCorrection,
  objectRemoval,
  backgroundChange,
  faceEdit,
  custom,
}

enum QualityLevel {
  draft,
  standard,
  high,
  professional,
}

enum PerformancePriority {
  speed,
  balanced,
  quality,
}

/// Basic image marker for MVP - simplified version
class ImageMarker extends Equatable {
  const ImageMarker({
    required this.id,
    required this.x,
    required this.y,
    this.width = 0.1, // Default 10% of image width
    this.height = 0.1, // Default 10% of image height
    this.label,
    this.description,
  });

  final String id;
  final double x; // Normalized coordinate (0.0 - 1.0)
  final double y; // Normalized coordinate (0.0 - 1.0)
  final double width; // Normalized width (0.0 - 1.0)
  final double height; // Normalized height (0.0 - 1.0)
  final String? label;
  final String? description;

  @override
  List<Object?> get props => [id, x, y, width, height, label, description];

  /// Convert to the Map format expected by AI pipeline
  Map<String, dynamic> toAIMap() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'description': description ?? label ?? 'Object to remove',
    };
  }

  /// Create a marker from bounding box coordinates
  factory ImageMarker.fromBoundingBox({
    required String id,
    required double left,
    required double top,
    required double right,
    required double bottom,
    String? label,
    String? description,
  }) {
    return ImageMarker(
      id: id,
      x: (left + right) / 2, // Center X
      y: (top + bottom) / 2, // Center Y
      width: right - left,
      height: bottom - top,
      label: label,
      description: description,
    );
  }

  /// Get bounding box coordinates
  ({double left, double top, double right, double bottom}) get boundingBox {
    final halfWidth = width / 2;
    final halfHeight = height / 2;
    return (
      left: (x - halfWidth).clamp(0.0, 1.0),
      top: (y - halfHeight).clamp(0.0, 1.0),
      right: (x + halfWidth).clamp(0.0, 1.0),
      bottom: (y + halfHeight).clamp(0.0, 1.0),
    );
  }
}

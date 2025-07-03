import 'package:equatable/equatable.dart';
import 'package:revision/features/ai_processing/domain/entities/image_marker.dart';

/// Represents the context for AI image processing
/// 
/// This entity defines the complete processing configuration for AI-powered
/// image operations, including quality preferences, performance priorities,
/// and specialized instructions for different AI models.
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
  }) : assert(
         processingType != ProcessingType.custom || 
         (customInstructions != null && customInstructions.length >= 10),
         'Custom processing type requires detailed instructions (min 10 characters)',
       );

  /// Factory constructor for quick enhancement processing
  factory ProcessingContext.quickEnhance() {
    return const ProcessingContext(
      processingType: ProcessingType.enhance,
      qualityLevel: QualityLevel.standard,
      performancePriority: PerformancePriority.speed,
    );
  }

  /// Factory constructor for professional quality editing
  factory ProcessingContext.professionalEdit({
    required ProcessingType type,
    List<ImageMarker> markers = const [],
  }) {
    return ProcessingContext(
      processingType: type,
      qualityLevel: QualityLevel.professional,
      performancePriority: PerformancePriority.quality,
      markers: markers,
    );
  }

  /// Factory constructor for artistic transformations
  factory ProcessingContext.artisticTransform({
    QualityLevel quality = QualityLevel.high,
    String? customStyle,
  }) {
    return ProcessingContext(
      processingType: ProcessingType.artistic,
      qualityLevel: quality,
      performancePriority: PerformancePriority.balanced,
      customInstructions: customStyle,
    );
  }

  /// Factory constructor for restoration tasks
  factory ProcessingContext.restoration() {
    return const ProcessingContext(
      processingType: ProcessingType.restoration,
      qualityLevel: QualityLevel.high,
      performancePriority: PerformancePriority.quality,
    );
  }

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

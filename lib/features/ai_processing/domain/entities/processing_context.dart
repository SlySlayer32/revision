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

  /// Factory constructor for AI-powered segmentation
  factory ProcessingContext.segmentation({
    String? targetObjects,
    double confidenceThreshold = 0.7,
  }) {
    return ProcessingContext(
      processingType: ProcessingType.segmentation,
      qualityLevel: QualityLevel.high,
      performancePriority: PerformancePriority.quality,
      customInstructions: targetObjects != null
          ? 'Segment $targetObjects with confidence threshold $confidenceThreshold'
          : 'Segment all prominent objects with confidence threshold $confidenceThreshold',
    );
  }

  /// Factory constructor for object detection
  factory ProcessingContext.objectDetection({String? targetObjects}) {
    return ProcessingContext(
      processingType: ProcessingType.objectDetection,
      qualityLevel: QualityLevel.standard,
      performancePriority: PerformancePriority.speed,
      customInstructions: targetObjects != null
          ? 'Detect $targetObjects'
          : 'Detect all prominent objects',
    );
  }

  /// The type of processing to be performed
  final ProcessingType processingType;

  /// The desired quality level for the output
  final QualityLevel qualityLevel;

  /// Performance vs quality trade-off preference
  final PerformancePriority performancePriority;

  /// Spatial markers for object selection and region-specific operations
  final List<ImageMarker> markers;

  /// Custom instructions for specialized processing
  final String? customInstructions;

  /// Target output format (e.g., 'JPEG', 'PNG', 'WEBP')
  final String? targetFormat;

  /// Custom system instructions for the prompt generation AI model (Gemini)
  final String? promptSystemInstructions;

  /// Custom system instructions for the image editing AI model (Imagen)
  final String? editSystemInstructions;

  /// Validates if the current context configuration is valid
  bool get isValid {
    // Custom processing requires detailed instructions
    if (processingType == ProcessingType.custom) {
      return customInstructions != null &&
          customInstructions!.trim().length >= 10;
    }

    // Object-specific operations require markers
    if (requiresMarkers && markers.isEmpty) {
      return false;
    }

    // Professional quality with speed priority may be incompatible
    if (qualityLevel == QualityLevel.professional &&
        performancePriority == PerformancePriority.speed) {
      return false;
    }

    return true;
  }

  /// Determines if this processing type requires spatial markers
  bool get requiresMarkers {
    return processingType == ProcessingType.objectRemoval ||
        processingType == ProcessingType.backgroundChange ||
        processingType == ProcessingType.faceEdit;
    // Note: segmentation and objectDetection don't require markers
    // as they generate their own markers through AI detection
  }

  /// Estimates processing time in seconds based on configuration
  int get estimatedProcessingTimeSeconds {
    int baseTime = switch (processingType) {
      ProcessingType.enhance => 5,
      ProcessingType.artistic => 15,
      ProcessingType.restoration => 20,
      ProcessingType.colorCorrection => 8,
      ProcessingType.objectRemoval => 25,
      ProcessingType.backgroundChange => 30,
      ProcessingType.faceEdit => 18,
      ProcessingType.segmentation => 12,
      ProcessingType.objectDetection => 8,
      ProcessingType.custom => 20,
    };

    // Adjust for quality level
    final qualityMultiplier = switch (qualityLevel) {
      QualityLevel.draft => 0.5,
      QualityLevel.standard => 1.0,
      QualityLevel.high => 1.5,
      QualityLevel.professional => 2.0,
    };

    // Adjust for performance priority
    final performanceMultiplier = switch (performancePriority) {
      PerformancePriority.speed => 0.7,
      PerformancePriority.balanced => 1.0,
      PerformancePriority.quality => 1.3,
    };

    return (baseTime * qualityMultiplier * performanceMultiplier).round();
  }

  @override
  String toString() {
    return 'ProcessingContext('
        'type: $processingType, '
        'quality: $qualityLevel, '
        'performance: $performancePriority, '
        'markers: ${markers.length}, '
        'valid: $isValid, '
        'estimatedTime: ${estimatedProcessingTimeSeconds}s'
        ')';
  }

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

/// The type of AI processing to be performed on the image
enum ProcessingType {
  /// Basic image enhancement (brightness, contrast, sharpening)
  enhance,

  /// Artistic style transfer and creative transformations
  artistic,

  /// Photo restoration and damage repair
  restoration,

  /// Color correction and white balance adjustments
  colorCorrection,

  /// Remove unwanted objects from the image
  objectRemoval,

  /// Replace or modify the background
  backgroundChange,

  /// Edit facial features or expressions
  faceEdit,

  /// AI-powered object segmentation with masks
  segmentation,

  /// Object detection with bounding boxes
  objectDetection,

  /// Custom processing with user-defined instructions
  custom,
}

/// The desired quality level for the output image
enum QualityLevel {
  /// Fast, lower quality for previews
  draft,

  /// Balanced quality for most use cases
  standard,

  /// High quality for important images
  high,

  /// Maximum quality for professional use
  professional,
}

/// Performance vs quality trade-off preference
enum PerformancePriority {
  /// Prioritize fast processing over quality
  speed,

  /// Balance between speed and quality
  balanced,

  /// Prioritize quality over processing speed
  quality,
}

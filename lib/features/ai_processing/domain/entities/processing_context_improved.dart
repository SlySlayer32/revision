import 'package:equatable/equatable.dart';
import 'package:revision/features/ai_processing/domain/entities/image_marker.dart';

/// Represents the context for AI image processing operations.
///
/// This entity encapsulates all parameters needed to configure how an AI
/// model should process an image, including quality requirements, performance
/// preferences, and specific processing instructions.
///
/// ## Usage Examples:
/// ```dart
/// // Quick enhancement
/// final context = ProcessingContext.quickEnhance();
///
/// // Professional artistic transformation
/// final context = ProcessingContext.professionalEdit(
///   type: ProcessingType.artistic,
///   customInstructions: 'Apply Van Gogh style',
/// );
/// ```
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

  /// Factory constructor for quick image enhancement
  factory ProcessingContext.quickEnhance({
    List<ImageMarker> markers = const [],
  }) =>
      ProcessingContext(
        processingType: ProcessingType.enhance,
        qualityLevel: QualityLevel.standard,
        performancePriority: PerformancePriority.speed,
        markers: markers,
      );

  /// Factory constructor for professional quality editing
  factory ProcessingContext.professionalEdit({
    required ProcessingType type,
    List<ImageMarker> markers = const [],
    String? customInstructions,
  }) =>
      ProcessingContext(
        processingType: type,
        qualityLevel: QualityLevel.professional,
        performancePriority: PerformancePriority.quality,
        markers: markers,
        customInstructions: customInstructions,
      );

  /// Factory constructor for artistic transformations
  factory ProcessingContext.artisticTransform({
    ProcessingType type = ProcessingType.artistic,
    QualityLevel quality = QualityLevel.high,
    List<ImageMarker> markers = const [],
    String? customInstructions,
  }) =>
      ProcessingContext(
        processingType: type,
        qualityLevel: quality,
        performancePriority: PerformancePriority.balanced,
        markers: markers,
        customInstructions: customInstructions,
      );

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

  /// Validates if the combination of processing parameters is valid
  static bool _isValidCombination(
    ProcessingType type,
    QualityLevel quality,
    PerformancePriority priority,
  ) {
    // Face editing should not use speed priority due to quality requirements
    if (type == ProcessingType.faceEdit &&
        priority == PerformancePriority.speed) {
      return false;
    }

    // Professional quality should not be paired with speed priority
    if (quality == QualityLevel.professional &&
        priority == PerformancePriority.speed) {
      return false;
    }

    // Restoration requires at least standard quality
    if (type == ProcessingType.restoration && quality == QualityLevel.draft) {
      return false;
    }

    return true;
  }

  /// Returns true if this context requires spatial markers
  bool get requiresMarkers {
    return processingType == ProcessingType.objectRemoval ||
        processingType == ProcessingType.backgroundChange ||
        processingType == ProcessingType.faceEdit;
  }

  /// Returns true if the context configuration is valid for processing
  bool get isValid {
    // Check if markers are required but missing
    if (requiresMarkers && markers.isEmpty) {
      return false;
    }

    // Check if custom instructions are too short when required
    if (processingType == ProcessingType.custom &&
        (customInstructions == null ||
            customInstructions!.trim().length < 10)) {
      return false;
    }

    return _isValidCombination(
        processingType, qualityLevel, performancePriority);
  }

  /// Returns estimated processing time in seconds based on configuration
  int get estimatedProcessingTimeSeconds {
    int baseTime = switch (processingType) {
      ProcessingType.enhance => 5,
      ProcessingType.colorCorrection => 8,
      ProcessingType.artistic => 15,
      ProcessingType.restoration => 20,
      ProcessingType.objectRemoval => 25,
      ProcessingType.backgroundChange => 30,
      ProcessingType.faceEdit => 35,
      ProcessingType.custom => 20,
    };

    // Adjust for quality level
    final qualityMultiplier = switch (qualityLevel) {
      QualityLevel.draft => 0.5,
      QualityLevel.standard => 1.0,
      QualityLevel.high => 1.5,
      QualityLevel.professional => 2.5,
    };

    // Adjust for performance priority
    final priorityMultiplier = switch (performancePriority) {
      PerformancePriority.speed => 0.7,
      PerformancePriority.balanced => 1.0,
      PerformancePriority.quality => 1.8,
    };

    return (baseTime * qualityMultiplier * priorityMultiplier).round();
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

  @override
  String toString() {
    return 'ProcessingContext('
        'type: $processingType, '
        'quality: $qualityLevel, '
        'priority: $performancePriority, '
        'markers: ${markers.length}, '
        'hasCustomInstructions: ${customInstructions != null}, '
        'hasPromptInstructions: ${promptSystemInstructions != null}, '
        'hasEditInstructions: ${editSystemInstructions != null}'
        ')';
  }

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

/// Types of AI image processing operations available.
///
/// Each type represents a different category of image transformation
/// with specific AI model requirements and processing characteristics.
enum ProcessingType {
  /// General image enhancement (brightness, contrast, sharpness)
  /// Typically fast processing with good results for most images
  enhance,

  /// Artistic style transformations and filters
  /// Applies creative styles and artistic effects
  artistic,

  /// Photo restoration and repair
  /// Fixes damage, noise, and quality issues in old photos
  restoration,

  /// Color balance and correction
  /// Adjusts colors, saturation, and white balance
  colorCorrection,

  /// Remove unwanted objects from images
  /// Requires markers to identify objects to remove
  objectRemoval,

  /// Replace or modify image backgrounds
  /// Requires markers to define background areas
  backgroundChange,

  /// Face-specific editing and enhancement
  /// Specialized processing for facial features
  faceEdit,

  /// Custom processing with user-defined parameters
  /// Requires detailed custom instructions
  custom,
}

/// Quality levels for AI processing operations.
///
/// Higher quality levels produce better results but take longer to process
/// and consume more computational resources.
enum QualityLevel {
  /// Fast processing with basic quality
  /// Suitable for quick previews and drafts
  draft,

  /// Balanced quality and speed
  /// Good for most general use cases
  standard,

  /// High quality processing
  /// Better results with longer processing time
  high,

  /// Maximum quality with extensive processing
  /// Best results for final output and professional work
  professional,
}

/// Performance priority settings for processing operations.
///
/// Determines the trade-off between processing speed and output quality.
enum PerformancePriority {
  /// Prioritize fast processing over quality
  /// May use optimized algorithms or reduced iterations
  speed,

  /// Balance between speed and quality
  /// Default setting for most use cases
  balanced,

  /// Prioritize quality over processing speed
  /// Uses more thorough algorithms and iterations
  quality,
}

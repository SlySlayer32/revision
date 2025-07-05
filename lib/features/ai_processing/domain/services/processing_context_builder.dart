import 'package:revision/features/ai_processing/domain/entities/image_marker.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_context.dart';

/// Builder service for creating ProcessingContext instances
///
/// Separates business logic from UI components for better testability
/// and maintainability following VGV Clean Architecture principles.
class ProcessingContextBuilder {
  /// Builds a ProcessingContext with validated parameters
  ///
  /// Takes UI selections and converts them to domain entities.
  /// Validates combinations and applies business rules.
  static ProcessingContext build({
    required ProcessingType type,
    required QualityLevel quality,
    required PerformancePriority priority,
    required List<ImageMarker> markers,
    String? promptInstructions,
    String? editInstructions,
  }) {
    // Apply business rules for quality/priority combinations
    final adjustedQuality = _validateQualitySettings(quality, priority);

    // Ensure processing type matches available markers
    final adjustedType = _validateProcessingType(type, markers);

    return ProcessingContext(
      processingType: adjustedType,
      qualityLevel: adjustedQuality,
      performancePriority: priority,
      markers: markers,
      promptSystemInstructions: promptInstructions,
      editSystemInstructions: editInstructions,
    );
  }

  /// Validates quality settings against performance priority
  ///
  /// Applies business rules for quality/performance combinations:
  /// - Speed priority caps at standard quality
  /// - Professional quality requires quality priority
  static QualityLevel _validateQualitySettings(
    QualityLevel quality,
    PerformancePriority priority,
  ) {
    return switch ((quality, priority)) {
      (QualityLevel.professional, PerformancePriority.speed) =>
        QualityLevel.standard,
      (QualityLevel.high, PerformancePriority.speed) => QualityLevel.standard,
      (QualityLevel.professional, PerformancePriority.balanced) =>
        QualityLevel.high,
      _ => quality,
    };
  }

  /// Validates processing type against available markers
  ///
  /// Ensures processing type is compatible with available data:
  /// - Object removal requires markers
  /// - Background change requires markers for masking
  static ProcessingType _validateProcessingType(
    ProcessingType type,
    List<ImageMarker> markers,
  ) {
    final hasMarkers = markers.isNotEmpty;

    return switch ((type, hasMarkers)) {
      (ProcessingType.objectRemoval, false) => ProcessingType.enhance,
      (ProcessingType.backgroundChange, false) => ProcessingType.enhance,
      _ => type,
    };
  }

  /// Gets recommended processing type based on markers
  ///
  /// Suggests appropriate processing type based on available annotation data.
  static ProcessingType getRecommendedType(List<ImageMarker> markers) {
    if (markers.isEmpty) {
      return ProcessingType.enhance;
    }

    // If user has marked objects, suggest object removal
    return ProcessingType.objectRemoval;
  }

  /// Validates if the combination of settings is supported
  ///
  /// Checks if the selected combination is valid for processing.
  static bool isValidCombination({
    required ProcessingType type,
    required QualityLevel quality,
    required PerformancePriority priority,
    required List<ImageMarker> markers,
  }) {
    // Object removal requires markers
    if (type == ProcessingType.objectRemoval && markers.isEmpty) {
      return false;
    }

    // Background change requires markers for masking
    if (type == ProcessingType.backgroundChange && markers.isEmpty) {
      return false;
    }

    // Professional quality with speed priority is not optimal
    if (quality == QualityLevel.professional &&
        priority == PerformancePriority.speed) {
      return false;
    }

    return true;
  }
}

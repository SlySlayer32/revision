import 'package:equatable/equatable.dart';
import 'package:revision/features/ai_processing/domain/entities/segmentation_mask.dart';

/// Result of Gemini 2.5 segmentation operation
///
/// Contains all detected segmentation masks along with metadata
/// about the segmentation process.
class SegmentationResult extends Equatable {
  const SegmentationResult({
    required this.masks,
    required this.processingTimeMs,
    required this.imageWidth,
    required this.imageHeight,
    this.modelVersion = 'gemini-2.5-flash',
    this.confidence = 0.0,
  });

  /// List of detected segmentation masks
  final List<SegmentationMask> masks;

  /// Time taken for segmentation processing in milliseconds
  final int processingTimeMs;

  /// Original image width in pixels
  final int imageWidth;

  /// Original image height in pixels
  final int imageHeight;

  /// Gemini model version used for segmentation
  final String modelVersion;

  /// Overall confidence score for the segmentation result
  final double confidence;

  @override
  List<Object?> get props => [
    masks,
    processingTimeMs,
    imageWidth,
    imageHeight,
    modelVersion,
    confidence,
  ];

  /// Factory constructor from Gemini API JSON response
  factory SegmentationResult.fromJson(
    Map<String, dynamic> json,
    int imageWidth,
    int imageHeight,
    int processingTimeMs,
  ) {
    final masksJson = json['masks'] as List<dynamic>? ?? [];
    final masks = masksJson
        .map(
          (maskJson) =>
              SegmentationMask.fromJson(maskJson as Map<String, dynamic>),
        )
        .toList();

    return SegmentationResult(
      masks: masks,
      processingTimeMs: processingTimeMs,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      modelVersion: json['modelVersion'] as String? ?? 'gemini-2.5-flash',
      confidence:
          (json['confidence'] as num?)?.toDouble() ??
          (masks.isNotEmpty
              ? masks.map((m) => m.confidence).reduce((a, b) => a + b) /
                    masks.length
              : 0.0),
    );
  }

  /// Convert to JSON format
  Map<String, dynamic> toJson() {
    return {
      'masks': masks.map((mask) => mask.toJson()).toList(),
      'processingTimeMs': processingTimeMs,
      'imageWidth': imageWidth,
      'imageHeight': imageHeight,
      'modelVersion': modelVersion,
      'confidence': confidence,
    };
  }

  /// Get masks filtered by label/object type
  List<SegmentationMask> getMasksByLabel(String label) {
    return masks
        .where((mask) => mask.label.toLowerCase().contains(label.toLowerCase()))
        .toList();
  }

  /// Get masks that overlap with a given point
  List<SegmentationMask> getMasksAtPoint(int x, int y) {
    return masks
        .where((mask) => mask.containsPoint(x, y, imageWidth, imageHeight))
        .toList();
  }

  /// Get the largest mask by area
  SegmentationMask? getLargestMask() {
    if (masks.isEmpty) return null;

    return masks.reduce(
      (a, b) => a.boundingBox.area > b.boundingBox.area ? a : b,
    );
  }

  /// Get masks above a confidence threshold
  List<SegmentationMask> getHighConfidenceMasks({double threshold = 0.7}) {
    return masks.where((mask) => mask.confidence >= threshold).toList();
  }

  /// Get summary statistics
  SegmentationStats get stats {
    if (masks.isEmpty) {
      return const SegmentationStats(
        totalMasks: 0,
        averageConfidence: 0.0,
        uniqueLabels: [],
        totalArea: 0.0,
      );
    }

    final uniqueLabels = masks.map((m) => m.label).toSet().toList();
    final avgConfidence =
        masks.map((m) => m.confidence).reduce((a, b) => a + b) / masks.length;
    final totalArea = masks
        .map((m) => m.boundingBox.area)
        .reduce((a, b) => a + b);

    return SegmentationStats(
      totalMasks: masks.length,
      averageConfidence: avgConfidence,
      uniqueLabels: uniqueLabels,
      totalArea: totalArea,
    );
  }

  @override
  String toString() {
    return 'SegmentationResult(masks: ${masks.length}, '
        'confidence: ${confidence.toStringAsFixed(2)}, '
        'processingTime: ${processingTimeMs}ms)';
  }
}

/// Statistics about a segmentation result
class SegmentationStats extends Equatable {
  const SegmentationStats({
    required this.totalMasks,
    required this.averageConfidence,
    required this.uniqueLabels,
    required this.totalArea,
  });

  final int totalMasks;
  final double averageConfidence;
  final List<String> uniqueLabels;
  final double totalArea;

  @override
  List<Object?> get props => [
    totalMasks,
    averageConfidence,
    uniqueLabels,
    totalArea,
  ];

  @override
  String toString() {
    return 'SegmentationStats(masks: $totalMasks, '
        'avgConfidence: ${averageConfidence.toStringAsFixed(2)}, '
        'labels: ${uniqueLabels.length}, '
        'area: ${totalArea.toStringAsFixed(1)})';
  }
}

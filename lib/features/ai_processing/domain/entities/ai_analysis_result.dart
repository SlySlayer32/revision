import 'package:equatable/equatable.dart';

/// Entity representing the result of AI analysis for image editing preparation.
///
/// This entity contains the analysis results from Vertex AI Gemini model
/// after examining an annotated image for object removal tasks.
class AiAnalysisResult extends Equatable {
  const AiAnalysisResult({
    required this.identifiedObjects,
    required this.editingPrompt,
    required this.confidence,
    required this.processingTimeMs,
    this.technicalNotes,
    this.safetyAssessment,
  });

  /// Objects identified in the marked areas by the AI
  final List<String> identifiedObjects;

  /// Generated prompt optimized for the image editing AI model
  final String editingPrompt;

  /// Confidence score for the analysis (0.0 to 1.0)
  final double confidence;

  /// Time taken for analysis in milliseconds
  final int processingTimeMs;

  /// Additional technical notes or recommendations from the AI
  final String? technicalNotes;

  /// Safety assessment of the content
  final String? safetyAssessment;

  @override
  List<Object?> get props => [
    identifiedObjects,
    editingPrompt,
    confidence,
    processingTimeMs,
    technicalNotes,
    safetyAssessment,
  ];

  /// Returns a formatted summary of identified objects
  String get objectsSummary {
    if (identifiedObjects.isEmpty) return 'No objects identified';
    if (identifiedObjects.length == 1) return identifiedObjects.first;
    if (identifiedObjects.length == 2) {
      return '${identifiedObjects.first} and ${identifiedObjects.last}';
    }
    final lastObject = identifiedObjects.last;
    final otherObjects = identifiedObjects.sublist(
      0,
      identifiedObjects.length - 1,
    );
    return '${otherObjects.join(', ')} and $lastObject';
  }

  /// Returns true if the analysis has high confidence (>= 0.8)
  bool get isHighConfidence => confidence >= 0.8;

  /// Returns true if the analysis processing was fast (< 5 seconds)
  bool get wasFastProcessing => processingTimeMs < 5000;

  @override
  String toString() {
    return 'AiAnalysisResult('
        'objects: $identifiedObjects, '
        'confidence: ${(confidence * 100).toStringAsFixed(1)}%, '
        'processingTime: ${processingTimeMs}ms'
        ')';
  }
}

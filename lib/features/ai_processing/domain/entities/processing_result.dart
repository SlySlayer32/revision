import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Represents the result of AI image processing
class ProcessingResult extends Equatable {
  const ProcessingResult({
    required this.processedImageData,
    required this.originalPrompt,
    required this.enhancedPrompt,
    required this.processingTime,
    this.jobId,
    this.imageAnalysis,
    this.metadata,
  });

  final Uint8List processedImageData;
  final String originalPrompt;
  final String enhancedPrompt;
  final Duration processingTime;
  final String? jobId;
  final ImageAnalysis? imageAnalysis;
  final Map<String, dynamic>? metadata;

  @override
  List<Object?> get props => [
    processedImageData,
    originalPrompt,
    enhancedPrompt,
    processingTime,
    jobId,
    imageAnalysis,
    metadata,
  ];
}

/// Represents the analysis of an image for AI processing
class ImageAnalysis extends Equatable {
  const ImageAnalysis({
    required this.width,
    required this.height,
    required this.format,
    required this.fileSize,
    this.dominantColors = const [],
    this.detectedObjects = const [],
    this.qualityScore,
  });

  final int width;
  final int height;
  final String format;
  final int fileSize;
  final List<String> dominantColors;
  final List<String> detectedObjects;
  final double? qualityScore;

  @override
  List<Object?> get props => [
    width,
    height,
    format,
    fileSize,
    dominantColors,
    detectedObjects,
    qualityScore,
  ];
}

/// Represents progress during AI processing
class ProcessingProgress extends Equatable {
  const ProcessingProgress({
    required this.stage,
    required this.progress,
    this.message,
    this.estimatedTimeRemaining,
  });

  final ProcessingStage stage;
  final double progress; // 0.0 to 1.0
  final String? message;
  final Duration? estimatedTimeRemaining;

  @override
  List<Object?> get props => [stage, progress, message, estimatedTimeRemaining];
}

enum ProcessingStage {
  analyzing,
  promptEngineering,
  aiProcessing,
  postProcessing,
  completed,
}

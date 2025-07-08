import 'dart:typed_data';

import 'package:revision/features/ai_processing/domain/entities/processing_context.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_result.dart';
import 'package:revision/features/ai_processing/domain/entities/prompt_template.dart';

/// Service for analyzing images before AI processing
abstract class ImageAnalysisService {
  Future<ImageAnalysis> analyzeImage(Uint8List imageData);
}

/// Service for prompt engineering and optimization
abstract class PromptEngineeringService {
  Future<String> generateEnhancedPrompt({
    required String userPrompt,
    required ProcessingContext context,
    required ImageAnalysis imageAnalysis,
  });

  Future<List<PromptTemplate>> getTemplatesForContext(
    ProcessingContext context,
  );

  Future<String> optimizePromptForModel({
    required String prompt,
    required String modelName,
    required Map<String, dynamic> modelCapabilities,
  });

  Future<ValidationResult> validatePrompt(String prompt);
}

/// Service for orchestrating the AI processing pipeline
abstract class AiProcessingOrchestratorService {
  Future<ProcessingResult> processImage({
    required Uint8List imageData,
    required String userPrompt,
    required ProcessingContext context,
  });

  Stream<ProcessingProgress> watchProgress(String jobId);

  Future<void> cancelProcessing(String jobId);
}

// Import the ImageAnalysis class
class ImageAnalysis {
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
}

// Import the ValidationResult class
class ValidationResult {
  const ValidationResult({required this.isValid, this.issues = const []});

  final bool isValid;
  final List<ValidationIssue> issues;
}

class ValidationIssue {
  const ValidationIssue({
    required this.type,
    required this.message,
    this.suggestion,
  });

  final ValidationIssueType type;
  final String message;
  final String? suggestion;
}

enum ValidationIssueType { error, warning, info }

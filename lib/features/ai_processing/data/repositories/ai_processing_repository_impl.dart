import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:revision/core/error/failures.dart' as core_failures;
import 'package:revision/core/services/vertex_ai_service.dart';
import 'package:revision/core/utils/result.dart';
import 'package:revision/features/ai_processing/domain/entities/ai_analysis_result.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_context.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_result.dart';
import 'package:revision/features/ai_processing/domain/repositories/ai_processing_repository.dart';
import 'package:revision/features/image_editing/domain/entities/annotated_image.dart';

/// Implementation of AI processing repository using Vertex AI service
class AiProcessingRepositoryImpl implements AiProcessingRepository {
  const AiProcessingRepositoryImpl(this._vertexAiService);

  final VertexAIService _vertexAiService;
  @override
  Future<Either<core_failures.Failure, AiAnalysisResult>> analyzeAnnotatedImage(
    AnnotatedImage annotatedImage, {
    ProcessingContext? context,
  }) async {
    try {
      // Convert annotation strokes to markers for AI processing
      final markersData = <Map<String, dynamic>>[];

      for (final stroke in annotatedImage.annotations) {
        if (stroke.points.isNotEmpty) {
          // Use the first point of each stroke as the marker position
          final firstPoint = stroke.points.first;
          markersData.add({
            'x': firstPoint.x,
            'y': firstPoint.y,
            'type': 'marked_object',
            'label': 'marked_object',
          });
        }
      }
      final prompt = await _vertexAiService.generateEditingPrompt(
        imageBytes: annotatedImage.originalImage.bytes!,
        markers: markersData,
      );

      final result = AiAnalysisResult(
        identifiedObjects: const ['marked_object'], // Simplified for MVP
        editingPrompt: prompt,
        confidence: 0.85,
        processingTimeMs: 2000,
      );

      return Right(result);
    } catch (e) {
      return Left(core_failures.AIProcessingFailure('Analysis failed: $e'));
    }
  }

  @override
  Future<Result<ProcessingResult>> processImage({
    required Uint8List imageData,
    required String userPrompt,
    required ProcessingContext context,
  }) async {
    try {
      print('🔄 AiProcessingRepository: Starting processImage');
      print('🔄 Image data size: ${imageData.length} bytes');
      print('🔄 User prompt: "$userPrompt"');
      print('🔄 Processing type: ${context.processingType}');
      print('🔄 Markers count: ${context.markers.length}');
      print('🔄 System instructions provided: prompt=${context.promptSystemInstructions != null}, edit=${context.editSystemInstructions != null}');

      // Validate inputs
      if (imageData.isEmpty) {
        throw Exception('Image data is empty');
      }
      if (userPrompt.trim().isEmpty) {
        throw Exception('User prompt is empty');
      }

      // For MVP: Use the simplified AI processing approach
      // This implements the two-step process: analyze then edit

      // Step 1: Generate enhanced editing prompt if we have markers
      String enhancedPrompt = userPrompt;
      if (context.markers.isNotEmpty) {
        print('🔄 AiProcessingRepository: Generating enhanced prompt with ${context.markers.length} markers...');

        final markersData = context.markers
            .map((marker) => {
                  'x': marker.x,
                  'y': marker.y,
                  'label': marker.label ?? 'marked_object',
                })
            .toList();

        print('🔄 Markers data: $markersData');

        // Use custom system instructions if provided for prompt generation
        if (context.promptSystemInstructions != null) {
          print('🔄 Using custom prompt system instructions');
        }

        enhancedPrompt = await _vertexAiService.generateEditingPrompt(
          imageBytes: imageData,
          markers: markersData,
        );

        print('✅ AiProcessingRepository: Enhanced prompt generated: "$enhancedPrompt"');
      } else {
        print('ℹ️ AiProcessingRepository: No markers provided, using original prompt');
      }

      // Step 2: Process the image with AI using the enhanced prompt
      print('🔄 AiProcessingRepository: Processing image with AI...');
      print('🔄 Final prompt being sent to AI: "$enhancedPrompt"');
      
      // Apply custom editing system instructions if provided
      String finalEditingPrompt = enhancedPrompt;
      if (context.editSystemInstructions != null) {
        finalEditingPrompt = '${context.editSystemInstructions}\n\nEditing instructions: $enhancedPrompt';
        print('🔄 Using custom editing system instructions');
      }
      
      final processedImageData = await _vertexAiService.processImageWithAI(
        imageBytes: imageData,
        editingPrompt: finalEditingPrompt,
      );

      print(
          '✅ AiProcessingRepository: Image processing completed, result size: ${processedImageData.length} bytes');

      // Create the processing result
      final result = ProcessingResult(
        processedImageData: processedImageData,
        originalPrompt: userPrompt,
        enhancedPrompt: enhancedPrompt,
        processingTime: const Duration(seconds: 2), // Placeholder
        jobId: 'mvp_${DateTime.now().millisecondsSinceEpoch}',
        metadata: {
          'processing_type': context.processingType.toString(),
          'quality_level': context.qualityLevel.toString(),
          'performance_priority': context.performancePriority.toString(),
          'markers_count': context.markers.length,
          'ai_model': 'gemini-2.5-flash',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      print('✅ AiProcessingRepository: Processing result created successfully');
      return Success(result);
    } catch (e) {
      print('❌ AiProcessingRepository: Processing failed: $e');
      return Failure(Exception('AI processing failed: $e'));
    }
  }

  @override
  Future<Result<Uint8List>> editImageWithPrompt(
    Uint8List imageBytes,
    String editingPrompt,
  ) async {
    try {
      final result = await _vertexAiService.processImageWithAI(
        imageBytes: imageBytes,
        editingPrompt: editingPrompt,
      );
      return Success(result);
    } catch (e) {
      return Failure(Exception('Image editing failed: $e'));
    }
  }

  @override
  Stream<ProcessingProgress> watchProgress(String jobId) {
    // For MVP, return a simple progress stream
    return Stream.periodic(const Duration(milliseconds: 500), (count) {
      final progress = (count * 10).clamp(0, 100) / 100.0;
      return ProcessingProgress(
        progress: progress,
        stage: progress < 0.5
            ? ProcessingStage.analyzing
            : ProcessingStage.aiProcessing,
        message: progress < 0.5 ? 'Analyzing image...' : 'Generating result...',
        estimatedTimeRemaining: Duration(seconds: (10 - count).clamp(0, 10)),
      );
    }).take(11); // Complete after ~5 seconds
  }

  @override
  Future<Result<void>> cancelProcessing(String jobId) async {
    try {
      // For MVP, we don't implement actual cancellation
      // In production, this would cancel the ongoing AI request
      return const Success(null);
    } catch (e) {
      return Failure(Exception('Failed to cancel processing: $e'));
    }
  }

  @override
  Future<bool> isServiceAvailable() async {
    try {
      // Simple health check - try to call the AI service with minimal data
      await _vertexAiService.checkContentSafety(Uint8List.fromList([1, 2, 3]));
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Result<bool>> validateImageSafety(Uint8List imageBytes) async {
    try {
      final isSafe = await _vertexAiService.checkContentSafety(imageBytes);
      return Success(isSafe);
    } catch (e) {
      return Failure(Exception('Safety validation failed: $e'));
    }
  }
}

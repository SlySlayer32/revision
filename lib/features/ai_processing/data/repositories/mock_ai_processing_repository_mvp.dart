import 'dart:async';
import 'dart:math';

import 'package:revision/features/ai_processing/domain/entities/ai_processing_result.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_status.dart';
import 'package:revision/features/ai_processing/domain/repositories/ai_processing_repository_mvp.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';

/// Simple MVP mock for AI processing
class MockAiProcessingRepositoryMvp implements AiProcessingRepositoryMvp {
  @override
  Future<AiProcessingResult> processImage(SelectedImage image) async {
    // Simulate processing time
    final processingTime = 2000 + Random().nextInt(3000);
    await Future.delayed(Duration(milliseconds: processingTime));

    return AiProcessingResult(
      id: 'mvp_${DateTime.now().millisecondsSinceEpoch}',
      originalImagePath: image.path ?? '',
      processedImagePath: image.path ?? '', // Same image for MVP
      status: ProcessingStatus.completed,
      processingTimeMs: processingTime,
      prompt: 'MVP Demo: Enhanced your photo with AI magic!',
      timestamp: DateTime.now(),
    );
  }

  @override
  Stream<double> getProcessingProgress(String processingId) async* {
    for (var i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 200));
      yield i / 100.0;
    }
  }

  @override
  Future<List<AiProcessingResult>> getProcessingHistory() async {
    return [];
  }
}

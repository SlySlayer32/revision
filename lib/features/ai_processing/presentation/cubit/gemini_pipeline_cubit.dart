import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/core/services/gemini_pipeline_service.dart';
import 'package:revision/features/ai_processing/domain/usecases/process_image_with_gemini_usecase.dart';

/// Cubit for managing Gemini AI Pipeline state and operations
///
/// Handles the complete MVP pipeline:
/// 1. Image selection
/// 2. Gemini 2.5 Flash analysis
/// 3. Gemini 2.0 Flash Preview image generation
/// 4. Results display
class GeminiPipelineCubit extends Cubit<GeminiPipelineState> {
  GeminiPipelineCubit(this._processImageWithGeminiUseCase)
      : super(const GeminiPipelineInitial());

  final ProcessImageWithGeminiUseCase _processImageWithGeminiUseCase;

  /// Process an image through the complete Gemini AI Pipeline
  Future<void> processImage(Uint8List imageData) async {
    emit(const GeminiPipelineLoading());

    final result = await _processImageWithGeminiUseCase(imageData);

    result.fold(
      success: (pipelineResult) => emit(GeminiPipelineSuccess(pipelineResult)),
      failure: (exception) {
        String errorMessage = exception.toString();
        
        // Provide helpful error messages for common Firebase AI setup issues
        if (errorMessage.contains('400') || errorMessage.toLowerCase().contains('not initiated')) {
          errorMessage = '''
Firebase AI (Gemini) Setup Required:

1. Enable Gemini AI in Firebase Console:
   - Go to Firebase Console > Project Settings
   - Navigate to "AI" tab
   - Enable "Gemini API" for your project

2. Verify API key configuration in Firebase Console

3. Ensure Firebase AI Logic is properly initialized

Original error: ${exception.toString()}''';
        }
        
        emit(GeminiPipelineError(errorMessage));
      },
    );
  }

  /// Clear the current pipeline state
  void clearPipeline() {
    emit(const GeminiPipelineInitial());
  }
}

/// Base state for Gemini AI Pipeline
abstract class GeminiPipelineState {
  const GeminiPipelineState();
}

/// Initial state - no processing started
class GeminiPipelineInitial extends GeminiPipelineState {
  const GeminiPipelineInitial();
}

/// Loading state - pipeline is processing
class GeminiPipelineLoading extends GeminiPipelineState {
  const GeminiPipelineLoading();
}

/// Success state - pipeline completed successfully
class GeminiPipelineSuccess extends GeminiPipelineState {
  const GeminiPipelineSuccess(this.result);

  final GeminiPipelineResult result;
}

/// Error state - pipeline failed
class GeminiPipelineError extends GeminiPipelineState {
  const GeminiPipelineError(this.message);

  final String message;
}

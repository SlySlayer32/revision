import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/core/services/gemini_pipeline_service.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_context.dart';
import 'package:revision/features/ai_processing/domain/usecases/process_image_with_gemini_usecase.dart';
import 'package:revision/features/ai_processing/presentation/cubit/gemini_pipeline_state.dart';
import 'package:revision/features/image_editing/domain/entities/annotated_image.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';

/// Cubit for managing Gemini AI Pipeline state and operations
///
/// Handles the complete MVP pipeline:
/// 1. Image selection
/// 2. Gemini 2.5 Flash analysis
/// 3. Gemini 2.0 Flash Preview image generation
/// 4. Results display
class GeminiPipelineCubit extends Cubit<GeminiPipelineState> {
  GeminiPipelineCubit(this._processImageWithGeminiUseCase)
      : super(const GeminiPipelineState());

  final ProcessImageWithGeminiUseCase _processImageWithGeminiUseCase;

  /// Process an image through the complete Gemini AI Pipeline
  Future<void> startImageProcessing({
    required SelectedImage selectedImage,
    required String prompt,
    required ProcessingContext processingContext,
    AnnotatedImage? annotatedImage,
  }) async {
    emit(state.copyWith(status: GeminiPipelineStatus.processing, progressMessage: 'Starting analysis...'));

    // Convert ImageMarker objects to the Map format expected by the pipeline
    final markedAreas = processingContext.markers.map((marker) => marker.toAIMap()).toList();

    final result = await _processImageWithGeminiUseCase(selectedImage.bytes,
        markedAreas: markedAreas);

    result.fold(
      success: (pipelineResult) => emit(state.copyWith(
        status: GeminiPipelineStatus.success,
        processingResult: pipelineResult,
      )),
      failure: (exception) {
        String errorMessage = exception.toString();

        // Provide helpful error messages for common Firebase AI setup issues
        if (errorMessage.contains('400') ||
            errorMessage.toLowerCase().contains('not initiated')) {
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

        emit(state.copyWith(status: GeminiPipelineStatus.error, errorMessage: errorMessage));
      },
    );
  }

  /// Clear the current pipeline state
  void clearPipeline() {
    emit(const GeminiPipelineState());
  }
}

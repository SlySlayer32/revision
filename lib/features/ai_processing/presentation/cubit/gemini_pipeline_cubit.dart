import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_context.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_result.dart';
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
    final stopwatch = Stopwatch()..start();
    if (selectedImage.bytes == null) {
      emit(
        state.copyWith(
          status: GeminiPipelineStatus.error,
          errorMessage: 'Selected image data is missing.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: GeminiPipelineStatus.processing,
        progressMessage: 'Analyzing image with Gemini...',
      ),
    );

    final result = await _processImageWithGeminiUseCase(
      selectedImage.bytes!,
      imageName: selectedImage.name,
      // The use case expects a more generic prompt and context structure
      // This might need to be adjusted based on the final use case implementation
      markedAreas: processingContext.markers.map((m) => m.toAIMap()).toList(),
    );

    result.fold(
      success: (pipelineResult) {
        // The result from the use case is GeminiPipelineResult, which needs to be
        // adapted to the ProcessingResult expected by the state.
        final processingResult = ProcessingResult(
          processedImageData: pipelineResult.generatedImage,
          originalPrompt: prompt,
          enhancedPrompt: pipelineResult.analysisPrompt,
          processingTime: stopwatch.elapsed,
        );
        emit(
          state.copyWith(
            status: GeminiPipelineStatus.success,
            processingResult: processingResult,
          ),
        );
      },
      failure: (exception) {
        String errorMessage = exception.toString();

        if (errorMessage.contains('400') ||
            errorMessage.toLowerCase().contains('not initiated')) {
          errorMessage = '''
Firebase AI (Gemini) Setup Required:

1. Enable Gemini AI in Firebase Console.
2. Verify API key configuration.
3. Ensure Firebase AI Logic is properly initialized.

Original error: ${exception.toString()}''';
        }

        emit(
          state.copyWith(
            status: GeminiPipelineStatus.error,
            errorMessage: errorMessage,
          ),
        );
      },
    );
  }

  /// Clear the current pipeline state
  void clearPipeline() {
    emit(const GeminiPipelineState());
  }
}

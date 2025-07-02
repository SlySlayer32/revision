import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_context.dart';
import 'package:revision/features/ai_processing/presentation/cubit/gemini_pipeline_cubit.dart';
import 'package:revision/features/ai_processing/presentation/widgets/processing_controls.dart';
import 'package:revision/features/ai_processing/presentation/widgets/processing_status_display.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';
import 'package:revision/features/image_selection/presentation/cubit/image_selection_cubit.dart';
import 'package:revision/features/image_selection/presentation/cubit/image_selection_state.dart';

/// Main view for AI processing functionality.
///
/// This view provides the complete AI processing experience including
/// image preview, controls, progress tracking, and results display.
class AiProcessingView extends StatelessWidget {
  const AiProcessingView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Wire this up once ImageEditorCubit is available
    const annotatedImage = null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI-Powered Revision'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocBuilder<ImageSelectionCubit, ImageSelectionState>(
          builder: (context, state) {
            if (state is ImageSelectionLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ImageSelectionSuccess) {
              final selectedImage = state.selectedImage;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Expanded(
                          child: Image.memory(
                            selectedImage.bytes!,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const ProcessingStatusDisplay(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 1,
                    child: ProcessingControls(
                      selectedImage: selectedImage,
                      annotatedImage: annotatedImage,
                      onStartProcessing: (prompt, processingContext) {
                        context.read<GeminiPipelineCubit>().startImageProcessing(
                              selectedImage: selectedImage,
                              prompt: prompt,
                              annotatedImage: annotatedImage,
                              processingContext: processingContext,
                            );
                      },
                    ),
                  ),
                ],
              );
            } else if (state is ImageSelectionError) {
              return Center(
                child: Text('Error selecting image: ${state.message}'),
              );
            } else {
              return const Center(
                child: Text('Select an image to begin.'),
              );
            }
          },
        ),
      ),
    );
  }
}

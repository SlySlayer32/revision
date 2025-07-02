import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/core/di/service_locator.dart';
import 'package:revision/core/services/gemini_pipeline_service.dart';
import 'package:revision/features/ai_processing/data/services/ai_result_save_service.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_context.dart';
import 'package:revision/features/ai_processing/presentation/cubit/gemini_pipeline_cubit.dart';
import 'package:revision/features/ai_processing/presentation/widgets/processing_controls.dart';
import 'package:revision/features/ai_processing/presentation/widgets/processing_status_display.dart';
import 'package:revision/features/image_editing/presentation/cubit/image_editing_cubit.dart';
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
    final annotatedImage =
        context.watch<ImageEditingCubit>().state.annotatedImage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI-Powered Revision'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocBuilder<ImageSelectionCubit, ImageSelectionState>(
          builder: (context, state) {
            if (state.status == ImageSelectionStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state.selectedImage == null) {
              return const Center(
                child: Text('Select an image to begin.'),
              );
            }

            final selectedImage = state.selectedImage!;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side: Image and status
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

                // Right side: Controls
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
          },
        ),
      ),
    );
  }
}

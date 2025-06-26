import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/core/services/gemini_pipeline_service.dart';
import 'package:revision/features/ai_processing/presentation/cubit/gemini_pipeline_cubit.dart';
import 'package:revision/features/image_editing/domain/entities/annotated_image.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';

/// Main view for AI processing functionality.
///
/// This view provides the complete AI processing experience including
/// image preview, controls, progress tracking, and results display.
class AiProcessingView extends StatelessWidget {
  const AiProcessingView({
    required this.selectedImage,
    this.annotatedImage,
    super.key,
  });

  final SelectedImage selectedImage;
  final AnnotatedImage? annotatedImage;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AiProcessingCubit, AiProcessingState>(
      listener: (context, state) {
        switch (state) {
          case AiProcessingError():
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Processing failed: ${state.message}'),
                backgroundColor: Theme.of(context).colorScheme.error,
                action: SnackBarAction(
                  label: 'Retry',
                  onPressed: () => context.read<AiProcessingCubit>().reset(),
                ),
              ),
            );
          case AiProcessingSuccess():
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Processing completed successfully!'),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
          case AiProcessingCancelled():
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Processing was cancelled'),
              ),
            );
          default:
            break;
        }
      },
      builder: (context, state) {
        return Column(
          children: [
            // Image preview section
            Expanded(
              flex: 2,
              child: _buildImagePreview(context, state),
            ),

            // Progress section (shown during processing)
            if (state is AiProcessingInProgress)
              Expanded(
                child: ProcessingProgressIndicator(progress: state.progress),
              ),

            // Controls section
            Expanded(
              child: _buildControls(context, state),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImagePreview(BuildContext context, AiProcessingState state) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: switch (state) {
        AiProcessingSuccess() => ProcessingResultDisplay(
            result: state.result,
            originalImage: state.originalImage,
          ),
        _ => ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildImageWidget(),
          ),
      },
    );
  }

  Widget _buildImageWidget() {
    return Builder(
      builder: (context) {
        // Priority 1: Use bytes if available (most reliable for processed images)
        if (selectedImage.bytes != null) {
          return Image.memory(
            selectedImage.bytes!,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                _buildErrorPlaceholder(context),
          );
        }

        // Priority 2: Use file path for local images
        if (selectedImage.path != null) {
          if (selectedImage.path!.startsWith('http')) {
            return Image.network(
              selectedImage.path!,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  _buildErrorPlaceholder(context),
            );
          } else {
            final file = File(selectedImage.path!);
            if (file.existsSync()) {
              return Image.file(
                file,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    _buildErrorPlaceholder(context),
              );
            }
          }
        }

        return _buildErrorPlaceholder(context);
      },
    );
  }

  Widget _buildControls(BuildContext context, AiProcessingState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: switch (state) {
        AiProcessingInitial() ||
        AiProcessingError() ||
        AiProcessingCancelled() =>
          ProcessingControls(
            selectedImage: selectedImage,
            annotatedImage: annotatedImage,
            onStartProcessing: (prompt, processingContext) {
              BlocProvider.of<AiProcessingCubit>(context).processImage(
                image: selectedImage,
                userPrompt: prompt,
                context: processingContext,
              );
            },
          ),
        AiProcessingInProgress() => _buildCancelControls(context, state),
        AiProcessingSuccess() => _buildSuccessControls(context, state),
      },
    );
  }

  Widget _buildCancelControls(
      BuildContext context, AiProcessingInProgress state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          state.progress.message ?? 'Processing...',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        if (state.canCancel)
          ElevatedButton.icon(
            onPressed: () =>
                context.read<AiProcessingCubit>().cancelProcessing(),
            icon: const Icon(Icons.cancel),
            label: const Text('Cancel Processing'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
          ),
      ],
    );
  }

  Widget _buildSuccessControls(
      BuildContext context, AiProcessingSuccess state) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _saveResult(context, state.result),
                icon: const Icon(Icons.save),
                label: const Text('Save Result'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.read<AiProcessingCubit>().reset(),
                icon: const Icon(Icons.refresh),
                label: const Text('Process Again'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back to Selection'),
        ),
      ],
    );
  }

  Widget _buildErrorPlaceholder(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 64,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load image',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveResult(
      BuildContext context, ProcessingResult result) async {
    // TODO: Implement save functionality
    // For MVP, just show a success message
    // Auto-save Git automation test comment
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Save functionality coming soon!'),
      ),
    );
  }
}

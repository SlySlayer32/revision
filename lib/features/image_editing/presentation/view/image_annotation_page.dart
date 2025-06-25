import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/features/ai_processing/presentation/pages/ai_processing_page.dart';
import 'package:revision/features/image_editing/presentation/cubit/image_annotation_cubit.dart';
import 'package:revision/features/image_editing/presentation/cubit/image_annotation_state.dart';
import 'package:revision/features/image_editing/presentation/widgets/interactive_image_annotator.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';

/// Page for annotating images to mark objects for AI removal.
class ImageAnnotationPage extends StatelessWidget {
  const ImageAnnotationPage({
    required this.selectedImage,
    super.key,
  });

  final SelectedImage selectedImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Objects to Remove'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () => _showHelpDialog(context),
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
          ),
        ],
      ),
      body: BlocProvider(
        create: (context) =>
            ImageAnnotationCubit()..loadImageForAnnotation(selectedImage),
        child: BlocListener<ImageAnnotationCubit, ImageAnnotationState>(
          listener: (context, state) {
            if (state is ImageAnnotationError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            } else if (state is ImageAnnotationProcessing &&
                state.progress == 1.0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message ?? 'Processing complete!'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              );
            } else if (state is ImageAnnotationReadyForAI) {
              // Navigate to AI processing page with annotation data
              Navigator.of(context).push(
                AiProcessingPage.route(
                  selectedImage,
                  annotatedImage: state.annotatedImage,
                ),
              );
            }
          },
          child: const _ImageAnnotationView(),
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Mark Objects'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Draw on the objects you want to remove'),
            SizedBox(height: 8),
            Text('2. You can make multiple strokes to mark different objects'),
            SizedBox(height: 8),
            Text('3. Use "Clear All" to start over'),
            SizedBox(height: 8),
            Text('4. Tap "Remove Objects" when you\'re ready'),
            SizedBox(height: 16),
            Text(
              'Tip: Try to mark the entire object you want removed.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _ImageAnnotationView extends StatelessWidget {
  const _ImageAnnotationView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ImageAnnotationCubit, ImageAnnotationState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: switch (state) {
            ImageAnnotationInitial() => const Center(
                child: CircularProgressIndicator(),
              ),
            ImageAnnotationReady(:final annotatedImage) =>
              InteractiveImageAnnotator(
                file: annotatedImage.originalImage.file,
                bytes: annotatedImage.originalImage.bytes,
              ),
            ImageAnnotationProcessing(:final progress, :final message) =>
              _buildProcessingView(context, progress, message),
            ImageAnnotationError(:final message) =>
              _buildErrorView(context, message),
            ImageAnnotationReadyForAI() => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Navigating to AI processing...'),
                  ],
                ),
              ),
          },
        );
      },
    );
  }

  Widget _buildProcessingView(
      BuildContext context, double progress, String? message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message ?? 'Processing...',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            '${(progress * 100).toInt()}%',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }
}

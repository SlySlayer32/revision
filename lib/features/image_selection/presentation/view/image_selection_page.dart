import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/core/di/service_locator.dart';
import 'package:revision/core/navigation/route_factory.dart' as app_routes;
import 'package:revision/core/navigation/route_names.dart';
// import 'package:revision/features/image_editing/presentation/view/image_annotation_page.dart'; // Disabled
import 'package:revision/features/ai_processing/presentation/pages/ai_processing_page.dart';
import 'package:revision/features/image_selection/domain/entities/image_source.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';
import 'package:revision/features/image_selection/presentation/cubit/image_selection_cubit.dart';
import 'package:revision/features/image_selection/presentation/cubit/image_selection_state.dart';
import 'package:revision/features/image_selection/presentation/widgets/selected_image_display.dart';

/// MVP page for image selection functionality.
///
/// This page provides a simple interface for testing image selection
/// from gallery or camera with basic display of selected images.
class ImageSelectionPage extends StatelessWidget {
  const ImageSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Selection MVP'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: BlocProvider(
        create: (context) => getIt<ImageSelectionCubit>(),
        child: const _ImageSelectionView(),
      ),
    );
  }
}

class _ImageSelectionView extends StatelessWidget {
  const _ImageSelectionView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ImageSelectionCubit, ImageSelectionState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Selection buttons
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Select Image Source',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: state is ImageSelectionLoading
                                  ? null
                                  : () => _selectImage(
                                        context,
                                        ImageSource.gallery,
                                      ),
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Gallery'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Status/Result display
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildStateContent(context, state),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStateContent(BuildContext context, ImageSelectionState state) {
    return switch (state) {
      ImageSelectionInitial() => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_outlined,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No image selected',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Tap Gallery to get started',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ImageSelectionLoading() => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Selecting image...'),
            ],
          ),
        ),
      ImageSelectionSuccess(:final selectedImage) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Image Selected',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _clearSelection(context),
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SelectedImageDisplay(selectedImage: selectedImage),
              const SizedBox(height: 16), // Object marking and AI processing
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _navigateToAnnotation(context, selectedImage),
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('Mark Objects & Apply AI'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ImageSelectionError(:final message) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _clearSelection(context),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      _ => const Center(
          child: Text('Unknown state'),
        ),
    };
  }

  void _selectImage(BuildContext context, ImageSource source) {
    context.read<ImageSelectionCubit>().selectImage(source);
  }

  void _clearSelection(BuildContext context) {
    context.read<ImageSelectionCubit>().clearSelection();
  }

  void _navigateToAnnotation(
      BuildContext context, SelectedImage selectedImage) {
    // Navigate to AI processing page with Gemini segmentation
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AiProcessingPage(
          selectedImage: selectedImage,
        ),
      ),
    );
  }
}

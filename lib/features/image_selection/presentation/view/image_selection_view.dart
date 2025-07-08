import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/features/image_selection/domain/entities/image_source.dart';
import 'package:revision/features/image_selection/presentation/cubit/image_selection_cubit.dart';
import 'package:revision/features/image_selection/presentation/cubit/image_selection_state.dart';
import 'package:revision/features/image_selection/presentation/view/image_preview_view.dart';
import 'package:revision/features/image_selection/presentation/widgets/image_source_selector.dart';
import 'package:revision/features/image_selection/presentation/widgets/selected_image_display.dart';

/// Main view for image selection feature.
///
/// This view provides the complete image selection experience,
/// including source selection and image display.
class ImageSelectionView extends StatelessWidget {
  const ImageSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Image'), centerTitle: true),
      body: BlocBuilder<ImageSelectionCubit, ImageSelectionState>(
        builder: (context, state) {
          return Column(
            children: [
              Expanded(child: _buildContent(context, state)),
              if (state is! ImageSelectionSuccess) _buildSelectButton(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ImageSelectionState state) {
    if (state is ImageSelectionLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Selecting image...'),
          ],
        ),
      );
    }

    if (state is ImageSelectionSuccess) {
      return Column(
        children: [
          Expanded(
            child: SelectedImageDisplay(
              selectedImage: state.selectedImage,
              onRemove: () {
                context.read<ImageSelectionCubit>().clearSelection();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ImagePreviewView(
                        file: state.selectedImage.file,
                        bytes: state.selectedImage.bytes,
                        title: 'Preview',
                      ),
                    ),
                  );
                },
                child: const Text('Preview Image'),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      );
    }

    if (state is ImageSelectionError) {
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                state.message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<ImageSelectionCubit>().clearSelection();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    // Initial state
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No image selected',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Tap the button below to select an image',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            _showImageSourceSelector(context);
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Select Image'),
        ),
      ),
    );
  }

  void _showImageSourceSelector(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext bottomSheetContext) {
        return ImageSourceSelector(
          onSourceSelected: (ImageSource source) {
            Navigator.of(bottomSheetContext).pop();
            context.read<ImageSelectionCubit>().selectImage(source);
          },
        );
      },
    );
  }
}

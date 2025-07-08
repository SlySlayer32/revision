import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/image_preview_cubit.dart';
import '../cubit/image_preview_state.dart';

/// A simple page that previews an image using [ImagePreviewCubit].
/// Shows a loading indicator, the image (with memory optimizations), or an error message.
class ImagePreviewView extends StatelessWidget {
  const ImagePreviewView({
    Key? key,
    this.file,
    this.bytes,
    this.title = 'Image Preview',
  }) : super(key: key);

  /// Optional [File] to load and preview.
  final File? file;

  /// Optional raw image bytes to load and preview.
  final Uint8List? bytes;

  /// Title displayed in the AppBar.
  final String title;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ImagePreviewCubit()..loadImage(file: file, bytes: bytes),
      child: Scaffold(
        appBar: AppBar(title: Text(title), centerTitle: true),
        body: BlocBuilder<ImagePreviewCubit, ImagePreviewState>(
          builder: (context, state) {
            if (state is ImagePreviewLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ImagePreviewLoaded) {
              final imageBytes = state.bytes;
              if (imageBytes == null) {
                return const Center(child: Text('No image data to display'));
              }
              return Center(
                child: InteractiveViewer(
                  child: Image.memory(
                    imageBytes,
                    gaplessPlayback: true,
                    fit: BoxFit.contain,
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: MediaQuery.of(context).size.height * 0.6,
                  ),
                ),
              );
            }
            if (state is ImagePreviewError) {
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
                      'Error loading image',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<ImagePreviewCubit>().clearPreview(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            // Initial or fallback state
            return const Center(child: Text('Preparing to load image...'));
          },
        ),
      ),
    );
  }
}

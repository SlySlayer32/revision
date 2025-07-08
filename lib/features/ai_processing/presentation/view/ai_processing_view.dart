import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/features/ai_processing/presentation/cubit/gemini_pipeline_cubit.dart';
import 'package:revision/features/ai_processing/presentation/widgets/ai_segmentation_widget.dart';
import 'package:revision/features/ai_processing/presentation/widgets/processing_controls.dart';
import 'package:revision/features/ai_processing/presentation/widgets/processing_status_display.dart';
import 'package:revision/features/image_editing/domain/entities/annotated_image.dart';
import 'package:revision/features/image_editing/presentation/cubit/image_editor_cubit.dart';
import 'package:revision/features/image_editing/presentation/widgets/annotation_painter.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';

/// Main view for AI processing functionality.
///
/// This view provides the complete AI processing experience including
/// image preview, controls, progress tracking, and results display.
class AiProcessingView extends StatelessWidget {
  const AiProcessingView({required this.image, this.annotatedImage, super.key});

  final SelectedImage image;
  final AnnotatedImage? annotatedImage;

  /// Builds the image widget with proper null safety handling
  Widget _buildImageWidget() {
    if (image.bytes != null) {
      return Image.memory(
        image.bytes!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red,
                ),
                SizedBox(height: 16),
                Text(
                  'Error loading image',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          );
        },
      );
    } else if (image.path != null) {
      return Image.file(
        File(image.path!),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red,
                ),
                SizedBox(height: 16),
                Text(
                  'Error loading image from file',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          );
        },
      );
    } else {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No image data available',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ImageEditorCubit(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AI-Powered Revision'),
          actions: [
            BlocBuilder<ImageEditorCubit, ImageEditorState>(
              builder: (context, state) {
                return IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: state.strokes.isNotEmpty
                      ? () =>
                            context.read<ImageEditorCubit>().clearAnnotations()
                      : null,
                );
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Expanded(
                      child: BlocBuilder<ImageEditorCubit, ImageEditorState>(
                        builder: (context, editorState) {
                          return GestureDetector(
                            onPanStart: (details) {
                              context.read<ImageEditorCubit>().startDrawing(
                                details.localPosition,
                              );
                            },
                            onPanUpdate: (details) {
                              context.read<ImageEditorCubit>().drawing(
                                details.localPosition,
                              );
                            },
                            onPanEnd: (_) {
                              context.read<ImageEditorCubit>().endDrawing();
                            },
                            child: CustomPaint(
                              painter: AnnotationPainter(
                                strokes: editorState.strokes,
                              ),
                              child: _buildImageWidget(),
                            ),
                          );
                        },
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
                child: Column(
                  children: [
                    // AI Segmentation Widget
                    AISegmentationWidget(selectedImage: image),
                    const SizedBox(height: 16),
                    // Traditional Processing Controls
                    Expanded(
                      child: BlocBuilder<ImageEditorCubit, ImageEditorState>(
                        builder: (context, editorState) {
                          final currentAnnotatedImage = annotatedImage ??
                              (image.bytes != null
                                  ? AnnotatedImage(
                                      imageBytes: image.bytes!,
                                      annotations: editorState.strokes,
                                    )
                                  : null);
                          
                          // Only show processing controls if we have image data
                          if (currentAnnotatedImage == null) {
                            return const Center(
                              child: Text(
                                'No image data available for processing',
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }
                          
                          return ProcessingControls(
                            selectedImage: image,
                            annotatedImage: currentAnnotatedImage,
                            onStartProcessing: (prompt, processingContext) {
                              context
                                  .read<GeminiPipelineCubit>()
                                  .startImageProcessing(
                                    selectedImage: image,
                                    prompt: prompt,
                                    annotatedImage: currentAnnotatedImage,
                                    processingContext: processingContext,
                                  );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

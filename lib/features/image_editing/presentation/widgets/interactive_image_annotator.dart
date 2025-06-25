import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/features/image_editing/domain/entities/annotation_point.dart';
import 'package:revision/features/image_editing/presentation/cubit/image_annotation_cubit.dart';
import 'package:revision/features/image_editing/presentation/cubit/image_annotation_state.dart';
import 'package:revision/features/image_editing/presentation/widgets/annotation_painter.dart';

/// Interactive widget for annotating images to mark objects for removal.
class InteractiveImageAnnotator extends StatefulWidget {
  const InteractiveImageAnnotator({
    this.file,
    this.bytes,
    super.key,
  });

  final File? file;
  final Uint8List? bytes;

  @override
  State<InteractiveImageAnnotator> createState() =>
      _InteractiveImageAnnotatorState();
}

class _InteractiveImageAnnotatorState extends State<InteractiveImageAnnotator> {
  final GlobalKey _imageKey = GlobalKey();
  Size _imageSize = Size.zero;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ImageAnnotationCubit, ImageAnnotationState>(
      builder: (context, state) {
        return Column(
          children: [
            // Instructions
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.touch_app,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mark the objects you want to remove by drawing on them',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                  ),
                ],
              ),
            ),

            // Image with annotation overlay
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: Stack(
                      children: [
                        // Image
                        _buildImage(),

                        // Annotation overlay
                        if (state is ImageAnnotationReady)
                          Positioned.fill(
                            child: CustomPaint(
                              key: _imageKey,
                              painter: AnnotationPainter(
                                strokes: state.annotatedImage.annotations,
                                currentStroke: state.currentStroke,
                                imageSize: _imageSize,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Action buttons
            const SizedBox(height: 16),
            _buildActionButtons(state),
          ],
        );
      },
    );
  }

  Widget _buildImage() {
    if (widget.bytes != null) {
      return Image.memory(
        widget.bytes!,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    } else if (widget.file != null) {
      return Image.file(
        widget.file!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    }
    return _buildErrorWidget();
  }

  Widget _buildErrorWidget() {
    return Container(
      height: 200,
      color: Theme.of(context).colorScheme.errorContainer,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(height: 8),
            Text(
              'Error loading image',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ImageAnnotationState state) {
    return Row(
      children: [
        // Clear all button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: state is ImageAnnotationReady &&
                    state.annotatedImage.hasAnnotations
                ? () =>
                    context.read<ImageAnnotationCubit>().clearAllAnnotations()
                : null,
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear All'),
          ),
        ),
        const SizedBox(width: 12),

        // Process button
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: state is ImageAnnotationReady &&
                    state.annotatedImage.hasAnnotations
                ? () =>
                    context.read<ImageAnnotationCubit>().processAnnotatedImage()
                : null,
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('Remove Objects'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _onPanStart(DragStartDetails details) {
    final state = context.read<ImageAnnotationCubit>().state;
    if (state is! ImageAnnotationReady) return;

    _updateImageSize();
    final point = _getAnnotationPoint(details.localPosition);
    if (point != null) {
      context.read<ImageAnnotationCubit>().startStroke(point);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final state = context.read<ImageAnnotationCubit>().state;
    if (state is! ImageAnnotationReady || !state.isDrawing) return;

    final point = _getAnnotationPoint(details.localPosition);
    if (point != null) {
      context.read<ImageAnnotationCubit>().addPointToStroke(point);
    }
  }

  void _onPanEnd(DragEndDetails details) {
    final state = context.read<ImageAnnotationCubit>().state;
    if (state is! ImageAnnotationReady || !state.isDrawing) return;

    context.read<ImageAnnotationCubit>().finishStroke();
  }

  AnnotationPoint? _getAnnotationPoint(Offset localPosition) {
    final RenderBox? renderBox =
        _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;

    final size = renderBox.size;
    if (size.width == 0 || size.height == 0) return null;

    // Convert to normalized coordinates (0.0 to 1.0)
    final normalizedX = (localPosition.dx / size.width).clamp(0.0, 1.0);
    final normalizedY = (localPosition.dy / size.height).clamp(0.0, 1.0);

    return AnnotationPoint(x: normalizedX, y: normalizedY);
  }

  void _updateImageSize() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? renderBox =
          _imageKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        setState(() {
          _imageSize = renderBox.size;
        });
      }
    });
  }
}

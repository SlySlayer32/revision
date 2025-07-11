import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_configuration.dart';
import 'package:revision/features/ai_processing/presentation/cubit/gemini_pipeline_cubit.dart';
import 'package:revision/features/ai_processing/presentation/widgets/ai_segmentation_widget.dart';
import 'package:revision/features/ai_processing/presentation/widgets/processing_controls.dart';
import 'package:revision/features/ai_processing/presentation/widgets/processing_status_display.dart';
import 'package:revision/features/image_editing/domain/entities/annotated_image.dart';
import 'package:revision/features/image_editing/domain/entities/annotation_stroke.dart';
import 'package:revision/features/image_editing/presentation/cubit/image_editor_cubit.dart';
import 'package:revision/features/image_editing/presentation/widgets/annotation_painter.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';
import 'package:revision/core/utils/security_utils.dart';

/// Custom exceptions for AI processing view
abstract class AiProcessingException implements Exception {
  /// The error message describing what went wrong
  final String message;

  /// Optional error code for specific error types
  final String? code;

  /// Creates an [AiProcessingException] with the given [message] and optional [code]
  const AiProcessingException(this.message, [this.code]);

  @override
  String toString() =>
      'AiProcessingException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Exception thrown when image data is invalid or missing
class InvalidImageException extends AiProcessingException {
  /// Creates an [InvalidImageException] with the given [message]
  const InvalidImageException(super.message, [super.code]);
}

/// Exception thrown when image loading fails
class ImageLoadException extends AiProcessingException {
  /// Creates an [ImageLoadException] with the given [message]
  const ImageLoadException(super.message, [super.code]);
}

/// Main view for AI processing functionality.
///
/// This view provides the complete AI processing experience including:
/// - Image preview with annotation capabilities
/// - Interactive drawing controls for object marking
/// - AI segmentation and processing controls
/// - Real-time processing status display
/// - Comprehensive error handling with user-friendly messages
///
/// The view follows clean architecture principles with proper separation of concerns:
/// - Presentation layer handles UI interactions and state management
/// - Domain layer contains business logic and entities
/// - Proper error boundaries and fallback UI states
///
/// Performance optimizations included:
/// - Const constructors for immutable widgets
/// - Proper widget keys for efficient rebuilds
/// - Optimized image loading with error handling
/// - Efficient state management with BLoC pattern
///
/// Accessibility features:
/// - Semantic labels for screen readers
/// - Proper focus management
/// - High contrast error states
/// - Keyboard navigation support
class AiProcessingView extends StatelessWidget {
  /// Creates an [AiProcessingView] with the required [image] and optional [annotatedImage]
  ///
  /// The [image] parameter must not be null and should contain valid image data
  /// The [annotatedImage] parameter is optional and contains previously saved annotations
  /// The [configuration] parameter provides flexible processing configuration
  const AiProcessingView({
    required this.image,
    this.annotatedImage,
    this.configuration,
    super.key,
  });

  /// The selected image to be processed
  ///
  /// Must contain either [bytes] or [path] data for image display
  final SelectedImage image;

  /// Optional previously annotated image data
  ///
  /// If provided, existing annotations will be displayed and can be modified
  final AnnotatedImage? annotatedImage;

  /// Optional processing configuration
  ///
  /// If not provided, default configuration will be used
  final ProcessingConfiguration? configuration;

  /// Gets the current processing configuration
  ProcessingConfiguration get _processingConfig => 
      configuration ?? const ProcessingConfiguration();

  /// Validates that the image contains valid data
  ///
  /// Throws [InvalidImageException] if the image data is invalid
  ///
  /// @throws [InvalidImageException] when image data is missing or invalid
  void _validateImageData() {
    if (image.bytes == null && image.path == null) {
      throw const InvalidImageException(
        'Image data is required but both bytes and path are null',
        'MISSING_IMAGE_DATA',
      );
    }

    if (image.bytes != null && image.bytes!.isEmpty) {
      throw const InvalidImageException(
        'Image bytes are empty',
        'EMPTY_IMAGE_BYTES',
      );
    }

    if (image.path != null && image.path!.isEmpty) {
      throw const InvalidImageException(
        'Image path is empty',
        'EMPTY_IMAGE_PATH',
      );
    }
  }

  /// Validates that the image is ready for API processing with flexible configuration
  ///
  /// Uses the processing configuration to determine validation rules
  /// 
  /// @throws [InvalidImageException] when image data is invalid for API processing
  void _validateImageForProcessing() {
    _validateImageData();

    // Check file size using configuration
    if (image.sizeInBytes > _processingConfig.maxImageSizeBytes) {
      throw InvalidImageException(
        'Image too large for processing. Maximum size: ${_processingConfig.maxImageSizeBytes ~/ (1024 * 1024)}MB',
        'IMAGE_TOO_LARGE',
      );
    }

    // Validate image format using configuration
    final extension = image.name.toLowerCase().split('.').last;
    if (!_processingConfig.isImageFormatSupported(extension)) {
      throw InvalidImageException(
        'Unsupported image format: $extension. Supported formats: ${_processingConfig.supportedImageFormats.join(', ')}',
        'UNSUPPORTED_FORMAT',
      );
    }
  }

  /// Gets the appropriate MIME type for API based on file extension
  ///
  /// Returns the correct MIME type string for the API request
  String _getImageMimeType() {
    final extension = image.name.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      default:
        return 'image/jpeg'; // Default fallback
    }
  }

  /// Checks if the image is optimized for token usage
  ///
  /// Images within configuration limits use fewer tokens
  bool _isOptimizedForTokenUsage() {
    return image.sizeInBytes <= _processingConfig.maxImageDimension * _processingConfig.maxImageDimension * 3;
  }

  /// Builds the image widget with comprehensive error handling and accessibility
  ///
  /// Returns a widget that displays the image with proper error states and fallbacks
  /// Includes accessibility features, performance optimizations, and configuration-based validation
  ///
  /// @param context The build context for theme and localization access
  /// @returns A widget displaying the image or appropriate error state
  Widget _buildImageDisplayWidget(BuildContext context) {
    try {
      _validateImageForProcessing();

      if (image.bytes != null) {
        return _buildMemoryImageWidget(context);
      } else if (image.path != null) {
        return _buildFileImageWidget(context);
      } else {
        return _buildNoImageWidget(context);
      }
    } on InvalidImageException catch (e) {
      return _buildErrorWidget(context, e.message, Icons.broken_image);
    } catch (e) {
      return _buildErrorWidget(
        context,
        'Unexpected error loading image: ${SecurityUtils.maskSensitiveData(e.toString())}',
        Icons.error_outline,
      );
    }
  }

  /// Builds image widget from memory bytes
  Widget _buildMemoryImageWidget(BuildContext context) {
    return Semantics(
      label: 'Selected image for AI processing',
      child: Image.memory(
        image.bytes!,
        key: ValueKey('memory_image_${image.name}'),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget(
            context,
            'Failed to load image from memory',
            Icons.memory,
          );
        },
      ),
    );
  }

  /// Builds image widget from file path
  Widget _buildFileImageWidget(BuildContext context) {
    return Semantics(
      label: 'Selected image file for AI processing',
      child: Image.file(
        File(image.path!),
        key: ValueKey('file_image_${image.path}'),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget(
            context,
            'Failed to load image from file: ${image.path}',
            Icons.folder_open,
          );
        },
      ),
    );
  }

  /// Builds error widget with consistent styling and accessibility
  Widget _buildErrorWidget(
      BuildContext context, String message, IconData icon) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Error loading image: $message',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds widget shown when no image data is available
  Widget _buildNoImageWidget(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'No image data available',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No image data available',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the main image editing area with gesture handling
  Widget _buildImageEditingArea(BuildContext context) {
    return Expanded(
      child: BlocBuilder<ImageEditorCubit, ImageEditorState>(
        builder: (context, editorState) {
          return Semantics(
            label: 'Image editing area - draw to mark objects',
            child: GestureDetector(
              onPanStart: (details) {
                HapticFeedback.lightImpact();
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
                HapticFeedback.selectionClick();
                context.read<ImageEditorCubit>().endDrawing();
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CustomPaint(
                    painter: AnnotationPainter(
                      strokes: editorState.strokes,
                    ),
                    child: _buildImageDisplayWidget(context),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds the clear annotations button with proper state management
  Widget _buildClearAnnotationsButton(BuildContext context) {
    return BlocBuilder<ImageEditorCubit, ImageEditorState>(
      builder: (context, state) {
        final hasAnnotations = state.strokes.isNotEmpty;

        return Semantics(
          label:
              hasAnnotations ? 'Clear annotations' : 'No annotations to clear',
          child: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: hasAnnotations
                ? () {
                    HapticFeedback.mediumImpact();
                    context.read<ImageEditorCubit>().clearAnnotations();
                  }
                : null,
            tooltip: hasAnnotations ? 'Clear annotations' : 'No annotations',
          ),
        );
      },
    );
  }

  /// Creates annotated image with proper error handling
  AnnotatedImage? _createAnnotatedImage(List<AnnotationStroke> strokes) {
    if (image.bytes == null) {
      return null;
    }

    try {
      return AnnotatedImage(
        imageBytes: image.bytes!,
        annotations: strokes,
      );
    } catch (e) {
      // Log error but don't crash the app
      debugPrint('Error creating annotated image: $e');
      return null;
    }
  }

  /// Builds the processing controls section
  Widget _buildProcessingControlsSection(BuildContext context) {
    return Expanded(
      child: BlocBuilder<ImageEditorCubit, ImageEditorState>(
        builder: (context, editorState) {
          final currentAnnotatedImage =
              annotatedImage ?? _createAnnotatedImage(editorState.strokes);

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
              context.read<GeminiPipelineCubit>().startImageProcessing(
                    selectedImage: image,
                    prompt: prompt,
                    annotatedImage: currentAnnotatedImage,
                    processingContext: processingContext,
                  );
            },
          );
        },
      ),
    );
  }

  /// Builds an info widget showing processing configuration and compatibility
  Widget _buildProcessingInfoWidget(BuildContext context) {
    final theme = Theme.of(context);

    try {
      _validateImageForProcessing();
      final config = _processingConfig;

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Processing Ready',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow(context, 'Max Size', '${config.maxImageSizeBytes ~/ (1024 * 1024)}MB'),
            _buildInfoRow(context, 'Current Size', '${image.sizeInMB.toStringAsFixed(2)}MB'),
            _buildInfoRow(context, 'Format', _getImageFormat()),
            _buildInfoRow(context, 'Preprocessing', config.enableImagePreprocessing ? 'Enabled' : 'Disabled'),
            _buildInfoRow(context, 'Cancellation', config.enableCancellation ? 'Supported' : 'Not Supported'),
            _buildInfoRow(context, 'Progress Tracking', config.enableProgressTracking ? 'Enabled' : 'Disabled'),
            if (config.enableImageEncryption) ...[
              _buildInfoRow(context, 'Encryption', 'Enabled'),
            ],
          ],
        ),
      );
    } catch (e) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.error.withOpacity(0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning,
              color: theme.colorScheme.error,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Configuration Issue',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  /// Gets the image format for display
  String _getImageFormat() {
    final extension = image.name.toLowerCase().split('.').last;
    return extension.toUpperCase();
  }

  /// Builds an info row for the API compatibility widget
  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ImageEditorCubit(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AI-Powered Revision'),
          actions: [
            _buildClearAnnotationsButton(context),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Responsive layout based on screen size
                if (constraints.maxWidth > 768) {
                  return _buildWideLayout(context);
                } else {
                  return _buildNarrowLayout(context);
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Builds layout for wide screens (tablets/desktop)
  Widget _buildWideLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildImageEditingArea(context),
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
              _buildProcessingInfoWidget(context),
              const SizedBox(height: 16),
              AISegmentationWidget(
                selectedImage: image,
                key: ValueKey('segmentation_${image.name}'),
              ),
              const SizedBox(height: 16),
              _buildProcessingControlsSection(context),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds layout for narrow screens (mobile)
  Widget _buildNarrowLayout(BuildContext context) {
    return Column(
      children: [
        _buildImageEditingArea(context),
        const SizedBox(height: 16),
        const ProcessingStatusDisplay(),
        const SizedBox(height: 16),
        _buildProcessingInfoWidget(context),
        const SizedBox(height: 16),
        AISegmentationWidget(
          selectedImage: image,
          key: ValueKey('segmentation_${image.name}'),
        ),
        const SizedBox(height: 16),
        _buildProcessingControlsSection(context),
      ],
    );
  }
}

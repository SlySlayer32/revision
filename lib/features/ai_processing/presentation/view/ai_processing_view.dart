import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/core/di/service_locator.dart';
import 'package:revision/core/services/gemini_pipeline_service.dart';
import 'package:revision/debug_gemini.dart';
import 'package:revision/debug_remote_config.dart';
import 'package:revision/features/ai_processing/data/services/ai_result_save_service.dart';
import 'package:revision/features/ai_processing/presentation/cubit/gemini_pipeline_cubit.dart';
import 'package:revision/features/image_editing/domain/entities/annotated_image.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';

/// Main view for AI processing functionality.
///
/// This view provides the complete AI processing experience including
/// image preview, controls, progress tracking, and results display.
class AiProcessingView extends StatefulWidget {
  const AiProcessingView({
    required this.selectedImage,
    this.annotatedImage,
    super.key,
  });

  final SelectedImage selectedImage;
  final AnnotatedImage? annotatedImage;

  @override
  State<AiProcessingView> createState() => _AiProcessingViewState();
}

class _AiProcessingViewState extends State<AiProcessingView> {
  @override
  void initState() {
    super.initState();
    // Run debug tests first, then auto-start processing
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Debug test Remote Config first
      await RemoteConfigDebugTester.testRemoteConfig();
      
      // Then debug test Gemini connection
      await GeminiDebugTester.testGeminiConnection();
      
      // Auto-start processing when page loads if we have image data
      if (widget.selectedImage.bytes != null) {
        context.read<GeminiPipelineCubit>().processImage(widget.selectedImage.bytes!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GeminiPipelineCubit, GeminiPipelineState>(
      listener: (context, state) {
        switch (state) {
          case GeminiPipelineError():
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Processing failed: ${state.message}'),
                backgroundColor: Theme.of(context).colorScheme.error,
                action: SnackBarAction(
                  label: 'Retry',
                  onPressed: () =>
                      context.read<GeminiPipelineCubit>().clearPipeline(),
                ),
              ),
            );
          case GeminiPipelineSuccess():
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Processing completed successfully!'),
                backgroundColor: Theme.of(context).colorScheme.primary,
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
            if (state is GeminiPipelineLoading)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Processing with Gemini AI...'),
                    ],
                  ),
                ),
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

  Widget _buildImagePreview(BuildContext context, GeminiPipelineState state) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: switch (state) {
        GeminiPipelineSuccess() => Row(
            children: [
              // Original image
              Expanded(
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Original',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Expanded(child: _buildImageWidget()),
                  ],
                ),
              ),
              // Generated image
              Expanded(
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Generated',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: Image.memory(state.result.generatedImage,
                          fit: BoxFit.contain),
                    ),
                  ],
                ),
              ),
            ],
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
        if (widget.selectedImage.bytes != null) {
          return Image.memory(
            widget.selectedImage.bytes!,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                _buildErrorPlaceholder(context),
          );
        }

        // Priority 2: Use file path for local images
        if (widget.selectedImage.path != null) {
          if (widget.selectedImage.path!.startsWith('http')) {
            return Image.network(
              widget.selectedImage.path!,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  _buildErrorPlaceholder(context),
            );
          } else {
            final file = File(widget.selectedImage.path!);
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

  Widget _buildControls(BuildContext context, GeminiPipelineState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: switch (state) {
        GeminiPipelineInitial() || GeminiPipelineError() => ElevatedButton(
            onPressed: () {
              if (widget.selectedImage.bytes != null) {
                context
                    .read<GeminiPipelineCubit>()
                    .processImage(widget.selectedImage.bytes!);
              }
            },
            child: const Text('Process with Gemini AI'),
          ),
        GeminiPipelineLoading() => const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Processing...'),
            ],
          ),
        GeminiPipelineSuccess() => Column(
            children: [
              Text('Analysis: ${state.result.analysisPrompt}'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () =>
                        context.read<GeminiPipelineCubit>().clearPipeline(),
                    child: const Text('Process Another'),
                  ),
                  ElevatedButton(
                    onPressed: () => _saveResult(context, state.result),
                    child: const Text('Save Result'),
                  ),
                ],
              ),
            ],
          ),
        _ => const SizedBox.shrink(),
      },
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
      BuildContext context, GeminiPipelineResult result) async {
    try {
      // Show loading state
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Saving AI processed image...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final saveService = getIt<AIResultSaveService>();
      final saveResult = await saveService.saveResultToGallery(result);

      saveResult.fold(
        success: (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'Save Both',
                onPressed: () => _saveWithComparison(context, result),
              ),
            ),
          );
        },
        failure: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Save failed: ${error.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveWithComparison(
      BuildContext context, GeminiPipelineResult result) async {
    try {
      final saveService = getIt<AIResultSaveService>();
      final saveResult = await saveService.saveResultWithComparison(result);

      saveResult.fold(
        success: (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success),
              backgroundColor: Colors.green,
            ),
          );
        },
        failure: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Save failed: ${error.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

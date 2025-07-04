import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_context.dart';
import 'package:revision/features/ai_processing/presentation/cubit/gemini_pipeline_cubit.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';

/// Widget that provides AI-powered object segmentation using Gemini 2.5
///
/// This widget replaces the manual object marking workflow with automated
/// AI segmentation, following the spatial understanding approach from
/// the Gemini Cookbook.
class AISegmentationWidget extends StatefulWidget {
  const AISegmentationWidget({
    required this.selectedImage,
    super.key,
  });

  final SelectedImage selectedImage;

  @override
  State<AISegmentationWidget> createState() => _AISegmentationWidgetState();
}

class _AISegmentationWidgetState extends State<AISegmentationWidget> {
  final TextEditingController _targetObjectsController = TextEditingController();
  double _confidenceThreshold = 0.7;
  bool _isSegmenting = false;

  @override
  void dispose() {
    _targetObjectsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Object Segmentation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Let AI automatically detect and segment objects for precise editing.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            // Target objects input
            TextField(
              controller: _targetObjectsController,
              decoration: const InputDecoration(
                labelText: 'Target Objects (Optional)',
                hintText: 'e.g., "wooden and glass items", "furniture", "people"',
                border: OutlineInputBorder(),
                helperText: 'Leave empty to detect all prominent objects',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            
            // Confidence threshold slider
            Row(
              children: [
                const Text('Confidence Threshold:'),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: _confidenceThreshold,
                    min: 0.3,
                    max: 1.0,
                    divisions: 7,
                    label: '${(_confidenceThreshold * 100).round()}%',
                    onChanged: (value) {
                      setState(() {
                        _confidenceThreshold = value;
                      });
                    },
                  ),
                ),
                Text('${(_confidenceThreshold * 100).round()}%'),
              ],
            ),
            const SizedBox(height: 16),
            
            // Segmentation button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSegmenting ? null : _startSegmentation,
                icon: _isSegmenting 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_isSegmenting 
                    ? 'Detecting Objects...' 
                    : 'Start AI Segmentation'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Help text
            const Text(
              'AI will analyze your image and create precise masks for object removal or editing.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startSegmentation() async {
    if (widget.selectedImage.bytes == null) {
      _showErrorMessage('Image data not available');
      return;
    }

    setState(() {
      _isSegmenting = true;
    });

    try {
      // Create processing context for segmentation
      final processingContext = ProcessingContext.segmentation(
        targetObjects: _targetObjectsController.text.trim().isNotEmpty 
            ? _targetObjectsController.text.trim() 
            : null,
        confidenceThreshold: _confidenceThreshold,
      );

      // Start segmentation using the cubit
      if (mounted) {
        context.read<GeminiPipelineCubit>().startSegmentation(
          imageData: widget.selectedImage.bytes!,
          targetObjects: processingContext.customInstructions?.contains('targetObjects') == true
              ? _targetObjectsController.text.trim()
              : null,
          confidenceThreshold: _confidenceThreshold,
        );
      }
    } catch (e) {
      _showErrorMessage('Failed to start segmentation: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSegmenting = false;
        });
      }
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:revision/core/services/image_save_service.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_result.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';

/// Widget for displaying AI processing results with before/after comparison.
class ProcessingResultDisplay extends StatefulWidget {
  const ProcessingResultDisplay({
    required this.result,
    required this.originalImage,
    super.key,
  });

  final ProcessingResult result;
  final SelectedImage originalImage;

  @override
  State<ProcessingResultDisplay> createState() =>
      _ProcessingResultDisplayState();
}

class _ProcessingResultDisplayState extends State<ProcessingResultDisplay> {
  bool _showOriginal = false;

  @override
  Widget build(BuildContext context) {
    print('🔄 ProcessingResultDisplay: Building result display');
    print(
        '🔄 Result data size: ${widget.result.processedImageData.length} bytes');
    print('🔄 Original image path: ${widget.originalImage.path}');
    print(
        '🔄 Original image bytes: ${widget.originalImage.bytes?.length ?? 'null'}');
    print('🔄 Show original: $_showOriginal');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Toggle button
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Original',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              Switch(
                value: !_showOriginal,
                onChanged: (value) => setState(() => _showOriginal = !value),
              ),
              Text(
                'Processed',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),

        // Image display
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _showOriginal
                  ? _buildOriginalImage()
                  : _buildProcessedImage(),
            ),
          ),
        ),

        // Processing info
        if (widget.result.metadata != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: _buildProcessingInfo(context),
          ),

        // Save button
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _saveToGallery(context),
            icon: const Icon(Icons.save_alt),
            label: const Text('Save to Gallery'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOriginalImage() {
    final path = widget.originalImage.path;
    if (path == null) {
      return _buildErrorPlaceholder();
    }

    return path.startsWith('http')
        ? Image.network(
            path,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                _buildErrorPlaceholder(),
          )
        : File(path).existsSync()
            ? Image.file(
                File(path),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    _buildErrorPlaceholder(),
              )
            : _buildErrorPlaceholder();
  }

  Widget _buildProcessedImage() {
    print('🔄 ProcessingResultDisplay: Building processed image');
    print(
        '🔄 Processed image data size: ${widget.result.processedImageData.length} bytes');

    try {
      return Image.memory(
        widget.result.processedImageData,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          print(
              '❌ ProcessingResultDisplay: Error loading processed image: $error');
          return _buildErrorPlaceholder();
        },
      );
    } catch (e) {
      print(
          '❌ ProcessingResultDisplay: Exception building processed image: $e');
      return _buildErrorPlaceholder();
    }
  }

  Widget _buildProcessingInfo(BuildContext context) {
    final metadata = widget.result.metadata!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Processing Details',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Job ID', widget.result.jobId ?? 'N/A'),
            _buildInfoRow('Enhanced Prompt', widget.result.enhancedPrompt),
            _buildInfoRow(
              'Processing Time',
              '${widget.result.processingTime.inSeconds}s',
            ),
            if (metadata['ai_model'] != null)
              _buildInfoRow('AI Model', metadata['ai_model'].toString()),
            if (widget.result.imageAnalysis != null)
              _buildInfoRow(
                'Quality Score',
                '${(widget.result.imageAnalysis!.qualityScore ?? 0.0).toStringAsFixed(1)}/10',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return ColoredBox(
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
              'Unable to load image',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveToGallery(BuildContext context) async {
    try {
      // Check if we can save images
      final canSave = await ImageSaveService.canSaveImages();
      if (!canSave) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Cannot save to gallery. Please check permissions and storage space.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }

      // Show loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saving image to gallery...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Get the processed image data
      final processedImageData = widget.result.processedImageData;

      // Save the processed image to gallery
      final savedPath = await ImageSaveService.saveToGallery(
        processedImageData,
        filename: 'ai_processed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      if (context.mounted) {
        if (savedPath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Image saved to gallery successfully!'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to save image to gallery'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving image: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

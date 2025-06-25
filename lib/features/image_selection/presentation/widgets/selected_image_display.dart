import 'package:flutter/material.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';

/// Widget for displaying a selected image with metadata.
///
/// This widget shows the selected image along with its details
/// like file size and format.
class SelectedImageDisplay extends StatelessWidget {
  const SelectedImageDisplay({
    required this.selectedImage,
    this.onRemove,
    super.key,
  });

  final SelectedImage selectedImage;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image display
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
            child: Container(
              constraints: const BoxConstraints(
                maxHeight: 400, // Prevent excessive height
                minHeight: 200, // Ensure minimum visibility
              ),
              child: selectedImage.bytes != null
                  ? Image.memory(
                      selectedImage.bytes!,
                      fit: BoxFit.contain, // Changed from cover to contain
                      gaplessPlayback: true,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildErrorWidget(context);
                      },
                    )
                  : selectedImage.file != null
                      ? Image.file(
                          selectedImage.file!,
                          fit: BoxFit.contain, // Changed from cover to contain
                          errorBuilder: (context, error, stackTrace) {
                            return _buildErrorWidget(context);
                          },
                        )
                      : _buildErrorWidget(context),
            ),
          ),

          // Image metadata
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Selected Image',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (onRemove != null)
                      IconButton(
                        onPressed: onRemove,
                        icon: const Icon(Icons.close),
                        tooltip: 'Remove image',
                      ),
                  ],
                ),
                const SizedBox(height: 8), // Image details
                _DetailRow(
                  icon: Icons.image,
                  label: 'Format',
                  value: selectedImage.name.split('.').last.toUpperCase(),
                ),
                const SizedBox(height: 4),

                _DetailRow(
                  icon: Icons.storage,
                  label: 'Size',
                  value: _formatFileSize(selectedImage.sizeInBytes),
                ),
                const SizedBox(height: 4),

                _DetailRow(
                  icon:
                      selectedImage.isValid ? Icons.check_circle : Icons.error,
                  label: 'Status',
                  value: selectedImage.isValid ? 'Valid' : 'Invalid',
                  valueColor: selectedImage.isValid
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxHeight: 400,
        minHeight: 200,
      ),
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
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

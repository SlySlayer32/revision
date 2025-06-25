import 'dart:io';

import 'package:flutter/material.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';

/// Simple widget to display a selected image for MVP
class ImageDisplayWidget extends StatelessWidget {
  const ImageDisplayWidget({
    required this.selectedImage,
    super.key,
  });

  final SelectedImage selectedImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(selectedImage.path ?? ''),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
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
                      'Failed to load image',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

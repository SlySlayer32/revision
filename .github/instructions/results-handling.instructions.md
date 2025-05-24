---
applyTo: "**/result/**/*.dart,**/gallery/**/*.dart,**/share/**/*.dart"
---
# Results Handling Module Instructions

## Implementation Details

For the results handling module, implement:

- Side-by-side comparison of original and AI-edited images, or an easy toggle between them.
- Options to save the edited image to the device gallery (e.g., using `image_gallery_saver` or platform channels for more control).
- Sharing functionality for the edited image (e.g., using the `share_plus` package).
- Ability to undo/revert to the original image before saving.
- Option to further edit the result if needed (e.g., re-invoke AI with different parameters or apply basic adjustments).

## Code Structure Guidelines

- Use repository pattern for storage operations (saving to gallery, managing local copies if any).
- Implement proper error handling for saving and sharing (e.g., storage full, permission denied, no compatible app for sharing).
- Create utility functions for image format conversion if necessary before saving/sharing (e.g., ensuring JPEG or PNG format).
- Use dependency injection for platform-specific storage services or sharing plugins.
- Add comprehensive unit tests for all result handling operations (mocking platform interactions).

## API Integration

```dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:share_plus/share_plus.dart';

// Example save to gallery implementation
Future<String> saveImageToLocalStorage(File imageFile) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'AI_Edited_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedFile = await imageFile.copy('${directory.path}/$fileName');
    
    return savedFile.path;
  } catch (e) {
    throw SaveImageException('Failed to save image: $e');
  }
}

// Example sharing implementation
Future<void> shareImage(File imageFile) async {
  try {
    await Share.shareFiles(
      [imageFile.path],
      text: 'Check out this tree-less image edited with AI!',
    );
  } catch (e) {
    throw ShareImageException('Failed to share image: $e');
  }
}
```

## User Experience Considerations

- Show a success message (e.g., a Snackbar or Toast) when an image is saved or shared successfully.
- Implement smooth transitions or clear visual distinction when toggling between original and edited images.
- Add image metadata to saved files (when supported and relevant, e.g., app name, date edited). Consider privacy implications.
- Provide clear error messages if saving or sharing fails, with actionable advice if possible.
- Consider adding basic editing tools (brightness, contrast, filters) for final adjustments *after* AI processing, before saving/sharing.

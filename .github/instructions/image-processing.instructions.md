---
applyTo: "**/image/**/*.dart,**/picker/**/*.dart,**/camera/**/*.dart"
---
# Image Processing Module Instructions

## Implementation Details

For the image processing module, implement:

- Support for selecting images from gallery and camera (using `image_picker` package).
- RAW image file detection (e.g., by extension) and handling using `flutter_libraw`. Be mindful of potential performance implications and longer processing times for RAW files. Clearly indicate to the user when a RAW file is being processed.
- Image format validation (JPEG, PNG, common RAW types) and optional compression (e.g., using `flutter_image_compress` if needed, balancing quality and size).
- UI for displaying the selected image with controls (e.g., zoom, pan). This UI should be managed by a dedicated BLoC/Cubit. (Refer to [BLoC & Cubit Implementation Guidelines](./bloc-guidelines.instructions.md) and [BLoC Widget Structure Guidelines](./bloc_widget_structure.instructions.md)).
- Caching mechanism for processed or frequently accessed images (e.g., using `flutter_cache_manager`).

## Code Structure Guidelines

- Use repository pattern to abstract image source operations (gallery, camera, file system).
- Implement proper error handling for image loading/processing failures (e.g., file not found, unsupported format, decoding errors, permission issues).
- Create utility classes for common image operations (e.g., format conversion, resizing, EXIF data reading if necessary).
- Optimize for memory usage when handling large images, especially RAW files. Consider decoding at lower resolutions for previews if full resolution is not immediately needed.
- Use streams or BLoC states for indicating processing progress, especially for time-consuming operations like RAW decoding or compression.

## API Integration

```dart
// Example image picker implementation
Future<File?> pickImageFromGallery() async {
  try {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  } catch (e) {
    throw ImagePickerException('Failed to pick image: $e');
  }
}

// Example RAW image detection
Future<bool> isRawImage(File file) async {
  final extension = path.extension(file.path).toLowerCase();
  return ['.raw', '.cr2', '.nef', '.arw', '.dng'].contains(extension);
}
```

## User Experience Considerations

- Show proper loading indicators during image picking, loading, and processing. For RAW files or large images, provide more detailed progress if possible (e.g., percentage, steps).
- Handle permissions requests (camera, gallery/storage) elegantly, explaining why they are needed and guiding the user if denied. (Refer to platform-specific permission handling best practices).
- Provide clear feedback for unsupported file types or processing errors.
- Consider implementing image editing tools (crop, rotate) *before* AI processing to allow users to refine the input to the AI.
- Add intuitive gestures for image manipulation (zoom, pan) on the preview screen.

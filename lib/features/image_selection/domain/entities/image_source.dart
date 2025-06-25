/// Enumeration representing different sources for image selection.
///
/// This enum defines the available options for users to select images
/// in the photo editor application.
enum ImageSource {
  /// Select image from device gallery/photos
  gallery,

  /// Capture image using device camera
  camera;

  /// Display name for UI
  String get displayName {
    return switch (this) {
      ImageSource.gallery => 'Photo Gallery',
      ImageSource.camera => 'Camera',
    };
  }

  /// Description for UI
  String get description {
    return switch (this) {
      ImageSource.gallery => 'Choose from your photo library',
      ImageSource.camera => 'Take a new photo',
    };
  }
}

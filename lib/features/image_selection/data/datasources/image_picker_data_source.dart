import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart' as picker;
import 'package:revision/features/image_selection/domain/entities/image_source.dart';

/// Data source for image picking operations using the image_picker package.
///
/// This class handles the actual image selection from gallery or camera
/// and returns the XFile for platform-agnostic handling.
class ImagePickerDataSource {
  const ImagePickerDataSource(this._imagePicker);

  final picker.ImagePicker _imagePicker;

  /// Picks an image from the specified source.
  ///
  /// Returns [XFile] on success, throws exception on failure.
  Future<picker.XFile?> pickImage(ImageSource source) async {
    final pickerSource = source == ImageSource.gallery
        ? picker.ImageSource.gallery
        : picker.ImageSource.camera;
    final pickedFile = await _imagePicker
        .pickImage(
          source: pickerSource,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception('Image selection timed out'),
        );

    return pickedFile;
  }

  /// Checks if the device has camera capability.
  Future<bool> hasCameraCapability() async {
    // On web, camera is available if getUserMedia is supported
    if (kIsWeb) {
      return true; // Modern browsers support camera access
    }

    // On mobile platforms
    return Platform.isAndroid || Platform.isIOS;
  }
}

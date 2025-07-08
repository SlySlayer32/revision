import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart' as picker;
import 'package:revision/core/constants/app_constants.dart';
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
  /// Now includes enhanced security parameters and validation.
  Future<picker.XFile?> pickImage(ImageSource source) async {
    final pickerSource = source == ImageSource.gallery
        ? picker.ImageSource.gallery
        : picker.ImageSource.camera;
    
    try {
      final pickedFile = await _imagePicker
          .pickImage(
            source: pickerSource,
            maxWidth: 1920,
            maxHeight: 1080,
            imageQuality: 85,
            requestFullMetadata: false, // Don't request metadata for privacy
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Image selection timed out'),
          );

      // Additional validation if file was selected
      if (pickedFile != null) {
        await _validateSelectedFile(pickedFile);
      }

      return pickedFile;
    } catch (e) {
      // Re-throw with more context
      throw Exception('Image selection failed: ${e.toString()}');
    }
  }

  /// Validates the selected file before returning it.
  Future<void> _validateSelectedFile(picker.XFile file) async {
    try {
      // Check file size (consistent with AppConstants.maxImageSize)
      if (fileSize > AppConstants.maxImageSize) {
        final sizeMB = AppConstants.bytesToMB(fileSize);
        final maxSizeMB = AppConstants.bytesToMB(AppConstants.maxImageSize);
        throw Exception('Selected file is too large: ${sizeMB.toStringAsFixed(1)}MB (max ${maxSizeMB.toStringAsFixed(1)}MB)');
      }

      // Check file extension
      final extension = file.path.split('.').last.toLowerCase();
      const allowedExtensions = ['jpg', 'jpeg', 'png', 'webp', 'heic'];
      if (!allowedExtensions.contains(extension)) {
        throw Exception('Unsupported file format: $extension');
      }

      // Basic file existence check
      if (file.path.isEmpty) {
        throw Exception('Invalid file path');
      }
    } catch (e) {
      throw Exception('File validation failed: ${e.toString()}');
    }
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

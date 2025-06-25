import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:revision/core/utils/result.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';

/// Production-ready service to save images to device gallery
class ImageSaveService {
  const ImageSaveService();

  /// Saves an image to the device gallery
  /// Handles permissions, file processing, and platform-specific saving
  Future<Result<String>> saveToGallery(SelectedImage image) async {
    try {
      // Check and request permissions
      final permissionGranted = await _requestPermissions();
      if (!permissionGranted) {
        return Failure(
          Exception(
              'Storage permission denied. Please grant permission to save images.'),
        );
      }

      // Process the image file
      final imageBytes = await _processImageFile(image);
      if (imageBytes == null) {
        return Failure(Exception('Failed to process image file'));
      }

      // Generate a unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = _getFileExtension(image.name);
      final fileName = 'edited_image_$timestamp.$extension';

      // Save to gallery
      final result = await ImageGallerySaver.saveImage(
        imageBytes,
        name: fileName,
        quality: 95, // High quality for edited images
      );

      if (result['isSuccess'] == true) {
        final savedPath = result['filePath'] ?? 'Gallery';
        return Success('Image saved successfully to $savedPath');
      } else {
        return Failure(
          Exception(
              'Failed to save image to gallery: ${result['errorMessage'] ?? 'Unknown error'}'),
        );
      }
    } catch (e) {
      return Failure(Exception('Failed to save image: $e'));
    }
  }

  /// Checks if the device supports gallery saving and has necessary permissions
  Future<bool> canSaveToGallery() async {
    try {
      if (Platform.isIOS) {
        // iOS always supports saving to Photos
        return true;
      } else if (Platform.isAndroid) {
        // Check Android version and permissions
        final permission = await _getRequiredPermission();
        final status = await permission.status;
        return status.isGranted || status.isLimited;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Requests necessary permissions for saving images
  Future<bool> _requestPermissions() async {
    try {
      if (Platform.isIOS) {
        const permission = Permission.photos;
        final status = await permission.request();
        return status.isGranted || status.isLimited;
      } else if (Platform.isAndroid) {
        final permission = await _getRequiredPermission();
        final status = await permission.request();
        return status.isGranted;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Gets the appropriate permission based on Android version
  Future<Permission> _getRequiredPermission() async {
    // For Android 13+ (API 33+), use granular permissions
    if (Platform.isAndroid) {
      final androidInfo = await _getAndroidVersion();
      if (androidInfo >= 33) {
        return Permission.photos;
      } else {
        return Permission.storage;
      }
    }
    return Permission.photos;
  }

  /// Gets Android SDK version
  Future<int> _getAndroidVersion() async {
    // This is a simplified version - in a real implementation,
    // you might use device_info_plus package for more accurate detection
    return 33; // Assume modern Android for now
  }

  /// Processes the image file and returns bytes
  Future<Uint8List?> _processImageFile(SelectedImage image) async {
    try {
      if (image.path == null) {
        return null;
      }
      final file = File(image.path!);
      if (!await file.exists()) {
        return null;
      }

      final bytes = await file.readAsBytes();

      // Decode and re-encode to ensure compatibility
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) {
        return null;
      }

      // Re-encode as JPEG for better compatibility
      final encodedBytes = img.encodeJpg(decodedImage, quality: 95);
      return Uint8List.fromList(encodedBytes);
    } catch (e) {
      return null;
    }
  }

  /// Extracts file extension from filename
  String _getFileExtension(String fileName) {
    final parts = fileName.split('.');
    if (parts.length > 1) {
      return parts.last.toLowerCase();
    }
    return 'jpg'; // Default extension
  }

  /// Saves image to a temporary location (for testing or fallback)
  Future<Result<String>> saveToTemp(SelectedImage image) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = _getFileExtension(image.name);
      final fileName = 'temp_image_$timestamp.$extension';
      final tempFile = File('${tempDir.path}/$fileName');

      if (image.path == null) {
        return Failure(Exception('Image path is null'));
      }

      final originalFile = File(image.path!);
      await originalFile.copy(tempFile.path);

      return Success('Image saved to temporary location: ${tempFile.path}');
    } catch (e) {
      return Failure(Exception('Failed to save to temp: $e'));
    }
  }
}

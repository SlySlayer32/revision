import 'dart:io';
import 'dart:typed_data';

import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for saving processed images to device gallery and local storage.
class ImageSaveService {
  /// Save processed image to device gallery.
  ///
  /// Returns the path where the image was saved, or null if saving failed.
  static Future<String?> saveToGallery(
    Uint8List imageData, {
    String? filename,
  }) async {
    try {
      // Request permission on Android
      if (Platform.isAndroid) {
        final permission = await Permission.storage.request();
        if (!permission.isGranted) {
          final mediaLibraryPermission =
              await Permission.mediaLibrary.request();
          if (!mediaLibraryPermission.isGranted) {
            throw Exception('Storage permission denied');
          }
        }
      }

      // Generate filename if not provided
      final name =
          filename ?? 'ai_edited_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Save to gallery
      final result = await ImageGallerySaver.saveImage(
        imageData,
        name: name,
        quality: 95,
      );

      if (result['isSuccess'] == true) {
        return result['filePath'] as String?;
      } else {
        throw Exception('Failed to save image to gallery');
      }
    } catch (e) {
      print('Error saving image to gallery: $e');
      return null;
    }
  }

  /// Save image to app's local directory.
  ///
  /// Returns the local file path.
  static Future<String> saveToLocal(
    Uint8List imageData, {
    String? filename,
  }) async {
    try {
      // Get app's documents directory
      final directory = await getApplicationDocumentsDirectory();
      final localDir = Directory('${directory.path}/ai_processed');

      // Create directory if it doesn't exist
      if (!await localDir.exists()) {
        await localDir.create(recursive: true);
      }

      // Generate filename if not provided
      final name =
          filename ?? 'ai_edited_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Save file
      final file = File('${localDir.path}/$name');
      await file.writeAsBytes(imageData);

      return file.path;
    } catch (e) {
      throw Exception('Failed to save image locally: $e');
    }
  }

  /// Get all locally saved processed images.
  static Future<List<File>> getLocalProcessedImages() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final localDir = Directory('${directory.path}/ai_processed');

      if (!await localDir.exists()) {
        return [];
      }

      final files = await localDir.list().toList();
      return files
          .whereType<File>()
          .where((file) =>
              file.path.toLowerCase().endsWith('.jpg') ||
              file.path.toLowerCase().endsWith('.png'))
          .toList();
    } catch (e) {
      print('Error getting local images: $e');
      return [];
    }
  }

  /// Delete a locally saved image.
  static Future<bool> deleteLocal(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting local image: $e');
      return false;
    }
  }

  /// Get available storage space in bytes.
  static Future<int> getAvailableSpace() async {
    try {
      // This is a simplified approach - in production you'd want more detailed space checking
      return 1024 * 1024 * 100; // Return 100MB as available space for MVP
    } catch (e) {
      return 0;
    }
  }

  /// Check if we can save images (permissions, space, etc).
  static Future<bool> canSaveImages() async {
    try {
      // Check permissions
      if (Platform.isAndroid) {
        final storagePermission = await Permission.storage.status;
        final mediaPermission = await Permission.mediaLibrary.status;
        if (!storagePermission.isGranted && !mediaPermission.isGranted) {
          return false;
        }
      }

      // Check available space (simplified)
      final availableSpace = await getAvailableSpace();
      if (availableSpace < 1024 * 1024) {
        // Less than 1MB
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}

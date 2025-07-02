import 'dart:io';

import 'package:flutter/foundation.dart';
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
            return null;
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

      return result['isSuccess'] == true ? result['filePath'] as String? : null;
    } catch (e) {
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
      rethrow;
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

  /// Save image using platform-specific implementation.
  ///
  /// Returns true if the image was saved successfully, false otherwise.
  static Future<bool> saveImage(Uint8List imageBytes, String fileName) async {
    if (kIsWeb) {
      return _saveImageWeb(imageBytes, fileName);
    } else if (Platform.isAndroid || Platform.isIOS) {
      return _saveImageMobile(imageBytes, fileName);
    } else {
      return _saveImageDesktop(imageBytes, fileName);
    }
  }

  static Future<bool> _saveImageWeb(
      Uint8List imageBytes, String fileName) async {
    // Web saving is handled by the browser, this is a placeholder
    return true;
  }

  static Future<bool> _saveImageMobile(
      Uint8List imageBytes, String fileName) async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      final result = await ImageGallerySaver.saveImage(
        imageBytes,
        name: fileName,
        quality: 100,
      );
      return result['isSuccess'] ?? false;
    } else {
      return false;
    }
  }

  static Future<bool> _saveImageDesktop(
      Uint8List imageBytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$fileName';
    final file = File(path);
    await file.writeAsBytes(imageBytes);
    return true;
  }
}

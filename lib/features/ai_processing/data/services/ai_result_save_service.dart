import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:revision/core/services/gemini_pipeline_service.dart';
import 'package:revision/core/utils/result.dart';

/// Service to save AI processing results to device storage
class AIResultSaveService {
  const AIResultSaveService();

  /// Saves the AI processing result (generated image) to device gallery
  Future<Result<String>> saveResultToGallery(
      GeminiPipelineResult result) async {
    try {
      // Check and request permissions
      final permissionGranted = await _requestPermissions();
      if (!permissionGranted) {
        return Failure(
          Exception(
              'Storage permission denied. Please grant permission to save images.'),
        );
      }

      // Generate a unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'ai_processed_image_$timestamp.jpg';

      // Ensure the image is properly formatted
      final processedBytes = await _processImageBytes(result.generatedImage);
      if (processedBytes == null) {
        return Failure(Exception('Failed to process generated image'));
      }

      // Save to gallery
      final saveResult = await ImageGallerySaver.saveImage(
        processedBytes,
        name: fileName,
        quality: 95,
      );

      if (saveResult['isSuccess'] == true) {
        final savedPath = saveResult['filePath'] ?? 'Gallery';
        return Success('AI processed image saved successfully to $savedPath');
      } else {
        return Failure(
          Exception(
              'Failed to save image to gallery: ${saveResult['errorMessage'] ?? 'Unknown error'}'),
        );
      }
    } catch (e) {
      return Failure(Exception('Failed to save AI result: $e'));
    }
  }

  /// Saves both original and processed images with metadata
  Future<Result<String>> saveResultWithComparison(
      GeminiPipelineResult result) async {
    try {
      final permissionGranted = await _requestPermissions();
      if (!permissionGranted) {
        return Failure(
          Exception(
              'Storage permission denied. Please grant permission to save images.'),
        );
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Save original image
      final originalFileName = 'ai_original_$timestamp.jpg';
      final originalBytes = await _processImageBytes(result.originalImage);
      if (originalBytes != null) {
        await ImageGallerySaver.saveImage(
          originalBytes,
          name: originalFileName,
          quality: 95,
        );
      }

      // Save processed image
      final processedFileName = 'ai_processed_$timestamp.jpg';
      final processedBytes = await _processImageBytes(result.generatedImage);
      if (processedBytes != null) {
        await ImageGallerySaver.saveImage(
          processedBytes,
          name: processedFileName,
          quality: 95,
        );
      }

      // Save metadata as text file (optional)
      await _saveMetadata(result, timestamp);

      return const Success(
          'AI processing results saved with comparison images');
    } catch (e) {
      return Failure(Exception('Failed to save AI result with comparison: $e'));
    }
  }

  /// Saves AI result to temporary directory for sharing
  Future<Result<String>> saveResultToTemp(GeminiPipelineResult result) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'ai_processed_$timestamp.jpg';
      final tempFile = File('${tempDir.path}/$fileName');

      final processedBytes = await _processImageBytes(result.generatedImage);
      if (processedBytes == null) {
        return Failure(Exception('Failed to process generated image'));
      }

      await tempFile.writeAsBytes(processedBytes);
      return Success('AI result saved to temporary location: ${tempFile.path}');
    } catch (e) {
      return Failure(Exception('Failed to save to temp: $e'));
    }
  }

  /// Checks if the device supports gallery saving
  Future<bool> canSaveToGallery() async {
    try {
      if (Platform.isIOS) {
        return true;
      } else if (Platform.isAndroid) {
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
    return 33; // Assume modern Android for now
  }

  /// Processes image bytes to ensure compatibility
  Future<Uint8List?> _processImageBytes(Uint8List imageBytes) async {
    try {
      // Decode the image
      final decodedImage = img.decodeImage(imageBytes);
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

  /// Saves processing metadata as a text file
  Future<void> _saveMetadata(GeminiPipelineResult result, int timestamp) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final metadataFile = File('${tempDir.path}/ai_metadata_$timestamp.txt');

      final metadata = '''
AI Processing Result Metadata
============================
Timestamp: ${DateTime.now().toIso8601String()}
Processing Time: ${result.processingTimeMs}ms
Analysis Prompt: ${result.analysisPrompt}
Marked Areas: ${result.markedAreas.length} areas
Original Image Size: ${result.originalImage.length} bytes
Generated Image Size: ${result.generatedImage.length} bytes
''';

      await metadataFile.writeAsString(metadata);
    } catch (e) {
      // Ignore metadata save errors
    }
  }
}

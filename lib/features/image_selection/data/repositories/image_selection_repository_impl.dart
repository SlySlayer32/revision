import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart' as picker;
import 'package:permission_handler/permission_handler.dart';
import 'package:revision/core/utils/result.dart';
import 'package:revision/features/image_selection/data/datasources/image_picker_data_source.dart';
import 'package:revision/features/image_selection/domain/entities/image_source.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';
import 'package:revision/features/image_selection/domain/exceptions/image_selection_exception.dart';
import 'package:revision/features/image_selection/domain/repositories/image_selection_repository.dart';

/// Implementation of [ImageRepository] using [ImagePickerDataSource].
///
/// This class handles image selection operations and converts exceptions
/// to domain-specific exceptions.
class ImageSelectionRepositoryImpl implements ImageRepository {
  const ImageSelectionRepositoryImpl(this._dataSource);

  final ImagePickerDataSource _dataSource;

  @override
  Future<Result<SelectedImage>> pickFromGallery() async {
    try {
      final xFile = await _dataSource.pickImage(ImageSource.gallery);
      if (xFile == null) {
        return const Failure(
          ImageSelectionException.cancelled('No image selected'),
        );
      }

      final selectedImage = await _createSelectedImage(
        xFile,
        ImageSource.gallery,
      );
      return Success(selectedImage);
    } catch (e) {
      return Failure(_mapException(e));
    }
  }

  @override
  Future<Result<SelectedImage>> pickFromCamera() async {
    try {
      final xFile = await _dataSource.pickImage(ImageSource.camera);
      if (xFile == null) {
        return const Failure(
          ImageSelectionException.cancelled('No image selected'),
        );
      }

      final selectedImage = await _createSelectedImage(
        xFile,
        ImageSource.camera,
      );
      return Success(selectedImage);
    } catch (e) {
      return Failure(_mapException(e));
    }
  }

  /// Creates a platform-appropriate SelectedImage from XFile
  Future<SelectedImage> _createSelectedImage(
    picker.XFile xFile,
    ImageSource source,
  ) async {
    final fileName = xFile.name;
    final sizeInBytes = await xFile.length();

    if (kIsWeb) {
      // On web, store bytes
      final bytes = await xFile.readAsBytes();
      return SelectedImage(
        bytes: bytes,
        name: fileName,
        sizeInBytes: sizeInBytes,
        source: source,
      );
    } else {
      // On mobile, store file path
      return SelectedImage(
        path: xFile.path,
        name: fileName,
        sizeInBytes: sizeInBytes,
        source: source,
      );
    }
  }

  @override
  Result<SelectedImage> validateImage(SelectedImage image) {
    try {
      // Check if we have image data
      if (image.path == null && image.bytes == null) {
        return const Failure(
          ImageSelectionException.fileNotFound('No image data available'),
        );
      }

      // Check file size (50MB limit for AI processing)
      if (image.sizeInMB > 50) {
        return Failure(
          ImageSelectionException.fileTooLarge(
            'Image is too large (${image.sizeInMB.toStringAsFixed(1)}MB). Maximum size is 50MB',
          ),
        );
      }

      // Check format
      if (!image.isValidFormat) {
        return Failure(
          ImageSelectionException.invalidFormat(
            'Unsupported image format: ${image.name.split('.').last}',
          ),
        );
      }

      return Success(image);
    } catch (e) {
      return Failure(_mapException(e));
    }
  }

  @override
  Future<bool> isCameraAvailable() async {
    try {
      return await _dataSource.hasCameraCapability();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> isGalleryAvailable() async {
    // Web and Android: assume gallery is available (permissions handled by image_picker)
    try {
      if (kIsWeb || Platform.isAndroid) {
        return true;
      }
      // iOS: request photo library permission
      if (Platform.isIOS) {
        final status = await Permission.photos.request();
        return status.isGranted;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Maps generic exceptions to domain-specific exceptions.
  ImageSelectionException _mapException(Object exception) {
    if (exception is ImageSelectionException) {
      return exception;
    }

    final message = exception.toString();

    // Map common exception messages
    if (message.contains('No image selected') ||
        message.contains('User cancelled')) {
      return const ImageSelectionException.cancelled(
        'Image selection was cancelled',
      );
    }

    if (message.contains('permission') || message.contains('denied')) {
      return const ImageSelectionException.permissionDenied(
        'Permission denied for image selection',
      );
    }

    if (message.contains('camera') && message.contains('not available')) {
      return const ImageSelectionException.cameraUnavailable(
        'Camera is not available on this device',
      );
    }

    // Default to unknown error
    return ImageSelectionException.unknown(
      'An unexpected error occurred: $message',
    );
  }
}

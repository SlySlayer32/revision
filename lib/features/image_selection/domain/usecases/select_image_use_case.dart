import 'package:revision/core/utils/result.dart';
import 'package:revision/features/image_selection/domain/entities/image_source.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';
import 'package:revision/features/image_selection/domain/exceptions/image_selection_exception.dart';
import 'package:revision/features/image_selection/domain/repositories/image_selection_repository.dart';

/// String constants for error messages.
abstract class _Strings {
  static const String cameraUnavailableMessage =
      'Camera not available on this device';
  static const String galleryUnavailableMessage =
      'Gallery access not available';
}

/// Use case for selecting images from gallery or camera.
///
/// This use case encapsulates the business logic for image selection
/// and delegates to the repository for actual implementation.
class SelectImageUseCase {
  const SelectImageUseCase(this._repository);

  final ImageRepository _repository;

  /// Executes the image selection use case.
  ///
  /// [source] - The source from which to select the image (gallery/camera)
  ///
  /// Returns [Result] with [SelectedImage] on success,
  /// or [ImageSelectionException] on error.
  Future<Result<SelectedImage>> call(ImageSource source) async {
    // Check source availability first
    final availabilityResult = await _checkSourceAvailability(source);
    if (availabilityResult is Failure<void>) {
      return Failure<SelectedImage>(availabilityResult.exception);
    }

    // Select the image from the specified source
    final result = await _selectImageFromSource(source);

    // Validate the selected image if successful
    return result.fold(
      success: _repository.validateImage,
      failure: (exception) => Failure<SelectedImage>(exception),
    );
  }

  /// Checks if the specified image source is available.
  Future<Result<void>> _checkSourceAvailability(ImageSource source) async {
    switch (source) {
      case ImageSource.camera:
        final isAvailable = await _repository.isCameraAvailable();
        if (!isAvailable) {
          return Failure<void>(
            Exception(_Strings.cameraUnavailableMessage),
          );
        }
        break;
      case ImageSource.gallery:
        final isAvailable = await _repository.isGalleryAvailable();
        if (!isAvailable) {
          return Failure<void>(
            Exception(_Strings.galleryUnavailableMessage),
          );
        }
        break;
    }
    return const Success<void>(null);
  }

  /// Selects an image from the specified source.
  Future<Result<SelectedImage>> _selectImageFromSource(
    ImageSource source,
  ) async {
    switch (source) {
      case ImageSource.gallery:
        return _repository.pickFromGallery();
      case ImageSource.camera:
        return _repository.pickFromCamera();
    }
  }
}

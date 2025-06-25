import 'package:revision/core/utils/result.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';
import 'package:revision/features/image_selection/domain/exceptions/image_selection_exception.dart'
    show ImageSelectionException;

/// Repository interface for image selection operations.
///
/// This abstract class defines the contract for image selection
/// functionality that can be implemented by concrete classes.
abstract interface class ImageRepository {
  /// Picks an image from the device gallery
  ///
  /// Returns [SelectedImage] on success or [ImageSelectionException] on failure
  Future<Result<SelectedImage>> pickFromGallery();

  /// Captures an image using the device camera
  ///
  /// Returns [SelectedImage] on success or [ImageSelectionException] on failure
  Future<Result<SelectedImage>> pickFromCamera();

  /// Validates if the selected image meets requirements
  ///
  /// Returns [SelectedImage] on success or [ImageSelectionException] on failure
  Result<SelectedImage> validateImage(SelectedImage image);

  /// Checks if camera is available on the device
  Future<bool> isCameraAvailable();

  /// Checks if gallery access is available
  Future<bool> isGalleryAvailable();
}

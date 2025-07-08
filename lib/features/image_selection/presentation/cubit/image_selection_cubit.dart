import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/core/services/image_security_service.dart';
import 'package:revision/features/image_selection/domain/entities/image_source.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';
import 'package:revision/features/image_selection/domain/exceptions/image_selection_exception.dart';
import 'package:revision/features/image_selection/domain/usecases/select_image_use_case.dart';
import 'package:revision/features/image_selection/presentation/cubit/image_selection_state.dart';

/// Cubit for managing image selection state and operations.
///
/// This cubit handles the business logic for image selection from
/// gallery or camera, updating the UI state accordingly.
/// Now includes comprehensive security validation and processing.
class ImageSelectionCubit extends Cubit<ImageSelectionState> {
  ImageSelectionCubit(this._selectImageUseCase)
    : super(const ImageSelectionInitial());

  final SelectImageUseCase _selectImageUseCase;

  /// Selects an image from the specified source (gallery or camera).
  /// 
  /// Now includes comprehensive security processing:
  /// - Enhanced validation
  /// - EXIF data stripping
  /// - Image compression
  /// - Malware scanning
  Future<void> selectImage(ImageSource source) async {
    emit(const ImageSelectionLoading());
    // Allow UI to rebuild/loading indicator before heavy operations
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      final result = await _selectImageUseCase(source);

      await result.fold(
        success: (selectedImage) => _processImageSecurely(selectedImage),
        failure: (exception) => _handleImageSelectionError(exception),
      );
    } catch (e) {
      emit(ImageSelectionError('Unexpected error: ${e.toString()}'));
    }
  }

  /// Processes the selected image with comprehensive security measures.
  Future<void> _processImageSecurely(SelectedImage selectedImage) async {
    try {
      // Get image data for processing
      final imageData = selectedImage.bytes;
      if (imageData == null) {
        emit(const ImageSelectionError('No image data available for processing'));
        return;
      }

      // Process image with security measures
      final securityResult = ImageSecurityService.processImageSecurely(
        imageData,
        filename: selectedImage.name,
        compressImage: true,
        stripExif: true,
      );

      securityResult.fold(
        success: (processedData) {
          // Create new SelectedImage with processed data
          final secureImage = selectedImage.copyWith(
            bytes: processedData,
            sizeInBytes: processedData.length,
          );
          emit(ImageSelectionSuccess(secureImage));
        },
        failure: (exception) {
          emit(ImageSelectionError(_formatSecurityError(exception)));
        },
      );
    } catch (e) {
      emit(ImageSelectionError('Security processing failed: ${e.toString()}'));
    }
  }

  /// Handles image selection errors with improved error messages.
  void _handleImageSelectionError(Object exception) {
    String errorMessage;
    
    if (exception is ImageSelectionException) {
      errorMessage = _formatImageSelectionError(exception);
    } else {
      errorMessage = 'Image selection failed: ${exception.toString()}';
    }

    emit(ImageSelectionError(errorMessage));
  }

  /// Formats image selection errors for better user experience.
  String _formatImageSelectionError(ImageSelectionException exception) {
    switch (exception.runtimeType) {
      case const (PermissionDeniedException):
        return 'Permission denied. Please allow access to your camera/gallery in settings.';
      case const (FileTooLargeException):
        return exception.message;
      case const (InvalidFormatException):
        return 'Unsupported image format. Please select a JPEG, PNG, or WebP image.';
      case const (CameraUnavailableException):
        return 'Camera is not available on this device.';
      case const (CancelledException):
        return 'Image selection was cancelled.';
      default:
        return exception.message;
    }
  }

  /// Formats security-related errors for user display.
  String _formatSecurityError(Object exception) {
    if (exception is ImageSelectionException) {
      return exception.message;
    }
    return 'Security validation failed: ${exception.toString()}';
  }

  /// Clears the current selection and resets to initial state.
  void clearSelection() {
    emit(const ImageSelectionInitial());
  }
}

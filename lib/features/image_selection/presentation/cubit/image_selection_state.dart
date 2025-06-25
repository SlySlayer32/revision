import 'package:equatable/equatable.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';

/// States for the image selection cubit.
///
/// This represents all possible states during image selection process.
abstract class ImageSelectionState extends Equatable {
  const ImageSelectionState();

  @override
  List<Object?> get props => [];
}

/// Initial state - no image selection attempted
class ImageSelectionInitial extends ImageSelectionState {
  const ImageSelectionInitial();
}

/// Loading state - image selection in progress
class ImageSelectionLoading extends ImageSelectionState {
  const ImageSelectionLoading();
}

/// Success state - image successfully selected
class ImageSelectionSuccess extends ImageSelectionState {
  const ImageSelectionSuccess(this.selectedImage);

  final SelectedImage selectedImage;

  @override
  List<Object?> get props => [selectedImage];
}

/// Error state - image selection failed
class ImageSelectionError extends ImageSelectionState {
  const ImageSelectionError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

import 'dart:io';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// States for the ImagePreviewCubit.
abstract class ImagePreviewState extends Equatable {
  const ImagePreviewState();

  @override
  List<Object?> get props => [];
}

/// Initial state before image loading begins.
class ImagePreviewInitial extends ImagePreviewState {
  const ImagePreviewInitial();
}

/// State while the image is loading.
class ImagePreviewLoading extends ImagePreviewState {
  const ImagePreviewLoading();
}

/// State when the image has been loaded successfully.
/// Contains the [File] and/or raw [bytes] for display.
class ImagePreviewLoaded extends ImagePreviewState {
  const ImagePreviewLoaded({this.file, this.bytes});

  /// File reference to the loaded image (if available).
  final File? file;

  /// Raw bytes of the image.
  final Uint8List? bytes;

  @override
  List<Object?> get props => [file?.path, bytes?.lengthInBytes];
}

/// State when an error occurs during image loading.
class ImagePreviewError extends ImagePreviewState {
  const ImagePreviewError(this.message);

  /// Error message to display.
  final String message;

  @override
  List<Object?> get props => [message];
}

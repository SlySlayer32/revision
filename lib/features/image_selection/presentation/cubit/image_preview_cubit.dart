import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'image_preview_state.dart';

/// Cubit for managing image preview loading states.
class ImagePreviewCubit extends Cubit<ImagePreviewState> {
  ImagePreviewCubit() : super(const ImagePreviewInitial());

  /// Load image from [file] or raw [bytes].
  Future<void> loadImage({File? file, Uint8List? bytes}) async {
    try {
      emit(const ImagePreviewLoading());
      if (file == null && bytes == null) {
        throw Exception('No image data provided');
      }

      final Uint8List imageData = bytes ?? await file!.readAsBytes();
      emit(ImagePreviewLoaded(file: file, bytes: imageData));
    } catch (e) {
      emit(ImagePreviewError(e.toString()));
    }
  }

  /// Reset to initial state.
  void clearPreview() {
    emit(const ImagePreviewInitial());
  }
}

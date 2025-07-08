import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/features/image_selection/domain/entities/image_source.dart';
import 'package:revision/features/image_selection/domain/usecases/select_image_use_case.dart';
import 'package:revision/features/image_selection/presentation/cubit/image_selection_state.dart';

/// Cubit for managing image selection state and operations.
///
/// This cubit handles the business logic for image selection from
/// gallery or camera, updating the UI state accordingly.
class ImageSelectionCubit extends Cubit<ImageSelectionState> {
  ImageSelectionCubit(this._selectImageUseCase)
    : super(const ImageSelectionInitial());

  final SelectImageUseCase _selectImageUseCase;

  /// Selects an image from the specified source (gallery or camera).
  Future<void> selectImage(ImageSource source) async {
    emit(const ImageSelectionLoading());
    // Allow UI to rebuild/loading indicator before heavy operations
    await Future.delayed(const Duration(milliseconds: 100));

    final result = await _selectImageUseCase(source);

    result.fold(
      success: (selectedImage) => emit(ImageSelectionSuccess(selectedImage)),
      failure: (exception) => emit(ImageSelectionError(exception.toString())),
    );
  }

  /// Clears the current selection and resets to initial state.
  void clearSelection() {
    emit(const ImageSelectionInitial());
  }
}

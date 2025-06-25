import 'package:dartz/dartz.dart';
import 'package:revision/features/image_editor/domain/entities/edited_image.dart';
import 'package:revision/features/image_editor/domain/repositories/image_editor_repository.dart';

/// MVP Use case for loading images for editing
class LoadImageUseCase {
  const LoadImageUseCase(this._repository);

  final ImageEditorRepository _repository;

  Future<Either<ImageEditorException, EditedImage>> call(String path) async {
    if (path.isEmpty) {
      return const Left(ImageLoadException('Image path cannot be empty'));
    }

    try {
      return await _repository.loadImage(path);
    } catch (e) {
      return Left(ImageLoadException('Failed to load image: $e'));
    }
  }
}

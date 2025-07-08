import 'package:dartz/dartz.dart';
import 'package:revision/features/image_editor/domain/entities/edited_image.dart';

abstract class ImageEditorException implements Exception {
  const ImageEditorException(this.message);
  final String message;
}

class ImageLoadException extends ImageEditorException {
  const ImageLoadException(super.message);
}

class ImageSaveException extends ImageEditorException {
  const ImageSaveException(super.message);
}

class ProcessingException extends ImageEditorException {
  const ProcessingException(super.message);
}

/// MVP Repository interface for image editing operations
abstract class ImageEditorRepository {
  Future<Either<ImageEditorException, EditedImage>> loadImage(String path);
  Future<Either<ImageEditorException, EditedImage>> saveImage(
    EditedImage image,
  );
  Future<Either<ImageEditorException, void>> deleteImage(String id);
}

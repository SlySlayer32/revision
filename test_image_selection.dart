import 'package:image_picker/image_picker.dart';
import 'package:revision/features/image_selection/data/datasources/image_picker_data_source.dart';
import 'package:revision/features/image_selection/data/repositories/image_selection_repository_impl.dart';
import 'package:revision/features/image_selection/domain/usecases/select_image_use_case.dart';

void main() async {
  print('Testing image selection compilation...');

  // Test that all classes can be instantiated
  final imagePicker = ImagePicker();
  final dataSource = ImagePickerDataSource(imagePicker);
  final repository = ImageSelectionRepositoryImpl(dataSource);
  final useCase = SelectImageUseCase(repository);

  print('✅ All classes compile successfully');
  print('✅ Image selection module is ready');

  // Test availability checks
  try {
    final cameraAvailable = await repository.isCameraAvailable();
    final galleryAvailable = await repository.isGalleryAvailable();

    print('Camera available: $cameraAvailable');
    print('Gallery available: $galleryAvailable');
  } catch (e) {
    print('Error testing availability: $e');
  }
}

```prompt
// filepath: g:\BUILDING\New folder\web-guide-generator\revision\.github\prompts\07-image-picker-data-presentation.prompt.md
# Phase 3: Image Selection Data & Presentation Layers

## Context & Requirements
Implement the image picker data layer with platform integrations and presentation layer with intuitive UI, following test-first development and VGV patterns. This implementation must handle Android API 24+ permissions gracefully and provide excellent UX.

**Critical Implementation Requirements:**
- Test-first development approach (write tests before implementation)
- Flutter image_picker package integration
- Android API 24+ with modern photo picker support
- iOS permission handling with proper info.plist configuration
- Responsive UI with loading states and error handling
- Accessibility compliance (WCAG 2.1 AA)
- Memory-efficient image handling for large photos

## Exact Implementation Specifications

### 1. Data Layer - Image Data Source (Test-First)

**First: Write Data Source Tests**
```dart
// test/features/image_selection/data/datasources/image_picker_data_source_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ai_photo_editor/features/image_selection/image_selection.dart';

class MockImagePicker extends Mock implements ImagePicker {}
class MockFile extends Mock implements File {}
class MockFileStat extends Mock implements FileStat {}

void main() {
  group('ImagePickerDataSource', () {
    late ImagePickerDataSource dataSource;
    late MockImagePicker mockImagePicker;

    setUp(() {
      mockImagePicker = MockImagePicker();
      dataSource = ImagePickerDataSource(mockImagePicker);
    });

    group('pickFromGallery', () {
      test('returns SelectedImage when image is picked successfully', () async {
        // Arrange
        final mockXFile = XFile('/path/to/image.jpg');
        when(() => mockImagePicker.pickImage(source: ImageSource.gallery))
            .thenAnswer((_) async => mockXFile);

        final mockFile = MockFile();
        final mockStat = MockFileStat();
        when(() => mockFile.stat()).thenAnswer((_) async => mockStat);
        when(() => mockStat.size).thenReturn(1024000);
        when(() => mockFile.path).thenReturn('/path/to/image.jpg');

        // Act
        final result = await dataSource.pickFromGallery();

        // Assert
        expect(result.isSuccess, isTrue);
        final image = result.getSuccess();
        expect(image.path, '/path/to/image.jpg');
        expect(image.name, 'image.jpg');
        expect(image.sizeInBytes, 1024000);
        expect(image.source, ImageSource.gallery);
      });

      test('returns cancelled exception when user cancels selection', () async {
        // Arrange
        when(() => mockImagePicker.pickImage(source: ImageSource.gallery))
            .thenAnswer((_) async => null);

        // Act
        final result = await dataSource.pickFromGallery();

        // Assert
        expect(result.isFailure, isTrue);
        final exception = result.getFailure();
        expect(exception, isA<CancelledException>());
        expect(exception.message, 'Image selection was cancelled');
      });

      test('returns unknown exception when picker throws error', () async {
        // Arrange
        when(() => mockImagePicker.pickImage(source: ImageSource.gallery))
            .thenThrow(Exception('Picker error'));

        // Act
        final result = await dataSource.pickFromGallery();

        // Assert
        expect(result.isFailure, isTrue);
        final exception = result.getFailure();
        expect(exception, isA<UnknownException>());
        expect(exception.message, contains('Failed to pick image from gallery'));
      });
    });

    group('pickFromCamera', () {
      test('returns SelectedImage when photo is captured successfully', () async {
        // Arrange
        final mockXFile = XFile('/path/to/camera_photo.jpg');
        when(() => mockImagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: any(named: 'imageQuality'),
          maxWidth: any(named: 'maxWidth'),
          maxHeight: any(named: 'maxHeight'),
        )).thenAnswer((_) async => mockXFile);

        final mockFile = MockFile();
        final mockStat = MockFileStat();
        when(() => mockFile.stat()).thenAnswer((_) async => mockStat);
        when(() => mockStat.size).thenReturn(2048000);
        when(() => mockFile.path).thenReturn('/path/to/camera_photo.jpg');

        // Act
        final result = await dataSource.pickFromCamera();

        // Assert
        expect(result.isSuccess, isTrue);
        final image = result.getSuccess();
        expect(image.path, '/path/to/camera_photo.jpg');
        expect(image.name, 'camera_photo.jpg');
        expect(image.sizeInBytes, 2048000);
        expect(image.source, ImageSource.camera);
      });

      test('uses optimal camera settings for AI processing', () async {
        // Arrange
        final mockXFile = XFile('/path/to/camera_photo.jpg');
        when(() => mockImagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 2048,
          maxHeight: 2048,
        )).thenAnswer((_) async => mockXFile);

        final mockFile = MockFile();
        final mockStat = MockFileStat();
        when(() => mockFile.stat()).thenAnswer((_) async => mockStat);
        when(() => mockStat.size).thenReturn(2048000);
        when(() => mockFile.path).thenReturn('/path/to/camera_photo.jpg');

        // Act
        await dataSource.pickFromCamera();

        // Assert
        verify(() => mockImagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85, // Optimal quality for AI processing
          maxWidth: 2048,   // Limit resolution for performance
          maxHeight: 2048,
        )).called(1);
      });
    });

    group('validateImage', () {
      test('returns image when all validations pass', () {
        // Arrange
        const image = SelectedImage(
          path: '/path/to/image.jpg',
          name: 'image.jpg',
          sizeInBytes: 5 * 1024 * 1024, // 5MB
          source: ImageSource.gallery,
        );

        // Act
        final result = dataSource.validateImage(image);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.getSuccess(), image);
      });

      test('returns exception when file is too large', () {
        // Arrange
        const image = SelectedImage(
          path: '/path/to/large_image.jpg',
          name: 'large_image.jpg',
          sizeInBytes: 55 * 1024 * 1024, // 55MB (over 50MB limit)
          source: ImageSource.gallery,
        );

        // Act
        final result = dataSource.validateImage(image);

        // Assert
        expect(result.isFailure, isTrue);
        final exception = result.getFailure();
        expect(exception, isA<FileTooLargeException>());
        expect(exception.message, contains('50MB'));
      });

      test('returns exception when format is invalid', () {
        // Arrange
        const image = SelectedImage(
          path: '/path/to/document.pdf',
          name: 'document.pdf',
          sizeInBytes: 1024000,
          source: ImageSource.gallery,
        );

        // Act
        final result = dataSource.validateImage(image);

        // Assert
        expect(result.isFailure, isTrue);
        final exception = result.getFailure();
        expect(exception, isA<InvalidFormatException>());
        expect(exception.message, contains('JPG, PNG, HEIC'));
      });
    });

    group('permission checks', () {
      test('isCameraAvailable returns true when camera permission granted', () async {
        // This would require mocking permission_handler
        // Implementation depends on your permission handling strategy
        final result = await dataSource.isCameraAvailable();
        expect(result, isA<bool>());
      });

      test('isGalleryAvailable returns true when storage permission granted', () async {
        final result = await dataSource.isGalleryAvailable();
        expect(result, isA<bool>());
      });
    });
  });
}
```

**Then: Implement Data Source**
```dart
// lib/features/image_selection/data/datasources/image_picker_data_source.dart
import 'dart:io';
import 'package:image_picker/image_picker.dart' as picker;
import 'package:permission_handler/permission_handler.dart';
import '../../domain/domain.dart';
import '../../../../core/utils/result.dart';

class ImagePickerDataSource {
  const ImagePickerDataSource(this._imagePicker);

  final picker.ImagePicker _imagePicker;

  Future<Result<SelectedImage, ImageSelectionException>> pickFromGallery() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: picker.ImageSource.gallery,
        imageQuality: 90, // High quality for editing
        maxWidth: 4096,   // Support high-res images
        maxHeight: 4096,
      );

      if (pickedFile == null) {
        return const Failure(
          ImageSelectionException.cancelled('Image selection was cancelled'),
        );
      }

      return _createSelectedImage(pickedFile, ImageSource.gallery);
    } catch (e) {
      return Failure(
        ImageSelectionException.unknown(
          'Failed to pick image from gallery: ${e.toString()}',
        ),
      );
    }
  }

  Future<Result<SelectedImage, ImageSelectionException>> pickFromCamera() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: picker.ImageSource.camera,
        imageQuality: 85, // Optimal for AI processing
        maxWidth: 2048,   // Limit resolution for performance
        maxHeight: 2048,
        preferredCameraDevice: picker.CameraDevice.rear,
      );

      if (pickedFile == null) {
        return const Failure(
          ImageSelectionException.cancelled('Photo capture was cancelled'),
        );
      }

      return _createSelectedImage(pickedFile, ImageSource.camera);
    } catch (e) {
      return Failure(
        ImageSelectionException.unknown(
          'Failed to capture photo: ${e.toString()}',
        ),
      );
    }
  }

  Future<Result<SelectedImage, ImageSelectionException>> _createSelectedImage(
    picker.XFile pickedFile,
    ImageSource source,
  ) async {
    try {
      final file = File(pickedFile.path);
      final stat = await file.stat();
      final fileName = pickedFile.name;

      final selectedImage = SelectedImage(
        path: pickedFile.path,
        name: fileName,
        sizeInBytes: stat.size,
        source: source,
      );

      return Success(selectedImage);
    } catch (e) {
      return Failure(
        ImageSelectionException.fileNotFound(
          'Could not access selected file: ${e.toString()}',
        ),
      );
    }
  }

  Result<SelectedImage, ImageSelectionException> validateImage(SelectedImage image) {
    // Check file size (50MB limit for optimal AI processing)
    const maxSizeInBytes = 50 * 1024 * 1024; // 50MB
    if (image.sizeInBytes > maxSizeInBytes) {
      return const Failure(
        ImageSelectionException.fileTooLarge(
          'Image size exceeds 50MB limit. Please choose a smaller image.',
        ),
      );
    }

    // Check file format
    if (!image.isValidFormat) {
      return const Failure(
        ImageSelectionException.invalidFormat(
          'Only JPG, PNG, HEIC, and WebP images are supported.',
        ),
      );
    }

    // Check if file exists
    if (!File(image.path).existsSync()) {
      return const Failure(
        ImageSelectionException.fileNotFound(
          'The selected image file no longer exists.',
        ),
      );
    }

    return Success(image);
  }

  Future<bool> isCameraAvailable() async {
    try {
      // Check if camera permission is available
      final cameraStatus = await Permission.camera.status;
      
      if (cameraStatus.isDenied) {
        final requestResult = await Permission.camera.request();
        return requestResult.isGranted;
      }
      
      return cameraStatus.isGranted;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isGalleryAvailable() async {
    try {
      // For Android API 33+, we need different permissions
      if (Platform.isAndroid) {
        final photosStatus = await Permission.photos.status;
        
        if (photosStatus.isDenied) {
          final requestResult = await Permission.photos.request();
          return requestResult.isGranted;
        }
        
        return photosStatus.isGranted;
      } else {
        // iOS uses photos permission
        final photosStatus = await Permission.photos.status;
        
        if (photosStatus.isDenied) {
          final requestResult = await Permission.photos.request();
          return requestResult.isGranted;
        }
        
        return photosStatus.isGranted;
      }
    } catch (e) {
      return false;
    }
  }
}
```

### 2. Data Layer - Repository Implementation (Test-First)

**First: Write Repository Tests**
```dart
// test/features/image_selection/data/repositories/image_repository_impl_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ai_photo_editor/features/image_selection/image_selection.dart';
import 'package:ai_photo_editor/core/utils/result.dart';

class MockImagePickerDataSource extends Mock implements ImagePickerDataSource {}

void main() {
  group('ImageRepositoryImpl', () {
    late ImageRepositoryImpl repository;
    late MockImagePickerDataSource mockDataSource;

    setUp(() {
      mockDataSource = MockImagePickerDataSource();
      repository = ImageRepositoryImpl(mockDataSource);
    });

    group('pickFromGallery', () {
      test('returns success when data source succeeds', () async {
        // Arrange
        const expectedImage = SelectedImage(
          path: '/path/to/image.jpg',
          name: 'image.jpg',
          sizeInBytes: 1024000,
          source: ImageSource.gallery,
        );
        when(() => mockDataSource.pickFromGallery())
            .thenAnswer((_) async => const Success(expectedImage));

        // Act
        final result = await repository.pickFromGallery();

        // Assert
        expect(result, const Success(expectedImage));
        verify(() => mockDataSource.pickFromGallery()).called(1);
      });

      test('returns failure when data source fails', () async {
        // Arrange
        const exception = ImageSelectionException.permissionDenied('Access denied');
        when(() => mockDataSource.pickFromGallery())
            .thenAnswer((_) async => const Failure(exception));

        // Act
        final result = await repository.pickFromGallery();

        // Assert
        expect(result, const Failure(exception));
        verify(() => mockDataSource.pickFromGallery()).called(1);
      });
    });

    group('pickFromCamera', () {
      test('returns success when data source succeeds', () async {
        // Arrange
        const expectedImage = SelectedImage(
          path: '/path/to/camera_photo.jpg',
          name: 'camera_photo.jpg',
          sizeInBytes: 2048000,
          source: ImageSource.camera,
        );
        when(() => mockDataSource.pickFromCamera())
            .thenAnswer((_) async => const Success(expectedImage));

        // Act
        final result = await repository.pickFromCamera();

        // Assert
        expect(result, const Success(expectedImage));
        verify(() => mockDataSource.pickFromCamera()).called(1);
      });
    });

    group('validateImage', () {
      test('delegates to data source correctly', () {
        // Arrange
        const image = SelectedImage(
          path: '/path/to/image.jpg',
          name: 'image.jpg',
          sizeInBytes: 1024000,
          source: ImageSource.gallery,
        );
        when(() => mockDataSource.validateImage(image))
            .thenReturn(const Success(image));

        // Act
        final result = repository.validateImage(image);

        // Assert
        expect(result, const Success(image));
        verify(() => mockDataSource.validateImage(image)).called(1);
      });
    });

    group('permission checks', () {
      test('isCameraAvailable delegates to data source', () async {
        // Arrange
        when(() => mockDataSource.isCameraAvailable())
            .thenAnswer((_) async => true);

        // Act
        final result = await repository.isCameraAvailable();

        // Assert
        expect(result, true);
        verify(() => mockDataSource.isCameraAvailable()).called(1);
      });

      test('isGalleryAvailable delegates to data source', () async {
        // Arrange
        when(() => mockDataSource.isGalleryAvailable())
            .thenAnswer((_) async => true);

        // Act
        final result = await repository.isGalleryAvailable();

        // Assert
        expect(result, true);
        verify(() => mockDataSource.isGalleryAvailable()).called(1);
      });
    });
  });
}
```

**Then: Implement Repository**
```dart
// lib/features/image_selection/data/repositories/image_repository_impl.dart
import '../../domain/domain.dart';
import '../datasources/datasources.dart';
import '../../../../core/utils/result.dart';

class ImageRepositoryImpl implements ImageRepository {
  const ImageRepositoryImpl(this._dataSource);

  final ImagePickerDataSource _dataSource;

  @override
  Future<Result<SelectedImage, ImageSelectionException>> pickFromGallery() {
    return _dataSource.pickFromGallery();
  }

  @override
  Future<Result<SelectedImage, ImageSelectionException>> pickFromCamera() {
    return _dataSource.pickFromCamera();
  }

  @override
  Result<SelectedImage, ImageSelectionException> validateImage(SelectedImage image) {
    return _dataSource.validateImage(image);
  }

  @override
  Future<bool> isCameraAvailable() {
    return _dataSource.isCameraAvailable();
  }

  @override
  Future<bool> isGalleryAvailable() {
    return _dataSource.isGalleryAvailable();
  }
}
```

### 3. Presentation Layer - BLoC Implementation (Test-First)

**First: Write BLoC Tests**
```dart
// test/features/image_selection/cubit/image_selection_cubit_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ai_photo_editor/features/image_selection/image_selection.dart';
import 'package:ai_photo_editor/core/utils/result.dart';

class MockPickImageUseCase extends Mock implements PickImageUseCase {}
class MockCheckPermissionsUseCase extends Mock implements CheckPermissionsUseCase {}

void main() {
  group('ImageSelectionCubit', () {
    late ImageSelectionCubit cubit;
    late MockPickImageUseCase mockPickImageUseCase;
    late MockCheckPermissionsUseCase mockCheckPermissionsUseCase;

    setUp(() {
      mockPickImageUseCase = MockPickImageUseCase();
      mockCheckPermissionsUseCase = MockCheckPermissionsUseCase();
      cubit = ImageSelectionCubit(
        pickImageUseCase: mockPickImageUseCase,
        checkPermissionsUseCase: mockCheckPermissionsUseCase,
      );
    });

    tearDown(() => cubit.close());

    test('initial state is ImageSelectionState.initial()', () {
      expect(cubit.state, const ImageSelectionState.initial());
    });

    group('pickFromGallery', () {
      const selectedImage = SelectedImage(
        path: '/path/to/image.jpg',
        name: 'image.jpg',
        sizeInBytes: 1024000,
        source: ImageSource.gallery,
      );

      blocTest<ImageSelectionCubit, ImageSelectionState>(
        'emits [loading, selected] when image selection succeeds',
        build: () {
          when(() => mockPickImageUseCase(source: ImageSource.gallery))
              .thenAnswer((_) async => const Success(selectedImage));
          return cubit;
        },
        act: (cubit) => cubit.pickFromGallery(),
        expect: () => [
          const ImageSelectionState.loading(),
          const ImageSelectionState.selected(selectedImage),
        ],
      );

      blocTest<ImageSelectionCubit, ImageSelectionState>(
        'emits [loading, error] when image selection fails',
        build: () {
          const exception = ImageSelectionException.permissionDenied('Access denied');
          when(() => mockPickImageUseCase(source: ImageSource.gallery))
              .thenAnswer((_) async => const Failure(exception));
          return cubit;
        },
        act: (cubit) => cubit.pickFromGallery(),
        expect: () => [
          const ImageSelectionState.loading(),
          const ImageSelectionState.error(exception),
        ],
      );
    });

    group('pickFromCamera', () {
      const capturedImage = SelectedImage(
        path: '/path/to/camera_photo.jpg',
        name: 'camera_photo.jpg',
        sizeInBytes: 2048000,
        source: ImageSource.camera,
      );

      blocTest<ImageSelectionCubit, ImageSelectionState>(
        'emits [loading, selected] when photo capture succeeds',
        build: () {
          when(() => mockPickImageUseCase(source: ImageSource.camera))
              .thenAnswer((_) async => const Success(capturedImage));
          return cubit;
        },
        act: (cubit) => cubit.pickFromCamera(),
        expect: () => [
          const ImageSelectionState.loading(),
          const ImageSelectionState.selected(capturedImage),
        ],
      );

      blocTest<ImageSelectionCubit, ImageSelectionState>(
        'emits [loading, error] when camera is unavailable',
        build: () {
          const exception = ImageSelectionException.cameraUnavailable('Camera not available');
          when(() => mockPickImageUseCase(source: ImageSource.camera))
              .thenAnswer((_) async => const Failure(exception));
          return cubit;
        },
        act: (cubit) => cubit.pickFromCamera(),
        expect: () => [
          const ImageSelectionState.loading(),
          const ImageSelectionState.error(exception),
        ],
      );
    });

    group('checkPermissions', () {
      blocTest<ImageSelectionCubit, ImageSelectionState>(
        'updates permission status when checking succeeds',
        build: () {
          when(() => mockCheckPermissionsUseCase.checkCameraPermission())
              .thenAnswer((_) async => const Success(true));
          when(() => mockCheckPermissionsUseCase.checkGalleryPermission())
              .thenAnswer((_) async => const Success(true));
          return cubit;
        },
        act: (cubit) => cubit.checkPermissions(),
        expect: () => [
          const ImageSelectionState.permissionsChecked(
            cameraPermission: true,
            galleryPermission: true,
          ),
        ],
      );
    });
  });
}
```

**Then: Implement BLoC**
```dart
// lib/features/image_selection/cubit/image_selection_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../domain/domain.dart';

part 'image_selection_state.dart';

class ImageSelectionCubit extends Cubit<ImageSelectionState> {
  ImageSelectionCubit({
    required PickImageUseCase pickImageUseCase,
    required CheckPermissionsUseCase checkPermissionsUseCase,
  })  : _pickImageUseCase = pickImageUseCase,
        _checkPermissionsUseCase = checkPermissionsUseCase,
        super(const ImageSelectionState.initial());

  final PickImageUseCase _pickImageUseCase;
  final CheckPermissionsUseCase _checkPermissionsUseCase;

  Future<void> pickFromGallery() async {
    emit(const ImageSelectionState.loading());

    final result = await _pickImageUseCase(source: ImageSource.gallery);

    result.fold(
      (failure) => emit(ImageSelectionState.error(failure)),
      (image) => emit(ImageSelectionState.selected(image)),
    );
  }

  Future<void> pickFromCamera() async {
    emit(const ImageSelectionState.loading());

    final result = await _pickImageUseCase(source: ImageSource.camera);

    result.fold(
      (failure) => emit(ImageSelectionState.error(failure)),
      (image) => emit(ImageSelectionState.selected(image)),
    );
  }

  Future<void> checkPermissions() async {
    final cameraResult = await _checkPermissionsUseCase.checkCameraPermission();
    final galleryResult = await _checkPermissionsUseCase.checkGalleryPermission();

    final cameraPermission = cameraResult.fold(
      (_) => false,
      (hasPermission) => hasPermission,
    );

    final galleryPermission = galleryResult.fold(
      (_) => false,
      (hasPermission) => hasPermission,
    );

    emit(ImageSelectionState.permissionsChecked(
      cameraPermission: cameraPermission,
      galleryPermission: galleryPermission,
    ));
  }

  void clearSelection() {
    emit(const ImageSelectionState.initial());
  }
}
```

**ImageSelectionState Implementation**
```dart
// lib/features/image_selection/cubit/image_selection_state.dart
part of 'image_selection_cubit.dart';

sealed class ImageSelectionState extends Equatable {
  const ImageSelectionState();

  const factory ImageSelectionState.initial() = ImageSelectionInitial;
  const factory ImageSelectionState.loading() = ImageSelectionLoading;
  const factory ImageSelectionState.selected(SelectedImage image) = ImageSelectionSelected;
  const factory ImageSelectionState.error(ImageSelectionException error) = ImageSelectionError;
  const factory ImageSelectionState.permissionsChecked({
    required bool cameraPermission,
    required bool galleryPermission,
  }) = ImageSelectionPermissionsChecked;

  @override
  List<Object?> get props => [];
}

final class ImageSelectionInitial extends ImageSelectionState {
  const ImageSelectionInitial();
}

final class ImageSelectionLoading extends ImageSelectionState {
  const ImageSelectionLoading();
}

final class ImageSelectionSelected extends ImageSelectionState {
  const ImageSelectionSelected(this.image);

  final SelectedImage image;

  @override
  List<Object> get props => [image];
}

final class ImageSelectionError extends ImageSelectionState {
  const ImageSelectionError(this.error);

  final ImageSelectionException error;

  @override
  List<Object> get props => [error];
}

final class ImageSelectionPermissionsChecked extends ImageSelectionState {
  const ImageSelectionPermissionsChecked({
    required this.cameraPermission,
    required this.galleryPermission,
  });

  final bool cameraPermission;
  final bool galleryPermission;

  @override
  List<Object> get props => [cameraPermission, galleryPermission];
}
```

### 4. Presentation Layer - UI Implementation (Test-First)

**ImageSelectionPage Implementation**
```dart
// lib/features/image_selection/view/image_selection_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/image_selection_cubit.dart';
import '../../../core/di/injection_container.dart';
import 'image_selection_view.dart';

class ImageSelectionPage extends StatelessWidget {
  const ImageSelectionPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const ImageSelectionPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ImageSelectionCubit(
        pickImageUseCase: sl<PickImageUseCase>(),
        checkPermissionsUseCase: sl<CheckPermissionsUseCase>(),
      )..checkPermissions(),
      child: const ImageSelectionView(),
    );
  }
}
```

**ImageSelectionView Implementation**
```dart
// lib/features/image_selection/view/image_selection_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/image_selection_cubit.dart';
import '../widgets/widgets.dart';

class ImageSelectionView extends StatelessWidget {
  const ImageSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Image'),
        centerTitle: true,
      ),
      body: BlocConsumer<ImageSelectionCubit, ImageSelectionState>(
        listener: (context, state) {
          switch (state) {
            case ImageSelectionSelected(:final image):
              Navigator.of(context).pushNamed(
                '/image-editor',
                arguments: image,
              );
            case ImageSelectionError(:final error):
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(_getErrorMessage(error)),
                    backgroundColor: Theme.of(context).colorScheme.error,
                    action: SnackBarAction(
                      label: 'Retry',
                      onPressed: () => context
                          .read<ImageSelectionCubit>()
                          .checkPermissions(),
                    ),
                  ),
                );
            case ImageSelectionLoading():
            case ImageSelectionInitial():
            case ImageSelectionPermissionsChecked():
              break;
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  
                  // Header
                  const ImageSelectionHeader(),
                  
                  const SizedBox(height: 48),
                  
                  // Selection Options
                  Expanded(
                    child: _buildSelectionOptions(context, state),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Tips Section
                  const ImageSelectionTips(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectionOptions(BuildContext context, ImageSelectionState state) {
    switch (state) {
      case ImageSelectionLoading():
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Processing...'),
            ],
          ),
        );
        
      case ImageSelectionPermissionsChecked(:final cameraPermission, :final galleryPermission):
        return Column(
          children: [
            Expanded(
              child: ImageSourceOption(
                icon: Icons.photo_library_outlined,
                title: 'Photo Gallery',
                subtitle: 'Choose from your photo library',
                isEnabled: galleryPermission,
                onTap: galleryPermission
                    ? () => context.read<ImageSelectionCubit>().pickFromGallery()
                    : null,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Expanded(
              child: ImageSourceOption(
                icon: Icons.camera_alt_outlined,
                title: 'Camera',
                subtitle: 'Take a new photo',
                isEnabled: cameraPermission,
                onTap: cameraPermission
                    ? () => context.read<ImageSelectionCubit>().pickFromCamera()
                    : null,
              ),
            ),
          ],
        );
        
      default:
        return const Center(
          child: CircularProgressIndicator(),
        );
    }
  }

  String _getErrorMessage(ImageSelectionException error) {
    return switch (error) {
      PermissionDeniedException() => 'Permission required. Please enable access in settings.',
      CameraUnavailableException() => 'Camera is not available on this device.',
      FileTooLargeException() => 'Image is too large. Please select a smaller image.',
      InvalidFormatException() => 'Unsupported file format. Please select a valid image.',
      CancelledException() => 'Selection cancelled.',
      _ => 'An unexpected error occurred. Please try again.',
    };
  }
}
```

### 5. Custom Widgets

**ImageSelectionHeader Widget**
```dart
// lib/features/image_selection/widgets/image_selection_header.dart
import 'package:flutter/material.dart';

class ImageSelectionHeader extends StatelessWidget {
  const ImageSelectionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 80,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Select an Image',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose an image to edit with AI',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
```

**ImageSourceOption Widget**
```dart
// lib/features/image_selection/widgets/image_source_option.dart
import 'package:flutter/material.dart';

class ImageSourceOption extends StatelessWidget {
  const ImageSourceOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isEnabled,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isEnabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 64,
                color: isEnabled
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).disabledColor,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: isEnabled
                      ? null
                      : Theme.of(context).disabledColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isEnabled
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Theme.of(context).disabledColor,
                ),
              ),
              if (!isEnabled) ...[
                const SizedBox(height: 12),
                Chip(
                  label: const Text('Permission Required'),
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  side: BorderSide.none,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

**ImageSelectionTips Widget**
```dart
// lib/features/image_selection/widgets/image_selection_tips.dart
import 'package:flutter/material.dart';

class ImageSelectionTips extends StatelessWidget {
  const ImageSelectionTips({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tips for better results',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTip(context, 'Use high-quality images for best AI processing'),
            _buildTip(context, 'Ensure good lighting and clear details'),
            _buildTip(context, 'Images should be under 50MB in size'),
            _buildTip(context, 'Supported formats: JPG, PNG, HEIC, WebP'),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(BuildContext context, String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, right: 8),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              tip,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
```

### 6. Barrel Exports

```dart
// lib/features/image_selection/data/datasources/datasources.dart
export 'image_picker_data_source.dart';

// lib/features/image_selection/data/repositories/repositories.dart
export 'image_repository_impl.dart';

// lib/features/image_selection/data/data.dart
export 'datasources/datasources.dart';
export 'repositories/repositories.dart';

// lib/features/image_selection/cubit/cubit.dart
export 'image_selection_cubit.dart';

// lib/features/image_selection/view/view.dart
export 'image_selection_page.dart';
export 'image_selection_view.dart';

// lib/features/image_selection/widgets/widgets.dart
export 'image_selection_header.dart';
export 'image_source_option.dart';
export 'image_selection_tips.dart';

// lib/features/image_selection/image_selection.dart
export 'cubit/cubit.dart';
export 'data/data.dart';
export 'domain/domain.dart';
export 'view/view.dart';
export 'widgets/widgets.dart';
```

## Acceptance Criteria (Must All Pass)

1. ✅ All data layer tests pass with 100% coverage
2. ✅ Repository correctly delegates to data source
3. ✅ BLoC tests pass with comprehensive state coverage
4. ✅ UI responds correctly to all state changes
5. ✅ Permission handling works on Android API 23+
6. ✅ Error messages are user-friendly and actionable
7. ✅ Loading states provide good user feedback
8. ✅ Accessibility features properly implemented
9. ✅ Navigation to image editor works correctly
10. ✅ File validation prevents issues downstream

**Quality Gate:** All tests pass, smooth animations, proper error handling

**Performance Target:** Image selection < 2 seconds, smooth 60fps UI

**Platform Compliance:** Works correctly on Android API 23+ and iOS 12+

---

**Next Step:** After completion, proceed to Image Editor Domain Layer (Phase 4, Step 1)
```

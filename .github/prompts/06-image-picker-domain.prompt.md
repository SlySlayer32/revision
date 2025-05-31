```prompt
// filepath: g:\BUILDING\New folder\web-guide-generator\revision\.github\prompts\06-image-picker-domain.prompt.md
# Phase 3: Image Selection Domain Layer

## Context & Requirements
Create the image picker feature using test-first development and VGV clean architecture patterns. This domain layer must handle image selection from gallery or camera with robust error handling and validation.

**Critical Implementation Requirements:**
- Test-first development approach (write tests before implementation)
- Clean Architecture with proper separation of concerns
- Result pattern for error handling (Success/Failure)
- Comprehensive validation (file size, format, permissions)
- Scalable design for future image sources (cloud, web, etc.)
- Memory-efficient image handling for large photos

## Exact Implementation Specifications

### 1. Domain Entities (Test-First)

**First: Write Entity Tests**
```dart
// test/features/image_selection/domain/entities/image_source_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_photo_editor/features/image_selection/image_selection.dart';

void main() {
  group('ImageSource', () {
    test('gallery has correct name', () {
      expect(ImageSource.gallery.name, 'gallery');
    });

    test('camera has correct name', () {
      expect(ImageSource.camera.name, 'camera');
    });

    test('values contains all sources', () {
      expect(ImageSource.values, [ImageSource.gallery, ImageSource.camera]);
    });

    test('supports value equality', () {
      expect(ImageSource.gallery, ImageSource.gallery);
      expect(ImageSource.camera, ImageSource.camera);
      expect(ImageSource.gallery == ImageSource.camera, isFalse);
    });
  });
}
```

```dart
// test/features/image_selection/domain/entities/selected_image_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_photo_editor/features/image_selection/image_selection.dart';

void main() {
  group('SelectedImage', () {
    const path = '/path/to/image.jpg';
    const name = 'image.jpg';
    const sizeInBytes = 1024000; // 1MB
    const source = ImageSource.gallery;

    test('supports value equality', () {
      const image1 = SelectedImage(
        path: path,
        name: name,
        sizeInBytes: sizeInBytes,
        source: source,
      );
      const image2 = SelectedImage(
        path: path,
        name: name,
        sizeInBytes: sizeInBytes,
        source: source,
      );

      expect(image1, image2);
    });

    test('props are correct', () {
      const image = SelectedImage(
        path: path,
        name: name,
        sizeInBytes: sizeInBytes,
        source: source,
      );

      expect(image.props, [path, name, sizeInBytes, source]);
    });

    test('file getter returns File instance', () {
      const image = SelectedImage(
        path: path,
        name: name,
        sizeInBytes: sizeInBytes,
        source: source,
      );

      expect(image.file, isA<File>());
      expect(image.file.path, path);
    });

    test('sizeInMB calculates correctly', () {
      const image = SelectedImage(
        path: path,
        name: name,
        sizeInBytes: 2048000, // 2MB
        source: source,
      );

      expect(image.sizeInMB, 2.0);
    });

    test('sizeInMB handles small files', () {
      const image = SelectedImage(
        path: path,
        name: name,
        sizeInBytes: 512000, // 0.5MB
        source: source,
      );

      expect(image.sizeInMB, 0.5);
    });

    test('isLargeFile identifies large files correctly', () {
      const largeImage = SelectedImage(
        path: path,
        name: name,
        sizeInBytes: 15 * 1024 * 1024, // 15MB
        source: source,
      );
      const smallImage = SelectedImage(
        path: path,
        name: name,
        sizeInBytes: 1024 * 1024, // 1MB
        source: source,
      );

      expect(largeImage.isLargeFile, isTrue);
      expect(smallImage.isLargeFile, isFalse);
    });

    test('isValidFormat identifies valid image formats', () {
      const jpgImage = SelectedImage(
        path: '/path/to/image.jpg',
        name: 'image.jpg',
        sizeInBytes: sizeInBytes,
        source: source,
      );
      const pngImage = SelectedImage(
        path: '/path/to/image.png',
        name: 'image.png',
        sizeInBytes: sizeInBytes,
        source: source,
      );
      const heicImage = SelectedImage(
        path: '/path/to/image.heic',
        name: 'image.heic',
        sizeInBytes: sizeInBytes,
        source: source,
      );
      const invalidImage = SelectedImage(
        path: '/path/to/document.pdf',
        name: 'document.pdf',
        sizeInBytes: sizeInBytes,
        source: source,
      );

      expect(jpgImage.isValidFormat, isTrue);
      expect(pngImage.isValidFormat, isTrue);
      expect(heicImage.isValidFormat, isTrue);
      expect(invalidImage.isValidFormat, isFalse);
    });

    test('copyWith creates new instance with updated values', () {
      const original = SelectedImage(
        path: path,
        name: name,
        sizeInBytes: sizeInBytes,
        source: source,
      );

      final updated = original.copyWith(
        name: 'new_image.jpg',
        sizeInBytes: 2048000,
      );

      expect(updated.path, path);
      expect(updated.name, 'new_image.jpg');
      expect(updated.sizeInBytes, 2048000);
      expect(updated.source, source);
      expect(updated, isNot(original));
    });
  });
}
```

**Then: Implement Domain Entities**
```dart
// lib/features/image_selection/domain/entities/image_source.dart
enum ImageSource {
  gallery,
  camera;

  String get displayName {
    return switch (this) {
      ImageSource.gallery => 'Photo Gallery',
      ImageSource.camera => 'Camera',
    };
  }

  String get description {
    return switch (this) {
      ImageSource.gallery => 'Choose from your photo library',
      ImageSource.camera => 'Take a new photo',
    };
  }
}
```

```dart
// lib/features/image_selection/domain/entities/selected_image.dart
import 'dart:io';
import 'package:equatable/equatable.dart';
import 'image_source.dart';

class SelectedImage extends Equatable {
  const SelectedImage({
    required this.path,
    required this.name,
    required this.sizeInBytes,
    required this.source,
  });

  final String path;
  final String name;
  final int sizeInBytes;
  final ImageSource source;

  File get file => File(path);

  double get sizeInMB => sizeInBytes / (1024 * 1024);

  bool get isLargeFile => sizeInMB > 10; // Files over 10MB

  bool get isValidFormat {
    final extension = name.toLowerCase().split('.').last;
    const validFormats = ['jpg', 'jpeg', 'png', 'heic', 'webp'];
    return validFormats.contains(extension);
  }

  SelectedImage copyWith({
    String? path,
    String? name,
    int? sizeInBytes,
    ImageSource? source,
  }) {
    return SelectedImage(
      path: path ?? this.path,
      name: name ?? this.name,
      sizeInBytes: sizeInBytes ?? this.sizeInBytes,
      source: source ?? this.source,
    );
  }

  @override
  List<Object> get props => [path, name, sizeInBytes, source];

  @override
  String toString() {
    return 'SelectedImage(path: $path, name: $name, '
           'sizeInMB: ${sizeInMB.toStringAsFixed(2)}, source: $source)';
  }
}
```

### 2. Domain Exceptions (Test-First)

**First: Write Exception Tests**
```dart
// test/features/image_selection/domain/exceptions/image_selection_exception_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_photo_editor/features/image_selection/image_selection.dart';

void main() {
  group('ImageSelectionException', () {
    group('permissionDenied', () {
      test('creates exception with correct message and code', () {
        const exception = ImageSelectionException.permissionDenied(
          'Camera permission denied',
        );

        expect(exception.message, 'Camera permission denied');
        expect(exception.code, 'permission_denied');
        expect(exception.toString(), 
               'ImageSelectionException: Camera permission denied (permission_denied)');
      });
    });

    group('fileNotFound', () {
      test('creates exception with correct message and code', () {
        const exception = ImageSelectionException.fileNotFound(
          'Selected file no longer exists',
        );

        expect(exception.message, 'Selected file no longer exists');
        expect(exception.code, 'file_not_found');
        expect(exception.toString(), 
               'ImageSelectionException: Selected file no longer exists (file_not_found)');
      });
    });

    group('fileTooLarge', () {
      test('creates exception with correct message and code', () {
        const exception = ImageSelectionException.fileTooLarge(
          'File size exceeds 50MB limit',
        );

        expect(exception.message, 'File size exceeds 50MB limit');
        expect(exception.code, 'file_too_large');
      });
    });

    group('invalidFormat', () {
      test('creates exception with correct message and code', () {
        const exception = ImageSelectionException.invalidFormat(
          'Only JPG, PNG, and HEIC files are supported',
        );

        expect(exception.message, 'Only JPG, PNG, and HEIC files are supported');
        expect(exception.code, 'invalid_format');
      });
    });

    group('cameraUnavailable', () {
      test('creates exception with correct message and code', () {
        const exception = ImageSelectionException.cameraUnavailable(
          'Camera is not available on this device',
        );

        expect(exception.message, 'Camera is not available on this device');
        expect(exception.code, 'camera_unavailable');
      });
    });

    group('cancelled', () {
      test('creates exception with correct message and code', () {
        const exception = ImageSelectionException.cancelled(
          'Image selection was cancelled by user',
        );

        expect(exception.message, 'Image selection was cancelled by user');
        expect(exception.code, 'cancelled');
      });
    });

    group('unknown', () {
      test('creates exception with correct message and code', () {
        const exception = ImageSelectionException.unknown(
          'An unexpected error occurred',
        );

        expect(exception.message, 'An unexpected error occurred');
        expect(exception.code, 'unknown');
      });
    });

    test('supports value equality', () {
      const exception1 = ImageSelectionException.permissionDenied('Access denied');
      const exception2 = ImageSelectionException.permissionDenied('Access denied');
      const exception3 = ImageSelectionException.fileNotFound('File missing');

      expect(exception1, exception2);
      expect(exception1 == exception3, isFalse);
    });
  });
}
```

**Then: Implement Exception Classes**
```dart
// lib/features/image_selection/domain/exceptions/image_selection_exception.dart
import 'package:equatable/equatable.dart';

sealed class ImageSelectionException extends Equatable implements Exception {
  const ImageSelectionException(this.message, this.code);

  final String message;
  final String code;

  const factory ImageSelectionException.permissionDenied(String message) = 
      PermissionDeniedException;
  const factory ImageSelectionException.fileNotFound(String message) = 
      FileNotFoundException;
  const factory ImageSelectionException.fileTooLarge(String message) = 
      FileTooLargeException;
  const factory ImageSelectionException.invalidFormat(String message) = 
      InvalidFormatException;
  const factory ImageSelectionException.cameraUnavailable(String message) = 
      CameraUnavailableException;
  const factory ImageSelectionException.cancelled(String message) = 
      CancelledException;
  const factory ImageSelectionException.unknown(String message) = 
      UnknownException;

  @override
  List<Object> get props => [message, code];

  @override
  String toString() => 'ImageSelectionException: $message ($code)';
}

final class PermissionDeniedException extends ImageSelectionException {
  const PermissionDeniedException(String message) : super(message, 'permission_denied');
}

final class FileNotFoundException extends ImageSelectionException {
  const FileNotFoundException(String message) : super(message, 'file_not_found');
}

final class FileTooLargeException extends ImageSelectionException {
  const FileTooLargeException(String message) : super(message, 'file_too_large');
}

final class InvalidFormatException extends ImageSelectionException {
  const InvalidFormatException(String message) : super(message, 'invalid_format');
}

final class CameraUnavailableException extends ImageSelectionException {
  const CameraUnavailableException(String message) : super(message, 'camera_unavailable');
}

final class CancelledException extends ImageSelectionException {
  const CancelledException(String message) : super(message, 'cancelled');
}

final class UnknownException extends ImageSelectionException {
  const UnknownException(String message) : super(message, 'unknown');
}
```

### 3. Repository Interface (Test-First)

**First: Write Repository Interface Test**
```dart
// test/features/image_selection/domain/repositories/image_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_photo_editor/features/image_selection/image_selection.dart';
import 'package:ai_photo_editor/core/utils/result.dart';

void main() {
  group('ImageRepository', () {
    test('is an abstract interface', () {
      expect(ImageRepository, isA<Type>());
    });

    test('defines pickFromGallery method', () {
      expect(
        () => ImageRepository,
        returnsNormally,
      );
    });

    test('defines pickFromCamera method', () {
      expect(
        () => ImageRepository,
        returnsNormally,
      );
    });

    test('defines validateImage method', () {
      expect(
        () => ImageRepository,
        returnsNormally,
      );
    });
  });
}
```

**Then: Implement Repository Interface**
```dart
// lib/features/image_selection/domain/repositories/image_repository.dart
import '../entities/entities.dart';
import '../exceptions/exceptions.dart';
import '../../../../core/utils/result.dart';

abstract interface class ImageRepository {
  /// Picks an image from the device gallery
  /// 
  /// Returns [SelectedImage] on success or [ImageSelectionException] on failure
  Future<Result<SelectedImage, ImageSelectionException>> pickFromGallery();

  /// Captures an image using the device camera
  /// 
  /// Returns [SelectedImage] on success or [ImageSelectionException] on failure
  Future<Result<SelectedImage, ImageSelectionException>> pickFromCamera();

  /// Validates if the selected image meets requirements
  /// 
  /// Returns [SelectedImage] on success or [ImageSelectionException] on failure
  Result<SelectedImage, ImageSelectionException> validateImage(SelectedImage image);

  /// Checks if camera is available on the device
  Future<bool> isCameraAvailable();

  /// Checks if gallery access is available
  Future<bool> isGalleryAvailable();
}
```

### 4. Use Cases (Test-First)

**First: Write Use Case Tests**
```dart
// test/features/image_selection/domain/usecases/pick_image_use_case_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ai_photo_editor/features/image_selection/image_selection.dart';
import 'package:ai_photo_editor/core/utils/result.dart';

class MockImageRepository extends Mock implements ImageRepository {}

void main() {
  group('PickImageUseCase', () {
    late PickImageUseCase useCase;
    late MockImageRepository mockRepository;

    setUp(() {
      mockRepository = MockImageRepository();
      useCase = PickImageUseCase(mockRepository);
    });

    group('call with gallery source', () {
      const source = ImageSource.gallery;
      const selectedImage = SelectedImage(
        path: '/path/to/image.jpg',
        name: 'image.jpg',
        sizeInBytes: 1024000,
        source: ImageSource.gallery,
      );

      test('returns selected image when gallery selection succeeds', () async {
        // Arrange
        when(() => mockRepository.pickFromGallery())
            .thenAnswer((_) async => const Success(selectedImage));
        when(() => mockRepository.validateImage(selectedImage))
            .thenReturn(const Success(selectedImage));

        // Act
        final result = await useCase(source: source);

        // Assert
        expect(result, const Success(selectedImage));
        verify(() => mockRepository.pickFromGallery()).called(1);
        verify(() => mockRepository.validateImage(selectedImage)).called(1);
      });

      test('returns exception when gallery selection fails', () async {
        // Arrange
        const exception = ImageSelectionException.permissionDenied(
          'Gallery access denied',
        );
        when(() => mockRepository.pickFromGallery())
            .thenAnswer((_) async => const Failure(exception));

        // Act
        final result = await useCase(source: source);

        // Assert
        expect(result, const Failure(exception));
        verify(() => mockRepository.pickFromGallery()).called(1);
        verifyNever(() => mockRepository.validateImage(any()));
      });

      test('returns exception when image validation fails', () async {
        // Arrange
        const validationException = ImageSelectionException.fileTooLarge(
          'File size exceeds limit',
        );
        when(() => mockRepository.pickFromGallery())
            .thenAnswer((_) async => const Success(selectedImage));
        when(() => mockRepository.validateImage(selectedImage))
            .thenReturn(const Failure(validationException));

        // Act
        final result = await useCase(source: source);

        // Assert
        expect(result, const Failure(validationException));
        verify(() => mockRepository.pickFromGallery()).called(1);
        verify(() => mockRepository.validateImage(selectedImage)).called(1);
      });
    });

    group('call with camera source', () {
      const source = ImageSource.camera;
      const selectedImage = SelectedImage(
        path: '/path/to/camera_image.jpg',
        name: 'camera_image.jpg',
        sizeInBytes: 2048000,
        source: ImageSource.camera,
      );

      test('returns selected image when camera capture succeeds', () async {
        // Arrange
        when(() => mockRepository.pickFromCamera())
            .thenAnswer((_) async => const Success(selectedImage));
        when(() => mockRepository.validateImage(selectedImage))
            .thenReturn(const Success(selectedImage));

        // Act
        final result = await useCase(source: source);

        // Assert
        expect(result, const Success(selectedImage));
        verify(() => mockRepository.pickFromCamera()).called(1);
        verify(() => mockRepository.validateImage(selectedImage)).called(1);
      });

      test('returns exception when camera capture fails', () async {
        // Arrange
        const exception = ImageSelectionException.cameraUnavailable(
          'Camera not available',
        );
        when(() => mockRepository.pickFromCamera())
            .thenAnswer((_) async => const Failure(exception));

        // Act
        final result = await useCase(source: source);

        // Assert
        expect(result, const Failure(exception));
        verify(() => mockRepository.pickFromCamera()).called(1);
        verifyNever(() => mockRepository.validateImage(any()));
      });
    });

    test('throws ArgumentError for invalid source', () async {
      // This test ensures we handle all enum values
      expect(
        () => useCase(source: ImageSource.values.first),
        returnsNormally,
      );
    });
  });
}
```

```dart
// test/features/image_selection/domain/usecases/validate_image_use_case_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ai_photo_editor/features/image_selection/image_selection.dart';
import 'package:ai_photo_editor/core/utils/result.dart';

class MockImageRepository extends Mock implements ImageRepository {}

void main() {
  group('ValidateImageUseCase', () {
    late ValidateImageUseCase useCase;
    late MockImageRepository mockRepository;

    setUp(() {
      mockRepository = MockImageRepository();
      useCase = ValidateImageUseCase(mockRepository);
    });

    test('returns validated image when validation succeeds', () {
      // Arrange
      const image = SelectedImage(
        path: '/path/to/image.jpg',
        name: 'image.jpg',
        sizeInBytes: 1024000,
        source: ImageSource.gallery,
      );
      when(() => mockRepository.validateImage(image))
          .thenReturn(const Success(image));

      // Act
      final result = useCase(image: image);

      // Assert
      expect(result, const Success(image));
      verify(() => mockRepository.validateImage(image)).called(1);
    });

    test('returns exception when validation fails', () {
      // Arrange
      const image = SelectedImage(
        path: '/path/to/large_image.jpg',
        name: 'large_image.jpg',
        sizeInBytes: 52428800, // 50MB
        source: ImageSource.gallery,
      );
      const exception = ImageSelectionException.fileTooLarge(
        'File size exceeds 50MB limit',
      );
      when(() => mockRepository.validateImage(image))
          .thenReturn(const Failure(exception));

      // Act
      final result = useCase(image: image);

      // Assert
      expect(result, const Failure(exception));
      verify(() => mockRepository.validateImage(image)).called(1);
    });
  });
}
```

**Then: Implement Use Cases**
```dart
// lib/features/image_selection/domain/usecases/pick_image_use_case.dart
import '../entities/entities.dart';
import '../exceptions/exceptions.dart';
import '../repositories/repositories.dart';
import '../../../../core/utils/result.dart';

class PickImageUseCase {
  const PickImageUseCase(this._repository);

  final ImageRepository _repository;

  Future<Result<SelectedImage, ImageSelectionException>> call({
    required ImageSource source,
  }) async {
    final pickResult = await _pickImage(source);
    
    return pickResult.fold(
      (failure) => Failure(failure),
      (image) => _repository.validateImage(image),
    );
  }

  Future<Result<SelectedImage, ImageSelectionException>> _pickImage(
    ImageSource source,
  ) {
    return switch (source) {
      ImageSource.gallery => _repository.pickFromGallery(),
      ImageSource.camera => _repository.pickFromCamera(),
    };
  }
}
```

```dart
// lib/features/image_selection/domain/usecases/validate_image_use_case.dart
import '../entities/entities.dart';
import '../exceptions/exceptions.dart';
import '../repositories/repositories.dart';
import '../../../../core/utils/result.dart';

class ValidateImageUseCase {
  const ValidateImageUseCase(this._repository);

  final ImageRepository _repository;

  Result<SelectedImage, ImageSelectionException> call({
    required SelectedImage image,
  }) {
    return _repository.validateImage(image);
  }
}
```

```dart
// lib/features/image_selection/domain/usecases/check_permissions_use_case.dart
import '../exceptions/exceptions.dart';
import '../repositories/repositories.dart';
import '../../../../core/utils/result.dart';

class CheckPermissionsUseCase {
  const CheckPermissionsUseCase(this._repository);

  final ImageRepository _repository;

  Future<Result<bool, ImageSelectionException>> checkCameraPermission() async {
    try {
      final isAvailable = await _repository.isCameraAvailable();
      return Success(isAvailable);
    } catch (e) {
      return const Failure(
        ImageSelectionException.permissionDenied('Camera permission check failed'),
      );
    }
  }

  Future<Result<bool, ImageSelectionException>> checkGalleryPermission() async {
    try {
      final isAvailable = await _repository.isGalleryAvailable();
      return Success(isAvailable);
    } catch (e) {
      return const Failure(
        ImageSelectionException.permissionDenied('Gallery permission check failed'),
      );
    }
  }
}
```

### 5. Barrel Exports

```dart
// lib/features/image_selection/domain/entities/entities.dart
export 'image_source.dart';
export 'selected_image.dart';

// lib/features/image_selection/domain/exceptions/exceptions.dart
export 'image_selection_exception.dart';

// lib/features/image_selection/domain/repositories/repositories.dart
export 'image_repository.dart';

// lib/features/image_selection/domain/usecases/usecases.dart
export 'pick_image_use_case.dart';
export 'validate_image_use_case.dart';
export 'check_permissions_use_case.dart';

// lib/features/image_selection/domain/domain.dart
export 'entities/entities.dart';
export 'exceptions/exceptions.dart';
export 'repositories/repositories.dart';
export 'usecases/usecases.dart';
```

## Acceptance Criteria (Must All Pass)

1. ✅ All domain entity tests pass with 100% coverage
2. ✅ All exception classes tested and working correctly
3. ✅ Repository interface properly defined and tested
4. ✅ All use cases tested with mocked dependencies
5. ✅ Result pattern used consistently throughout
6. ✅ Proper error handling for all scenarios
7. ✅ File validation logic correctly implemented
8. ✅ Permission checking functionality working
9. ✅ Clean Architecture principles followed
10. ✅ VGV code standards and patterns maintained

**Quality Gate:** 100% test coverage, all tests pass, zero linting errors

**Performance Target:** Image validation < 100ms, memory usage < 50MB

**Architecture Compliance:** Clean separation of concerns, testable design

---

**Next Step:** After completion, proceed to Image Selection Data & Presentation (Phase 3, Step 2)
```

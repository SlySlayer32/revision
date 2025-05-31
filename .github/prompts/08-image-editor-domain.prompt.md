# Image Editor Domain Layer Implementation

## Context
Building the domain layer for the image editor feature of our Flutter AI photo editor app. This layer handles the core business logic for image editing operations, marker management, and AI processing coordination.

## Implementation Requirements

### 1. Domain Entities

Create the core entities that represent our business objects:

```dart
// lib/image_editor/domain/entities/edited_image.dart
import 'dart:typed_data';
import 'package:equatable/equatable.dart';

class EditedImage extends Equatable {
  const EditedImage({
    required this.id,
    required this.originalImageData,
    required this.originalPath,
    required this.markers,
    this.processedImageData,
    this.processedPath,
    required this.createdAt,
    this.modifiedAt,
    this.processingStatus = ProcessingStatus.pending,
    this.aiPrompt,
    this.processingMetadata,
  });

  final String id;
  final Uint8List originalImageData;
  final String originalPath;
  final List<ImageMarker> markers;
  final Uint8List? processedImageData;
  final String? processedPath;
  final DateTime createdAt;
  final DateTime? modifiedAt;
  final ProcessingStatus processingStatus;
  final String? aiPrompt;
  final ProcessingMetadata? processingMetadata;

  @override
  List<Object?> get props => [
        id,
        originalImageData,
        originalPath,
        markers,
        processedImageData,
        processedPath,
        createdAt,
        modifiedAt,
        processingStatus,
        aiPrompt,
        processingMetadata,
      ];

  EditedImage copyWith({
    String? id,
    Uint8List? originalImageData,
    String? originalPath,
    List<ImageMarker>? markers,
    Uint8List? processedImageData,
    String? processedPath,
    DateTime? createdAt,
    DateTime? modifiedAt,
    ProcessingStatus? processingStatus,
    String? aiPrompt,
    ProcessingMetadata? processingMetadata,
  }) {
    return EditedImage(
      id: id ?? this.id,
      originalImageData: originalImageData ?? this.originalImageData,
      originalPath: originalPath ?? this.originalPath,
      markers: markers ?? this.markers,
      processedImageData: processedImageData ?? this.processedImageData,
      processedPath: processedPath ?? this.processedPath,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      processingStatus: processingStatus ?? this.processingStatus,
      aiPrompt: aiPrompt ?? this.aiPrompt,
      processingMetadata: processingMetadata ?? this.processingMetadata,
    );
  }
}

enum ProcessingStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
}
```

```dart
// lib/image_editor/domain/entities/image_marker.dart
import 'package:equatable/equatable.dart';

class ImageMarker extends Equatable {
  const ImageMarker({
    required this.id,
    required this.position,
    required this.type,
    required this.createdAt,
    this.label,
    this.confidence,
    this.metadata,
  });

  final String id;
  final MarkerPosition position;
  final MarkerType type;
  final DateTime createdAt;
  final String? label;
  final double? confidence;
  final Map<String, dynamic>? metadata;

  @override
  List<Object?> get props => [
        id,
        position,
        type,
        createdAt,
        label,
        confidence,
        metadata,
      ];

  ImageMarker copyWith({
    String? id,
    MarkerPosition? position,
    MarkerType? type,
    DateTime? createdAt,
    String? label,
    double? confidence,
    Map<String, dynamic>? metadata,
  }) {
    return ImageMarker(
      id: id ?? this.id,
      position: position ?? this.position,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      label: label ?? this.label,
      confidence: confidence ?? this.confidence,
      metadata: metadata ?? this.metadata,
    );
  }
}

class MarkerPosition extends Equatable {
  const MarkerPosition({
    required this.x,
    required this.y,
    this.width,
    this.height,
  });

  final double x;
  final double y;
  final double? width;
  final double? height;

  @override
  List<Object?> get props => [x, y, width, height];

  MarkerPosition copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
  }) {
    return MarkerPosition(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
}

enum MarkerType {
  userDefined,
  aiDetected,
  objectBoundary,
  regionOfInterest,
}
```

```dart
// lib/image_editor/domain/entities/processing_metadata.dart
import 'package:equatable/equatable.dart';

class ProcessingMetadata extends Equatable {
  const ProcessingMetadata({
    required this.processingStartTime,
    this.processingEndTime,
    this.processingDuration,
    this.aiModel,
    this.parameters,
    this.performance,
    this.error,
  });

  final DateTime processingStartTime;
  final DateTime? processingEndTime;
  final Duration? processingDuration;
  final String? aiModel;
  final Map<String, dynamic>? parameters;
  final ProcessingPerformance? performance;
  final ProcessingError? error;

  @override
  List<Object?> get props => [
        processingStartTime,
        processingEndTime,
        processingDuration,
        aiModel,
        parameters,
        performance,
        error,
      ];
}

class ProcessingPerformance extends Equatable {
  const ProcessingPerformance({
    required this.memoryUsed,
    required this.processingTime,
    this.cpuUsage,
    this.gpuUsage,
  });

  final double memoryUsed;
  final Duration processingTime;
  final double? cpuUsage;
  final double? gpuUsage;

  @override
  List<Object?> get props => [memoryUsed, processingTime, cpuUsage, gpuUsage];
}

class ProcessingError extends Equatable {
  const ProcessingError({
    required this.code,
    required this.message,
    this.details,
    this.timestamp,
  });

  final String code;
  final String message;
  final Map<String, dynamic>? details;
  final DateTime? timestamp;

  @override
  List<Object?> get props => [code, message, details, timestamp];
}
```

### 2. Domain Exceptions

Create specific exceptions for image editor operations:

```dart
// lib/image_editor/domain/exceptions/image_editor_exceptions.dart
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

class MarkerException extends ImageEditorException {
  const MarkerException(super.message);
}

class ProcessingException extends ImageEditorException {
  const ProcessingException(super.message);
}

class InvalidImageFormatException extends ImageEditorException {
  const InvalidImageFormatException(super.message);
}

class InsufficientStorageException extends ImageEditorException {
  const InsufficientStorageException(super.message);
}

class NetworkException extends ImageEditorException {
  const NetworkException(super.message);
}

class PermissionDeniedException extends ImageEditorException {
  const PermissionDeniedException(super.message);
}
```

### 3. Repository Interface

Define the contract for data operations:

```dart
// lib/image_editor/domain/repositories/image_editor_repository.dart
import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../entities/edited_image.dart';
import '../entities/image_marker.dart';
import '../exceptions/image_editor_exceptions.dart';

abstract class ImageEditorRepository {
  Future<Either<ImageEditorException, EditedImage>> loadImage(String path);
  
  Future<Either<ImageEditorException, EditedImage>> saveImage(
    EditedImage image,
  );
  
  Future<Either<ImageEditorException, List<EditedImage>>> getAllImages();
  
  Future<Either<ImageEditorException, EditedImage>> getImageById(String id);
  
  Future<Either<ImageEditorException, void>> deleteImage(String id);
  
  Future<Either<ImageEditorException, EditedImage>> addMarker(
    String imageId,
    ImageMarker marker,
  );
  
  Future<Either<ImageEditorException, EditedImage>> removeMarker(
    String imageId,
    String markerId,
  );
  
  Future<Either<ImageEditorException, EditedImage>> updateMarker(
    String imageId,
    ImageMarker marker,
  );
  
  Future<Either<ImageEditorException, EditedImage>> processImage(
    String imageId,
    String prompt,
  );
  
  Future<Either<ImageEditorException, void>> cancelProcessing(String imageId);
  
  Stream<EditedImage> watchImage(String imageId);
  
  Stream<List<EditedImage>> watchAllImages();
}
```

### 4. Use Cases

Implement the business logic operations:

```dart
// lib/image_editor/domain/usecases/load_image_usecase.dart
import 'package:dartz/dartz.dart';
import '../entities/edited_image.dart';
import '../exceptions/image_editor_exceptions.dart';
import '../repositories/image_editor_repository.dart';

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
```

```dart
// lib/image_editor/domain/usecases/add_marker_usecase.dart
import 'package:dartz/dartz.dart';
import '../entities/edited_image.dart';
import '../entities/image_marker.dart';
import '../exceptions/image_editor_exceptions.dart';
import '../repositories/image_editor_repository.dart';

class AddMarkerUseCase {
  const AddMarkerUseCase(this._repository);

  final ImageEditorRepository _repository;

  Future<Either<ImageEditorException, EditedImage>> call({
    required String imageId,
    required ImageMarker marker,
  }) async {
    if (imageId.isEmpty) {
      return const Left(MarkerException('Image ID cannot be empty'));
    }

    // Validate marker position
    if (marker.position.x < 0 || marker.position.y < 0) {
      return const Left(
        MarkerException('Marker position cannot be negative'),
      );
    }

    try {
      return await _repository.addMarker(imageId, marker);
    } catch (e) {
      return Left(MarkerException('Failed to add marker: $e'));
    }
  }
}
```

```dart
// lib/image_editor/domain/usecases/process_image_usecase.dart
import 'package:dartz/dartz.dart';
import '../entities/edited_image.dart';
import '../exceptions/image_editor_exceptions.dart';
import '../repositories/image_editor_repository.dart';

class ProcessImageUseCase {
  const ProcessImageUseCase(this._repository);

  final ImageEditorRepository _repository;

  Future<Either<ImageEditorException, EditedImage>> call({
    required String imageId,
    required String prompt,
  }) async {
    if (imageId.isEmpty) {
      return const Left(ProcessingException('Image ID cannot be empty'));
    }

    if (prompt.trim().isEmpty) {
      return const Left(ProcessingException('Prompt cannot be empty'));
    }

    // Validate prompt length (reasonable limit for AI processing)
    if (prompt.length > 1000) {
      return const Left(
        ProcessingException('Prompt too long (max 1000 characters)'),
      );
    }

    try {
      return await _repository.processImage(imageId, prompt);
    } catch (e) {
      return Left(ProcessingException('Failed to process image: $e'));
    }
  }
}
```

```dart
// lib/image_editor/domain/usecases/watch_image_usecase.dart
import '../entities/edited_image.dart';
import '../repositories/image_editor_repository.dart';

class WatchImageUseCase {
  const WatchImageUseCase(this._repository);

  final ImageEditorRepository _repository;

  Stream<EditedImage> call(String imageId) {
    return _repository.watchImage(imageId);
  }
}
```

```dart
// lib/image_editor/domain/usecases/get_all_images_usecase.dart
import 'package:dartz/dartz.dart';
import '../entities/edited_image.dart';
import '../exceptions/image_editor_exceptions.dart';
import '../repositories/image_editor_repository.dart';

class GetAllImagesUseCase {
  const GetAllImagesUseCase(this._repository);

  final ImageEditorRepository _repository;

  Future<Either<ImageEditorException, List<EditedImage>>> call() async {
    try {
      return await _repository.getAllImages();
    } catch (e) {
      return Left(ImageLoadException('Failed to load images: $e'));
    }
  }
}
```

### 5. Comprehensive Test Coverage

Create extensive tests for all domain components:

```dart
// test/image_editor/domain/entities/edited_image_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_editor/image_editor/domain/entities/edited_image.dart';
import 'package:photo_editor/image_editor/domain/entities/image_marker.dart';

void main() {
  group('EditedImage', () {
    test('creates instance with required parameters', () {
      final image = EditedImage(
        id: 'test-id',
        originalImageData: Uint8List.fromList([1, 2, 3]),
        originalPath: '/test/path.jpg',
        markers: const [],
        createdAt: DateTime.now(),
      );

      expect(image.id, 'test-id');
      expect(image.originalImageData, Uint8List.fromList([1, 2, 3]));
      expect(image.originalPath, '/test/path.jpg');
      expect(image.markers, isEmpty);
      expect(image.processingStatus, ProcessingStatus.pending);
    });

    test('supports equality comparison', () {
      final now = DateTime.now();
      final image1 = EditedImage(
        id: 'test-id',
        originalImageData: Uint8List.fromList([1, 2, 3]),
        originalPath: '/test/path.jpg',
        markers: const [],
        createdAt: now,
      );

      final image2 = EditedImage(
        id: 'test-id',
        originalImageData: Uint8List.fromList([1, 2, 3]),
        originalPath: '/test/path.jpg',
        markers: const [],
        createdAt: now,
      );

      expect(image1, equals(image2));
    });

    test('copyWith creates new instance with updated fields', () {
      final original = EditedImage(
        id: 'test-id',
        originalImageData: Uint8List.fromList([1, 2, 3]),
        originalPath: '/test/path.jpg',
        markers: const [],
        createdAt: DateTime.now(),
      );

      final updated = original.copyWith(
        processingStatus: ProcessingStatus.completed,
      );

      expect(updated.id, original.id);
      expect(updated.processingStatus, ProcessingStatus.completed);
      expect(original.processingStatus, ProcessingStatus.pending);
    });
  });
}
```

```dart
// test/image_editor/domain/usecases/load_image_usecase_test.dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_editor/image_editor/domain/entities/edited_image.dart';
import 'package:photo_editor/image_editor/domain/exceptions/image_editor_exceptions.dart';
import 'package:photo_editor/image_editor/domain/repositories/image_editor_repository.dart';
import 'package:photo_editor/image_editor/domain/usecases/load_image_usecase.dart';

class MockImageEditorRepository extends Mock implements ImageEditorRepository {}

void main() {
  late LoadImageUseCase useCase;
  late MockImageEditorRepository mockRepository;

  setUp(() {
    mockRepository = MockImageEditorRepository();
    useCase = LoadImageUseCase(mockRepository);
  });

  group('LoadImageUseCase', () {
    const testPath = '/test/image.jpg';
    late EditedImage testImage;

    setUp(() {
      testImage = EditedImage(
        id: 'test-id',
        originalImageData: Uint8List.fromList([1, 2, 3]),
        originalPath: testPath,
        markers: const [],
        createdAt: DateTime.now(),
      );
    });

    test('returns image when repository succeeds', () async {
      // Arrange
      when(() => mockRepository.loadImage(testPath))
          .thenAnswer((_) async => Right(testImage));

      // Act
      final result = await useCase(testPath);

      // Assert
      expect(result, isA<Right<ImageEditorException, EditedImage>>());
      expect(result.fold((l) => null, (r) => r), equals(testImage));
      verify(() => mockRepository.loadImage(testPath)).called(1);
    });

    test('returns failure when path is empty', () async {
      // Act
      final result = await useCase('');

      // Assert
      expect(result, isA<Left<ImageEditorException, EditedImage>>());
      expect(
        result.fold((l) => l, (r) => null),
        isA<ImageLoadException>(),
      );
      verifyNever(() => mockRepository.loadImage(any()));
    });

    test('returns failure when repository fails', () async {
      // Arrange
      when(() => mockRepository.loadImage(testPath))
          .thenAnswer((_) async => const Left(ImageLoadException('Test error')));

      // Act
      final result = await useCase(testPath);

      // Assert
      expect(result, isA<Left<ImageEditorException, EditedImage>>());
      verify(() => mockRepository.loadImage(testPath)).called(1);
    });

    test('handles repository exceptions', () async {
      // Arrange
      when(() => mockRepository.loadImage(testPath))
          .thenThrow(Exception('Network error'));

      // Act
      final result = await useCase(testPath);

      // Assert
      expect(result, isA<Left<ImageEditorException, EditedImage>>());
      expect(
        result.fold((l) => l.message, (r) => null),
        contains('Failed to load image'),
      );
    });
  });
}
```

### 6. Domain Layer Structure

Ensure proper organization:

```
lib/image_editor/domain/
├── entities/
│   ├── edited_image.dart
│   ├── image_marker.dart
│   └── processing_metadata.dart
├── exceptions/
│   └── image_editor_exceptions.dart
├── repositories/
│   └── image_editor_repository.dart
└── usecases/
    ├── add_marker_usecase.dart
    ├── get_all_images_usecase.dart
    ├── load_image_usecase.dart
    ├── process_image_usecase.dart
    ├── remove_marker_usecase.dart
    ├── save_image_usecase.dart
    ├── update_marker_usecase.dart
    └── watch_image_usecase.dart
```

## Quality Standards

### Error Handling
- Validate all inputs before processing
- Provide meaningful error messages
- Handle network timeouts and failures
- Implement retry logic where appropriate

### Performance
- Use streams for real-time updates
- Implement pagination for large image lists
- Optimize memory usage for large images
- Cache frequently accessed data

### Testing
- 100% test coverage for use cases
- Test all error scenarios
- Mock external dependencies
- Integration tests for complex workflows

### Architecture
- Follow clean architecture principles
- Maintain separation of concerns
- Use dependency injection
- Implement proper abstraction layers

## Acceptance Criteria
1. ✅ All entities are immutable and equatable
2. ✅ Repository interface covers all required operations
3. ✅ Use cases validate inputs and handle errors
4. ✅ Comprehensive test coverage (>95%)
5. ✅ No direct dependencies on external frameworks
6. ✅ Proper exception hierarchy
7. ✅ Stream-based reactive patterns
8. ✅ Memory-efficient image handling
9. ✅ Type-safe implementations
10. ✅ Documentation for all public APIs

**Next Step:** After completion, proceed to image editor data layer implementation (08-image-editor-data.prompt.md)

**Quality Gate:** All tests pass, 100% coverage, zero analysis issues

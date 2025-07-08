import 'dart:typed_data';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/core/utils/result.dart';
import 'package:revision/features/image_selection/domain/entities/image_source.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';
import 'package:revision/features/image_selection/domain/exceptions/image_selection_exception.dart';
import 'package:revision/features/image_selection/domain/usecases/select_image_use_case.dart';
import 'package:revision/features/image_selection/presentation/cubit/image_selection_cubit.dart';
import 'package:revision/features/image_selection/presentation/cubit/image_selection_state.dart';

class MockSelectImageUseCase extends Mock implements SelectImageUseCase {}

void main() {
  group('ImageSelectionCubit', () {
    late ImageSelectionCubit cubit;
    late MockSelectImageUseCase mockSelectImageUseCase;

    setUp(() {
      mockSelectImageUseCase = MockSelectImageUseCase();
      cubit = ImageSelectionCubit(mockSelectImageUseCase);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is ImageSelectionInitial', () {
      expect(cubit.state, equals(const ImageSelectionInitial()));
    });

    group('selectImage', () {
      blocTest<ImageSelectionCubit, ImageSelectionState>(
        'emits [loading, success] when image selection and processing succeed',
        build: () {
          // Create a valid JPEG image data
          final validImageData = Uint8List.fromList([
            0xFF, 0xD8, 0xFF, 0xE0, // JPEG signature
            0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01, // JFIF header
            ...List.generate(1000, (i) => 0x00), // Padding
          ]);

          final selectedImage = SelectedImage(
            bytes: validImageData,
            name: 'test.jpg',
            sizeInBytes: validImageData.length,
            source: ImageSource.gallery,
          );

          when(() => mockSelectImageUseCase(ImageSource.gallery))
              .thenAnswer((_) async => Success(selectedImage));

          return cubit;
        },
        act: (cubit) => cubit.selectImage(ImageSource.gallery),
        expect: () => [
          const ImageSelectionLoading(),
          isA<ImageSelectionSuccess>(),
        ],
      );

      blocTest<ImageSelectionCubit, ImageSelectionState>(
        'emits [loading, error] when image selection fails',
        build: () {
          when(() => mockSelectImageUseCase(ImageSource.gallery))
              .thenAnswer((_) async => const Failure(
                    ImageSelectionException.permissionDenied(
                      'Permission denied',
                    ),
                  ));

          return cubit;
        },
        act: (cubit) => cubit.selectImage(ImageSource.gallery),
        expect: () => [
          const ImageSelectionLoading(),
          isA<ImageSelectionError>(),
        ],
      );

      blocTest<ImageSelectionCubit, ImageSelectionState>(
        'emits [loading, error] when security processing fails',
        build: () {
          // Create invalid image data that will fail security processing
          final invalidImageData = Uint8List.fromList([
            0x00, 0x00, 0x00, 0x00, // Invalid signature
            ...List.generate(1000, (i) => 0x00),
          ]);

          final selectedImage = SelectedImage(
            bytes: invalidImageData,
            name: 'test.jpg',
            sizeInBytes: invalidImageData.length,
            source: ImageSource.gallery,
          );

          when(() => mockSelectImageUseCase(ImageSource.gallery))
              .thenAnswer((_) async => Success(selectedImage));

          return cubit;
        },
        act: (cubit) => cubit.selectImage(ImageSource.gallery),
        expect: () => [
          const ImageSelectionLoading(),
          isA<ImageSelectionError>(),
        ],
      );

      blocTest<ImageSelectionCubit, ImageSelectionState>(
        'emits [loading, error] when selected image has no bytes',
        build: () {
          final selectedImage = SelectedImage(
            bytes: null,
            path: '/path/to/image.jpg',
            name: 'test.jpg',
            sizeInBytes: 1000,
            source: ImageSource.gallery,
          );

          when(() => mockSelectImageUseCase(ImageSource.gallery))
              .thenAnswer((_) async => Success(selectedImage));

          return cubit;
        },
        act: (cubit) => cubit.selectImage(ImageSource.gallery),
        expect: () => [
          const ImageSelectionLoading(),
          isA<ImageSelectionError>(),
        ],
      );

      blocTest<ImageSelectionCubit, ImageSelectionState>(
        'formats permission denied error appropriately',
        build: () {
          when(() => mockSelectImageUseCase(ImageSource.gallery))
              .thenAnswer((_) async => const Failure(
                    ImageSelectionException.permissionDenied(
                      'Permission denied',
                    ),
                  ));

          return cubit;
        },
        act: (cubit) => cubit.selectImage(ImageSource.gallery),
        expect: () => [
          const ImageSelectionLoading(),
          predicate<ImageSelectionError>((state) =>
              state.message.contains('Permission denied') &&
              state.message.contains('settings')),
        ],
      );

      blocTest<ImageSelectionCubit, ImageSelectionState>(
        'formats file too large error appropriately',
        build: () {
          when(() => mockSelectImageUseCase(ImageSource.gallery))
              .thenAnswer((_) async => const Failure(
                    ImageSelectionException.fileTooLarge(
                      'File is too large: 5.0MB',
                    ),
                  ));

          return cubit;
        },
        act: (cubit) => cubit.selectImage(ImageSource.gallery),
        expect: () => [
          const ImageSelectionLoading(),
          predicate<ImageSelectionError>((state) =>
              state.message.contains('5.0MB')),
        ],
      );

      blocTest<ImageSelectionCubit, ImageSelectionState>(
        'formats invalid format error appropriately',
        build: () {
          when(() => mockSelectImageUseCase(ImageSource.gallery))
              .thenAnswer((_) async => const Failure(
                    ImageSelectionException.invalidFormat(
                      'Invalid format',
                    ),
                  ));

          return cubit;
        },
        act: (cubit) => cubit.selectImage(ImageSource.gallery),
        expect: () => [
          const ImageSelectionLoading(),
          predicate<ImageSelectionError>((state) =>
              state.message.contains('Unsupported image format') &&
              state.message.contains('JPEG, PNG, or WebP')),
        ],
      );

      blocTest<ImageSelectionCubit, ImageSelectionState>(
        'formats camera unavailable error appropriately',
        build: () {
          when(() => mockSelectImageUseCase(ImageSource.camera))
              .thenAnswer((_) async => const Failure(
                    ImageSelectionException.cameraUnavailable(
                      'Camera unavailable',
                    ),
                  ));

          return cubit;
        },
        act: (cubit) => cubit.selectImage(ImageSource.camera),
        expect: () => [
          const ImageSelectionLoading(),
          predicate<ImageSelectionError>((state) =>
              state.message.contains('Camera is not available')),
        ],
      );

      blocTest<ImageSelectionCubit, ImageSelectionState>(
        'formats cancelled error appropriately',
        build: () {
          when(() => mockSelectImageUseCase(ImageSource.gallery))
              .thenAnswer((_) async => const Failure(
                    ImageSelectionException.cancelled(
                      'Selection cancelled',
                    ),
                  ));

          return cubit;
        },
        act: (cubit) => cubit.selectImage(ImageSource.gallery),
        expect: () => [
          const ImageSelectionLoading(),
          predicate<ImageSelectionError>((state) =>
              state.message.contains('Image selection was cancelled')),
        ],
      );

      blocTest<ImageSelectionCubit, ImageSelectionState>(
        'handles unexpected exceptions gracefully',
        build: () {
          when(() => mockSelectImageUseCase(ImageSource.gallery))
              .thenThrow(Exception('Unexpected error'));

          return cubit;
        },
        act: (cubit) => cubit.selectImage(ImageSource.gallery),
        expect: () => [
          const ImageSelectionLoading(),
          predicate<ImageSelectionError>((state) =>
              state.message.contains('Unexpected error')),
        ],
      );
    });

    group('clearSelection', () {
      blocTest<ImageSelectionCubit, ImageSelectionState>(
        'emits ImageSelectionInitial when clearSelection is called',
        build: () => cubit,
        seed: () => const ImageSelectionError('Some error'),
        act: (cubit) => cubit.clearSelection(),
        expect: () => [const ImageSelectionInitial()],
      );
    });

    group('image processing', () {
      blocTest<ImageSelectionCubit, ImageSelectionState>(
        'processes image with compression and EXIF stripping',
        build: () {
          // Create a valid JPEG image data
          final validImageData = Uint8List.fromList([
            0xFF, 0xD8, 0xFF, 0xE0, // JPEG signature
            0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01, // JFIF header
            ...List.generate(2000, (i) => 0x00), // Padding
          ]);

          final selectedImage = SelectedImage(
            bytes: validImageData,
            name: 'test.jpg',
            sizeInBytes: validImageData.length,
            source: ImageSource.gallery,
          );

          when(() => mockSelectImageUseCase(ImageSource.gallery))
              .thenAnswer((_) async => Success(selectedImage));

          return cubit;
        },
        act: (cubit) => cubit.selectImage(ImageSource.gallery),
        expect: () => [
          const ImageSelectionLoading(),
          isA<ImageSelectionSuccess>(),
        ],
        verify: (cubit) {
          // Verify that the final state contains processed image
          final state = cubit.state as ImageSelectionSuccess;
          expect(state.selectedImage.bytes, isNotNull);
          expect(state.selectedImage.name, equals('test.jpg'));
        },
      );

      blocTest<ImageSelectionCubit, ImageSelectionState>(
        'handles malicious image data appropriately',
        build: () {
          // Create image data with suspicious patterns (MZ header)
          final maliciousImageData = Uint8List.fromList([
            0x4D, 0x5A, // MZ signature (Windows executable)
            ...List.generate(1000, (i) => 0x00),
          ]);

          final selectedImage = SelectedImage(
            bytes: maliciousImageData,
            name: 'test.jpg',
            sizeInBytes: maliciousImageData.length,
            source: ImageSource.gallery,
          );

          when(() => mockSelectImageUseCase(ImageSource.gallery))
              .thenAnswer((_) async => Success(selectedImage));

          return cubit;
        },
        act: (cubit) => cubit.selectImage(ImageSource.gallery),
        expect: () => [
          const ImageSelectionLoading(),
          predicate<ImageSelectionError>((state) =>
              state.message.contains('Security validation failed') ||
              state.message.contains('suspicious patterns')),
        ],
      );
    });
  });
}
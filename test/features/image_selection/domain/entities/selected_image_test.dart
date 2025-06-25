import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:revision/features/image_selection/domain/entities/image_source.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';

void main() {
  group('SelectedImage', () {
    const testPath = '/test/path/image.jpg';
    const testName = 'image.jpg';
    const testSize = 1024;
    const testSource = ImageSource.gallery;

    test('creates instance with all properties', () {
      const selectedImage = SelectedImage(
        path: testPath,
        name: testName,
        sizeInBytes: testSize,
        source: testSource,
      );

      expect(selectedImage.path, testPath);
      expect(selectedImage.name, testName);
      expect(selectedImage.sizeInBytes, testSize);
      expect(selectedImage.source, testSource);
    });

    test('supports value equality', () {
      const image1 = SelectedImage(
        path: testPath,
        name: testName,
        sizeInBytes: testSize,
        source: testSource,
      );

      const image2 = SelectedImage(
        path: testPath,
        name: testName,
        sizeInBytes: testSize,
        source: testSource,
      );

      expect(image1, equals(image2));
    });

    group('computed properties', () {
      test('file returns File object', () {
        const selectedImage = SelectedImage(
          path: testPath,
          name: testName,
          sizeInBytes: testSize,
          source: testSource,
        );
        expect(selectedImage.file, isA<File?>());
        expect(selectedImage.file?.path, testPath);
      });

      test('sizeInMB returns correct megabyte size', () {
        const sizeInBytes = 2 * 1024 * 1024; // 2MB
        const selectedImage = SelectedImage(
          path: testPath,
          name: testName,
          sizeInBytes: sizeInBytes,
          source: testSource,
        );

        expect(selectedImage.sizeInMB, equals(2.0));
      });

      test('isLargeFile returns true for files over 10MB', () {
        const largeSize = 15 * 1024 * 1024; // 15MB
        const largeImage = SelectedImage(
          path: testPath,
          name: testName,
          sizeInBytes: largeSize,
          source: testSource,
        );

        expect(largeImage.isLargeFile, isTrue);
      });

      test('isLargeFile returns false for files under 10MB', () {
        const smallSize = 5 * 1024 * 1024; // 5MB
        const smallImage = SelectedImage(
          path: testPath,
          name: testName,
          sizeInBytes: smallSize,
          source: testSource,
        );

        expect(smallImage.isLargeFile, isFalse);
      });

      test('isValidFormat returns true for supported formats', () {
        const supportedFormats = [
          'image.jpg',
          'image.jpeg',
          'image.png',
          'image.heic',
          'image.webp'
        ];

        for (final filename in supportedFormats) {
          final image = SelectedImage(
            path: '/test/$filename',
            name: filename,
            sizeInBytes: testSize,
            source: testSource,
          );

          expect(image.isValidFormat, isTrue, reason: 'Failed for $filename');
        }
      });

      test('isValidFormat returns false for unsupported formats', () {
        const unsupportedFormats = ['image.bmp', 'image.gif', 'image.tiff'];

        for (final filename in unsupportedFormats) {
          final image = SelectedImage(
            path: '/test/$filename',
            name: filename,
            sizeInBytes: testSize,
            source: testSource,
          );

          expect(image.isValidFormat, isFalse, reason: 'Failed for $filename');
        }
      });

      test('isValid returns true for valid size and format', () {
        const validImage = SelectedImage(
          path: testPath,
          name: 'image.jpg',
          sizeInBytes: 5 * 1024 * 1024, // 5MB
          source: testSource,
        );

        expect(validImage.isValid, isTrue);
      });

      test('isValid returns false for oversized files', () {
        const oversizedImage = SelectedImage(
          path: testPath,
          name: 'image.jpg',
          sizeInBytes: 60 * 1024 * 1024, // 60MB (over 50MB limit)
          source: testSource,
        );

        expect(oversizedImage.isValid, isFalse);
      });

      test('isValid returns false for invalid format', () {
        const invalidFormatImage = SelectedImage(
          path: testPath,
          name: 'image.bmp',
          sizeInBytes: 5 * 1024 * 1024, // 5MB
          source: testSource,
        );

        expect(invalidFormatImage.isValid, isFalse);
      });
    });

    test('copyWith creates new instance with updated values', () {
      const original = SelectedImage(
        path: testPath,
        name: testName,
        sizeInBytes: testSize,
        source: testSource,
      );

      final updated = original.copyWith(
        name: 'new_image.jpg',
        sizeInBytes: 2048,
      );

      expect(updated.path, testPath);
      expect(updated.name, 'new_image.jpg');
      expect(updated.sizeInBytes, 2048);
      expect(updated.source, testSource);
      expect(updated, isNot(original));
    });

    test('toString returns formatted string', () {
      const selectedImage = SelectedImage(
        path: testPath,
        name: testName,
        sizeInBytes: 2 * 1024 * 1024, // 2MB
        source: testSource,
      );

      final result = selectedImage.toString();

      expect(result, contains('SelectedImage('));
      expect(result, contains('path: $testPath'));
      expect(result, contains('name: $testName'));
      expect(result, contains('sizeInMB: 2.00'));
      expect(result, contains('source: $testSource'));
    });
  });
}

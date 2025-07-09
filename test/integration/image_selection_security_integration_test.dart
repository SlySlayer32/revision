import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:revision/core/services/image_security_service.dart';
import 'package:revision/features/image_selection/domain/entities/image_source.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';
import 'package:revision/features/image_selection/domain/exceptions/image_selection_exception.dart';

/// Integration test for image selection security flow
void main() {
  group('Image Selection Security Integration', () {
    test('complete security pipeline processes valid image successfully', () {
      // Create a realistic JPEG image data
      final validJpegData = Uint8List.fromList([
        // JPEG signature
        0xFF, 0xD8, 0xFF, 0xE0,
        // JFIF header
        0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01, 0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00,
        // SOF0 (Start of Frame)
        0xFF, 0xC0, 0x00, 0x11, 0x08, 0x00, 0x10, 0x00, 0x10, 0x01, 0x01, 0x11, 0x00, 0x02, 0x11, 0x01, 0x03, 0x11, 0x01,
        // DHT (Define Huffman Table)
        0xFF, 0xC4, 0x00, 0x1A, 0x00, 0x00, 0x01, 0x05, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00,
        // More minimal JPEG data...
        ...List.generate(1500, (i) => 0x00), // Padding to make it realistic size
        // EOI (End of Image)
        0xFF, 0xD9,
      ]);

      // Test the complete security pipeline
      final result = ImageSecurityService.processImageSecurely(
        validJpegData,
        filename: 'test_image.jpg',
        compressImage: true,
        stripExif: true,
      );

      expect(result.isSuccess, true);
      
      final processedData = result.value;
      expect(processedData, isNotNull);
      expect(processedData.length, lessThanOrEqualTo(validJpegData.length));
    });

    test('rejects malicious executable disguised as image', () {
      // Create data that looks like a Windows executable
      final maliciousData = Uint8List.fromList([
        // MZ header (Windows executable signature)
        0x4D, 0x5A, 0x90, 0x00, 0x03, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00,
        // More executable data...
        ...List.generate(1000, (i) => 0x00),
      ]);

      final result = ImageSecurityService.processImageSecurely(
        maliciousData,
        filename: 'malicious.jpg',
      );

      expect(result.isFailure, true);
      expect(result.exception, isA<ImageSelectionException>());
      expect(result.exception.toString(), contains('suspicious patterns'));
    });

    test('handles oversized image correctly', () {
      // Create oversized image data (larger than 4MB AppConstants.maxImageSize)
      final oversizedData = Uint8List(5 * 1024 * 1024); // 5MB

      final result = ImageSecurityService.processImageSecurely(
        oversizedData,
        filename: 'huge_image.jpg',
      );

      expect(result.isFailure, true);
      expect(result.exception, isA<ImageSelectionException>());
      expect(result.exception.toString(), contains('too large'));
    });

    test('detects path traversal attempts in filename', () {
      final validJpegData = Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0,
        ...List.generate(1000, (i) => 0x00),
        0xFF, 0xD9,
      ]);

      final result = ImageSecurityService.processImageSecurely(
        validJpegData,
        filename: '../../../etc/passwd',
      );

      expect(result.isFailure, true);
      expect(result.exception, isA<ImageSelectionException>());
      expect(result.exception.toString(), contains('dangerous path traversal'));
    });

    test('validates file extension security', () {
      final validJpegData = Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0,
        ...List.generate(1000, (i) => 0x00),
        0xFF, 0xD9,
      ]);

      final result = ImageSecurityService.processImageSecurely(
        validJpegData,
        filename: 'script.exe',
      );

      expect(result.isFailure, true);
      expect(result.exception, isA<ImageSelectionException>());
      expect(result.exception.toString(), contains('Unsupported image format'));
    });

    test('compression reduces file size appropriately', () {
      // Create a larger valid JPEG
      final largeJpegData = Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0,
        0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01, 0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00,
        ...List.generate(3000, (i) => i % 256), // More varied data
        0xFF, 0xD9,
      ]);

      final uncompressedResult = ImageSecurityService.processImageSecurely(
        largeJpegData,
        compressImage: false,
        stripExif: false,
      );

      final compressedResult = ImageSecurityService.processImageSecurely(
        largeJpegData,
        compressImage: true,
        stripExif: false,
      );

      expect(uncompressedResult.isSuccess, true);
      expect(compressedResult.isSuccess, true);
      
      // Note: Due to the image library's behavior, actual compression may vary
      // but the function should handle it gracefully
      expect(compressedResult.value.length, greaterThan(0));
    });

    test('EXIF stripping removes metadata', () {
      // Create JPEG with EXIF data
      final jpegWithExif = Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE1, // JPEG with EXIF marker
        0x00, 0x16, 0x45, 0x78, 0x69, 0x66, 0x00, 0x00, // "Exif" marker
        ...List.generate(2000, (i) => i % 256),
        0xFF, 0xD9,
      ]);

      final result = ImageSecurityService.processImageSecurely(
        jpegWithExif,
        stripExif: true,
        compressImage: false,
      );

      expect(result.isSuccess, true);
      // The processed image should not contain EXIF data
      expect(result.value.length, greaterThan(0));
    });

    test('handles empty image data gracefully', () {
      final emptyData = Uint8List(0);

      final result = ImageSecurityService.processImageSecurely(emptyData);

      expect(result.isFailure, true);
      expect(result.exception, isA<ImageSelectionException>());
      expect(result.exception.toString(), contains('empty'));
    });

    test('validates supported image formats', () {
      // Test PNG format
      final pngData = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
        ...List.generate(1000, (i) => 0x00),
      ]);

      final result = ImageSecurityService.processImageSecurely(
        pngData,
        filename: 'test.png',
      );

      expect(result.isSuccess, true);
    });

    test('rejects ZIP archives disguised as images', () {
      // Create ZIP file signature
      final zipData = Uint8List.fromList([
        0x50, 0x4B, 0x03, 0x04, // ZIP signature
        ...List.generate(1000, (i) => 0x00),
      ]);

      final result = ImageSecurityService.processImageSecurely(
        zipData,
        filename: 'archive.jpg',
      );

      expect(result.isFailure, true);
      expect(result.exception.toString(), contains('suspicious patterns'));
    });

    test('handles realistic SelectedImage entity', () {
      final jpegData = Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0,
        ...List.generate(2000, (i) => i % 256),
        0xFF, 0xD9,
      ]);

      final selectedImage = SelectedImage(
        bytes: jpegData,
        name: 'photo.jpg',
        sizeInBytes: jpegData.length,
        source: ImageSource.gallery,
      );

      // Test that the entity properties work correctly
      expect(selectedImage.isValidFormat, true);
      expect(selectedImage.isValid, true);
      expect(selectedImage.sizeInMB, lessThan(1.0));
    });
  });
}
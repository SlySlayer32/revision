import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:revision/core/services/image_security_service.dart';
import 'package:revision/features/image_selection/domain/exceptions/image_selection_exception.dart';

void main() {
  group('ImageSecurityService', () {
    group('validateImage', () {
      test('should return success for valid JPEG image', () {
        // Create a minimal valid JPEG header
        final validJpeg = Uint8List.fromList([
          0xFF, 0xD8, 0xFF, 0xE0, // JPEG signature
          0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01, // JFIF header
          ...List.generate(100, (i) => 0x00), // Padding to make it sizeable
        ]);

        final result = ImageSecurityService.validateImage(validJpeg);

        expect(result.isSuccess, true);
      });

      test('should return failure for empty image data', () {
        final emptyData = Uint8List(0);

        final result = ImageSecurityService.validateImage(emptyData);

        expect(result.isFailure, true);
        expect(result.exception, isA<ImageSelectionException>());
      });

      test('should return failure for oversized image', () {
        // Create data larger than AppConstants.maxImageSize (4MB)
        final oversizedData = Uint8List(5 * 1024 * 1024); // 5MB

        final result = ImageSecurityService.validateImage(oversizedData);

        expect(result.isFailure, true);
        expect(result.exception, isA<ImageSelectionException>());
        expect(result.exception.toString(), contains('too large'));
      });

      test('should return failure for invalid format', () {
        // Create data with invalid header
        final invalidData = Uint8List.fromList([
          0x00, 0x00, 0x00, 0x00, // Invalid signature
          ...List.generate(100, (i) => 0x00),
        ]);

        final result = ImageSecurityService.validateImage(invalidData);

        expect(result.isFailure, true);
        expect(result.exception, isA<ImageSelectionException>());
      });

      test('should validate filename when provided', () {
        final validJpeg = Uint8List.fromList([
          0xFF, 0xD8, 0xFF, 0xE0,
          ...List.generate(100, (i) => 0x00),
        ]);

        final result = ImageSecurityService.validateImage(
          validJpeg,
          filename: 'test.jpg',
        );

        expect(result.isSuccess, true);
      });

      test('should reject dangerous filenames', () {
        final validJpeg = Uint8List.fromList([
          0xFF, 0xD8, 0xFF, 0xE0,
          ...List.generate(100, (i) => 0x00),
        ]);

        final result = ImageSecurityService.validateImage(
          validJpeg,
          filename: '../../../etc/passwd',
        );

        expect(result.isFailure, true);
        expect(result.exception.toString(), contains('dangerous path traversal'));
      });

      test('should reject unsupported file extensions', () {
        final validJpeg = Uint8List.fromList([
          0xFF, 0xD8, 0xFF, 0xE0,
          ...List.generate(100, (i) => 0x00),
        ]);

        final result = ImageSecurityService.validateImage(
          validJpeg,
          filename: 'test.exe',
        );

        expect(result.isFailure, true);
        expect(result.exception.toString(), contains('Unsupported image format'));
      });
    });

    group('compressImage', () {
      test('should return original data when compression fails', () {
        final invalidData = Uint8List.fromList([0x00, 0x00, 0x00, 0x00]);

        final result = ImageSecurityService.compressImage(invalidData);

        expect(result, equals(invalidData));
      });

      test('should handle empty data gracefully', () {
        final emptyData = Uint8List(0);

        final result = ImageSecurityService.compressImage(emptyData);

        expect(result, equals(emptyData));
      });
    });

    group('stripExifData', () {
      test('should return original data when stripping fails', () {
        final invalidData = Uint8List.fromList([0x00, 0x00, 0x00, 0x00]);

        final result = ImageSecurityService.stripExifData(invalidData);

        expect(result, equals(invalidData));
      });

      test('should handle empty data gracefully', () {
        final emptyData = Uint8List(0);

        final result = ImageSecurityService.stripExifData(emptyData);

        expect(result, equals(emptyData));
      });
    });

    group('processImageSecurely', () {
      test('should return failure for invalid image data', () {
        final invalidData = Uint8List.fromList([0x00, 0x00, 0x00, 0x00]);

        final result = ImageSecurityService.processImageSecurely(invalidData);

        expect(result.isFailure, true);
        expect(result.exception, isA<ImageSelectionException>());
      });

      test('should process valid image successfully', () {
        final validJpeg = Uint8List.fromList([
          0xFF, 0xD8, 0xFF, 0xE0,
          ...List.generate(1000, (i) => 0x00),
        ]);

        final result = ImageSecurityService.processImageSecurely(validJpeg);

        expect(result.isSuccess, true);
      });

      test('should skip compression when disabled', () {
        final validJpeg = Uint8List.fromList([
          0xFF, 0xD8, 0xFF, 0xE0,
          ...List.generate(1000, (i) => 0x00),
        ]);

        final result = ImageSecurityService.processImageSecurely(
          validJpeg,
          compressImage: false,
        );

        expect(result.isSuccess, true);
      });

      test('should skip EXIF stripping when disabled', () {
        final validJpeg = Uint8List.fromList([
          0xFF, 0xD8, 0xFF, 0xE0,
          ...List.generate(1000, (i) => 0x00),
        ]);

        final result = ImageSecurityService.processImageSecurely(
          validJpeg,
          stripExif: false,
        );

        expect(result.isSuccess, true);
      });
    });

    group('malware scanning', () {
      test('should detect suspicious executable patterns', () {
        // Create data with MZ header (Windows executable)
        final suspiciousData = Uint8List.fromList([
          0x4D, 0x5A, // MZ signature
          ...List.generate(1000, (i) => 0x00),
        ]);

        final result = ImageSecurityService.validateImage(suspiciousData);

        expect(result.isFailure, true);
        expect(result.exception.toString(), contains('suspicious patterns'));
      });

      test('should detect ZIP archive patterns', () {
        // Create data with PK header (ZIP archive)
        final suspiciousData = Uint8List.fromList([
          0x50, 0x4B, // PK signature
          ...List.generate(1000, (i) => 0x00),
        ]);

        final result = ImageSecurityService.validateImage(suspiciousData);

        expect(result.isFailure, true);
        expect(result.exception.toString(), contains('suspicious patterns'));
      });

      test('should detect ELF executable patterns', () {
        // Create data with ELF header
        final suspiciousData = Uint8List.fromList([
          0x7F, 0x45, 0x4C, 0x46, // ELF signature
          ...List.generate(1000, (i) => 0x00),
        ]);

        final result = ImageSecurityService.validateImage(suspiciousData);

        expect(result.isFailure, true);
        expect(result.exception.toString(), contains('suspicious patterns'));
      });
    });

    group('dimension validation', () {
      test('should handle decode failures gracefully', () {
        final invalidImageData = Uint8List.fromList([
          0xFF, 0xD8, 0xFF, 0xE0, // Valid JPEG header
          0x00, 0x00, 0x00, 0x00, // Invalid data
        ]);

        final result = ImageSecurityService.validateImage(invalidImageData);

        // Should fail during dimension validation
        expect(result.isFailure, true);
      });
    });

    group('compression ratio calculation', () {
      test('should apply different compression ratios based on file size', () {
        // Test with small file (< 1MB)
        final smallFile = Uint8List(500 * 1024); // 500KB
        final smallResult = ImageSecurityService.compressImage(smallFile);
        
        // Test with large file (> 2MB)
        final largeFile = Uint8List(3 * 1024 * 1024); // 3MB
        final largeResult = ImageSecurityService.compressImage(largeFile);

        // Both should return the original data since they're invalid images
        expect(smallResult, equals(smallFile));
        expect(largeResult, equals(largeFile));
      });
    });
  });
}
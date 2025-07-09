import 'package:flutter_test/flutter_test.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_configuration.dart';

void main() {
  group('ProcessingConfiguration', () {
    test('should create default configuration', () {
      const config = ProcessingConfiguration();
      
      expect(config.maxImageSizeBytes, equals(15 * 1024 * 1024));
      expect(config.maxProcessingTimeSeconds, equals(300));
      expect(config.enableProgressTracking, isTrue);
      expect(config.enableCancellation, isTrue);
      expect(config.enableImagePreprocessing, isTrue);
      expect(config.enableImageEncryption, isFalse);
      expect(config.enableRequestSigning, isTrue);
      expect(config.rateLimitMaxRequests, equals(10));
      expect(config.rateLimitWindowMinutes, equals(1));
      expect(config.supportedImageFormats, contains('jpg'));
      expect(config.supportedImageFormats, contains('png'));
      expect(config.preprocessingQuality, equals(0.8));
      expect(config.maxImageDimension, equals(2048));
      expect(config.enableMemoryOptimization, isTrue);
    });

    test('should validate supported image formats', () {
      const config = ProcessingConfiguration();
      
      expect(config.isImageFormatSupported('jpg'), isTrue);
      expect(config.isImageFormatSupported('JPG'), isTrue);
      expect(config.isImageFormatSupported('png'), isTrue);
      expect(config.isImageFormatSupported('webp'), isTrue);
      expect(config.isImageFormatSupported('gif'), isFalse);
      expect(config.isImageFormatSupported('bmp'), isFalse);
    });

    test('should validate image size limits', () {
      const config = ProcessingConfiguration();
      
      expect(config.isImageSizeValid(1024 * 1024), isTrue); // 1MB
      expect(config.isImageSizeValid(15 * 1024 * 1024), isTrue); // 15MB (at limit)
      expect(config.isImageSizeValid(16 * 1024 * 1024), isFalse); // 16MB (over limit)
    });

    test('should provide duration getters', () {
      const config = ProcessingConfiguration();
      
      expect(config.processingTimeout, equals(Duration(seconds: 300)));
      expect(config.rateLimitWindow, equals(Duration(minutes: 1)));
      expect(config.progressUpdateInterval, equals(Duration(milliseconds: 500)));
      expect(config.cancellationTimeout, equals(Duration(milliseconds: 5000)));
    });

    test('should create copy with modified values', () {
      const config = ProcessingConfiguration();
      
      final modified = config.copyWith(
        maxImageSizeBytes: 20 * 1024 * 1024,
        enableImageEncryption: true,
        rateLimitMaxRequests: 20,
      );
      
      expect(modified.maxImageSizeBytes, equals(20 * 1024 * 1024));
      expect(modified.enableImageEncryption, isTrue);
      expect(modified.rateLimitMaxRequests, equals(20));
      // Unchanged values should remain the same
      expect(modified.enableProgressTracking, isTrue);
      expect(modified.enableCancellation, isTrue);
    });

    test('should support custom configuration', () {
      const config = ProcessingConfiguration(
        maxImageSizeBytes: 50 * 1024 * 1024,
        maxProcessingTimeSeconds: 600,
        enableProgressTracking: false,
        enableCancellation: false,
        enableImagePreprocessing: false,
        enableImageEncryption: true,
        enableRequestSigning: false,
        rateLimitMaxRequests: 5,
        rateLimitWindowMinutes: 2,
        supportedImageFormats: ['jpg', 'png'],
        preprocessingQuality: 0.9,
        maxImageDimension: 4096,
        enableMemoryOptimization: false,
      );
      
      expect(config.maxImageSizeBytes, equals(50 * 1024 * 1024));
      expect(config.maxProcessingTimeSeconds, equals(600));
      expect(config.enableProgressTracking, isFalse);
      expect(config.enableCancellation, isFalse);
      expect(config.enableImagePreprocessing, isFalse);
      expect(config.enableImageEncryption, isTrue);
      expect(config.enableRequestSigning, isFalse);
      expect(config.rateLimitMaxRequests, equals(5));
      expect(config.rateLimitWindowMinutes, equals(2));
      expect(config.supportedImageFormats, equals(['jpg', 'png']));
      expect(config.preprocessingQuality, equals(0.9));
      expect(config.maxImageDimension, equals(4096));
      expect(config.enableMemoryOptimization, isFalse);
    });
  });
}
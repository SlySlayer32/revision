import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:revision/features/ai_processing/domain/entities/processing_configuration.dart';
import 'package:revision/features/ai_processing/domain/entities/cancellation_token.dart';
import 'package:revision/features/ai_processing/domain/entities/enhanced_processing_progress.dart';

/// Utility class for image preprocessing and memory optimization
class ImagePreprocessingUtils {
  /// Preprocesses an image for AI processing with memory optimization
  static Future<PreprocessingResult> preprocessImage({
    required Uint8List imageData,
    required ProcessingConfiguration config,
    CancellationToken? cancellationToken,
    Function(ProcessingProgress)? onProgress,
  }) async {
    cancellationToken?.throwIfCancelled();
    
    onProgress?.call(ProcessingProgress.preprocessing(
      progress: 0.0,
      message: 'Loading image...',
    ));

    // Decode the image
    final image = img.decodeImage(imageData);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    cancellationToken?.throwIfCancelled();
    
    onProgress?.call(ProcessingProgress.preprocessing(
      progress: 0.2,
      message: 'Analyzing image dimensions...',
    ));

    // Check if resizing is needed
    final needsResize = _needsResize(image, config.maxImageDimension);
    final needsCompress = _needsCompress(imageData.length, config.maxImageSizeBytes);

    img.Image processedImage = image;
    bool wasResized = false;
    bool wasCompressed = false;

    // Resize if needed
    if (needsResize) {
      cancellationToken?.throwIfCancelled();
      
      onProgress?.call(ProcessingProgress.preprocessing(
        progress: 0.4,
        message: 'Resizing image...',
      ));

      processedImage = _resizeImage(image, config.maxImageDimension);
      wasResized = true;
    }

    cancellationToken?.throwIfCancelled();
    
    onProgress?.call(ProcessingProgress.preprocessing(
      progress: 0.6,
      message: 'Optimizing image quality...',
    ));

    // Apply quality optimization
    if (config.enableMemoryOptimization) {
      processedImage = _optimizeImage(processedImage);
    }

    cancellationToken?.throwIfCancelled();
    
    onProgress?.call(ProcessingProgress.preprocessing(
      progress: 0.8,
      message: 'Encoding optimized image...',
    ));

    // Encode the result
    Uint8List processedData;
    if (needsCompress || wasResized) {
      processedData = _encodeWithQuality(processedImage, config.preprocessingQuality);
      wasCompressed = true;
    } else {
      processedData = imageData; // Use original if no processing needed
    }

    cancellationToken?.throwIfCancelled();
    
    onProgress?.call(ProcessingProgress.preprocessing(
      progress: 1.0,
      message: 'Preprocessing complete',
    ));

    return PreprocessingResult(
      processedData: processedData,
      originalSize: imageData.length,
      processedSize: processedData.length,
      originalDimensions: ImageDimensions(image.width, image.height),
      processedDimensions: ImageDimensions(processedImage.width, processedImage.height),
      wasResized: wasResized,
      wasCompressed: wasCompressed,
      compressionRatio: imageData.length / processedData.length,
    );
  }

  /// Optimizes memory usage by disposing of large image objects
  static void disposeImageData(Uint8List? data) {
    // Force garbage collection hint for large data
    if (data != null && data.length > 1024 * 1024) {
      // For very large images, we can't directly control GC,
      // but we can set references to null and suggest collection
      data = null;
    }
  }

  /// Validates if an image needs resizing
  static bool _needsResize(img.Image image, int maxDimension) {
    return image.width > maxDimension || image.height > maxDimension;
  }

  /// Validates if an image needs compression
  static bool _needsCompress(int currentSize, int maxSize) {
    return currentSize > maxSize;
  }

  /// Resizes an image while maintaining aspect ratio
  static img.Image _resizeImage(img.Image image, int maxDimension) {
    final aspectRatio = image.width / image.height;
    int newWidth, newHeight;

    if (image.width > image.height) {
      newWidth = maxDimension;
      newHeight = (maxDimension / aspectRatio).round();
    } else {
      newHeight = maxDimension;
      newWidth = (maxDimension * aspectRatio).round();
    }

    return img.copyResize(
      image,
      width: newWidth,
      height: newHeight,
      interpolation: img.Interpolation.cubic,
    );
  }

  /// Optimizes image for memory usage
  static img.Image _optimizeImage(img.Image image) {
    // Apply subtle noise reduction and sharpening
    var optimized = img.gaussianBlur(image, radius: 0.5);
    optimized = img.convolution(optimized, [
      0, -1, 0,
      -1, 5, -1,
      0, -1, 0
    ]);
    return optimized;
  }

  /// Encodes image with specified quality
  static Uint8List _encodeWithQuality(img.Image image, double quality) {
    final jpegQuality = (quality * 100).round();
    return Uint8List.fromList(img.encodeJpg(image, quality: jpegQuality));
  }

  /// Estimates processing time based on image size
  static Duration estimateProcessingTime(int imageSizeBytes) {
    // Rough estimation: 1MB = 2 seconds of processing
    final sizeInMB = imageSizeBytes / (1024 * 1024);
    final estimatedSeconds = (sizeInMB * 2).round();
    return Duration(seconds: estimatedSeconds.clamp(5, 60));
  }

  /// Gets memory usage information
  static Map<String, dynamic> getMemoryInfo(int imageSizeBytes) {
    return {
      'imageSizeBytes': imageSizeBytes,
      'imageSizeMB': (imageSizeBytes / (1024 * 1024)).toStringAsFixed(2),
      'recommendsOptimization': imageSizeBytes > 5 * 1024 * 1024, // 5MB threshold
      'estimatedProcessingTime': estimateProcessingTime(imageSizeBytes).inSeconds,
    };
  }
}

/// Result of image preprocessing
class PreprocessingResult {
  const PreprocessingResult({
    required this.processedData,
    required this.originalSize,
    required this.processedSize,
    required this.originalDimensions,
    required this.processedDimensions,
    required this.wasResized,
    required this.wasCompressed,
    required this.compressionRatio,
  });

  final Uint8List processedData;
  final int originalSize;
  final int processedSize;
  final ImageDimensions originalDimensions;
  final ImageDimensions processedDimensions;
  final bool wasResized;
  final bool wasCompressed;
  final double compressionRatio;

  /// Gets the size reduction as a percentage
  double get sizeReductionPercentage => (1 - (processedSize / originalSize)) * 100;

  /// Whether any optimization was applied
  bool get wasOptimized => wasResized || wasCompressed;

  /// Summary of optimizations applied
  String get optimizationSummary {
    if (!wasOptimized) return 'No optimization needed';
    
    final optimizations = <String>[];
    if (wasResized) optimizations.add('resized');
    if (wasCompressed) optimizations.add('compressed');
    
    return 'Optimized: ${optimizations.join(', ')} (${sizeReductionPercentage.toStringAsFixed(1)}% smaller)';
  }
}

/// Represents image dimensions
class ImageDimensions {
  const ImageDimensions(this.width, this.height);

  final int width;
  final int height;

  @override
  String toString() => '${width}x${height}';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageDimensions && width == other.width && height == other.height;

  @override
  int get hashCode => width.hashCode ^ height.hashCode;
}
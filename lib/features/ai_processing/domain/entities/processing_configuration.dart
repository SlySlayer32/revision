import 'package:equatable/equatable.dart';

/// Flexible configuration for AI processing operations
/// Replaces hardcoded values with dynamic configuration
class ProcessingConfiguration extends Equatable {
  const ProcessingConfiguration({
    this.maxImageSizeBytes = 15 * 1024 * 1024, // 15MB default
    this.maxProcessingTimeSeconds = 300, // 5 minutes
    this.enableProgressTracking = true,
    this.enableCancellation = true,
    this.enableImagePreprocessing = true,
    this.enableImageEncryption = false,
    this.enableRequestSigning = true,
    this.rateLimitMaxRequests = 10,
    this.rateLimitWindowMinutes = 1,
    this.supportedImageFormats = const ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'],
    this.preprocessingQuality = 0.8,
    this.maxImageDimension = 2048,
    this.enableMemoryOptimization = true,
    this.progressUpdateIntervalMs = 500,
    this.cancellationTimeoutMs = 5000,
  });

  /// Maximum allowed image size in bytes
  final int maxImageSizeBytes;
  
  /// Maximum processing time in seconds before timeout
  final int maxProcessingTimeSeconds;
  
  /// Whether to enable detailed progress tracking
  final bool enableProgressTracking;
  
  /// Whether to enable operation cancellation
  final bool enableCancellation;
  
  /// Whether to enable image preprocessing optimization
  final bool enableImagePreprocessing;
  
  /// Whether to enable image encryption during processing
  final bool enableImageEncryption;
  
  /// Whether to enable request signing for API security
  final bool enableRequestSigning;
  
  /// Maximum requests per rate limit window
  final int rateLimitMaxRequests;
  
  /// Rate limit window in minutes
  final int rateLimitWindowMinutes;
  
  /// Supported image formats for processing
  final List<String> supportedImageFormats;
  
  /// Quality level for preprocessing (0.0 to 1.0)
  final double preprocessingQuality;
  
  /// Maximum dimension for images (width/height)
  final int maxImageDimension;
  
  /// Whether to enable memory optimization
  final bool enableMemoryOptimization;
  
  /// Progress update interval in milliseconds
  final int progressUpdateIntervalMs;
  
  /// Cancellation timeout in milliseconds
  final int cancellationTimeoutMs;

  /// Gets the rate limit window as Duration
  Duration get rateLimitWindow => Duration(minutes: rateLimitWindowMinutes);
  
  /// Gets the processing timeout as Duration
  Duration get processingTimeout => Duration(seconds: maxProcessingTimeSeconds);
  
  /// Gets the progress update interval as Duration
  Duration get progressUpdateInterval => Duration(milliseconds: progressUpdateIntervalMs);
  
  /// Gets the cancellation timeout as Duration
  Duration get cancellationTimeout => Duration(milliseconds: cancellationTimeoutMs);

  /// Validates if an image format is supported
  bool isImageFormatSupported(String format) {
    return supportedImageFormats.contains(format.toLowerCase());
  }

  /// Validates if an image size is within limits
  bool isImageSizeValid(int sizeInBytes) {
    return sizeInBytes <= maxImageSizeBytes;
  }

  /// Creates a copy with updated values
  ProcessingConfiguration copyWith({
    int? maxImageSizeBytes,
    int? maxProcessingTimeSeconds,
    bool? enableProgressTracking,
    bool? enableCancellation,
    bool? enableImagePreprocessing,
    bool? enableImageEncryption,
    bool? enableRequestSigning,
    int? rateLimitMaxRequests,
    int? rateLimitWindowMinutes,
    List<String>? supportedImageFormats,
    double? preprocessingQuality,
    int? maxImageDimension,
    bool? enableMemoryOptimization,
    int? progressUpdateIntervalMs,
    int? cancellationTimeoutMs,
  }) {
    return ProcessingConfiguration(
      maxImageSizeBytes: maxImageSizeBytes ?? this.maxImageSizeBytes,
      maxProcessingTimeSeconds: maxProcessingTimeSeconds ?? this.maxProcessingTimeSeconds,
      enableProgressTracking: enableProgressTracking ?? this.enableProgressTracking,
      enableCancellation: enableCancellation ?? this.enableCancellation,
      enableImagePreprocessing: enableImagePreprocessing ?? this.enableImagePreprocessing,
      enableImageEncryption: enableImageEncryption ?? this.enableImageEncryption,
      enableRequestSigning: enableRequestSigning ?? this.enableRequestSigning,
      rateLimitMaxRequests: rateLimitMaxRequests ?? this.rateLimitMaxRequests,
      rateLimitWindowMinutes: rateLimitWindowMinutes ?? this.rateLimitWindowMinutes,
      supportedImageFormats: supportedImageFormats ?? this.supportedImageFormats,
      preprocessingQuality: preprocessingQuality ?? this.preprocessingQuality,
      maxImageDimension: maxImageDimension ?? this.maxImageDimension,
      enableMemoryOptimization: enableMemoryOptimization ?? this.enableMemoryOptimization,
      progressUpdateIntervalMs: progressUpdateIntervalMs ?? this.progressUpdateIntervalMs,
      cancellationTimeoutMs: cancellationTimeoutMs ?? this.cancellationTimeoutMs,
    );
  }

  @override
  List<Object?> get props => [
    maxImageSizeBytes,
    maxProcessingTimeSeconds,
    enableProgressTracking,
    enableCancellation,
    enableImagePreprocessing,
    enableImageEncryption,
    enableRequestSigning,
    rateLimitMaxRequests,
    rateLimitWindowMinutes,
    supportedImageFormats,
    preprocessingQuality,
    maxImageDimension,
    enableMemoryOptimization,
    progressUpdateIntervalMs,
    cancellationTimeoutMs,
  ];
}
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_context.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_result.dart' hide ProcessingProgress;
import 'package:revision/features/ai_processing/domain/entities/enhanced_processing_progress.dart';
import 'package:revision/features/ai_processing/domain/entities/cancellation_token.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_configuration.dart';
import 'package:revision/features/ai_processing/domain/utils/image_preprocessing_utils.dart';
import 'package:revision/features/ai_processing/domain/services/request_signing_service.dart';
import 'package:revision/features/ai_processing/domain/usecases/process_image_with_gemini_usecase.dart';
import 'package:revision/features/ai_processing/presentation/cubit/gemini_pipeline_state.dart';
import 'package:revision/features/image_editing/domain/entities/annotated_image.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';
import 'package:revision/core/utils/security_utils.dart';

/// Cubit for managing Gemini AI Pipeline state and operations
///
/// Enhanced with:
/// - Detailed progress tracking
/// - Cancellation support
/// - Image preprocessing
/// - Request signing
/// - Memory optimization
class GeminiPipelineCubit extends Cubit<GeminiPipelineState> {
  GeminiPipelineCubit(
    this._processImageWithGeminiUseCase, {
    ProcessingConfiguration? configuration,
  }) : super(const GeminiPipelineState()) {
    _configuration = configuration ?? const ProcessingConfiguration();
    _cancellationSource = CancellationTokenSource();
  }

  final ProcessImageWithGeminiUseCase _processImageWithGeminiUseCase;
  late ProcessingConfiguration _configuration;
  late CancellationTokenSource _cancellationSource;
  Timer? _progressTimer;

  /// Current processing configuration
  ProcessingConfiguration get configuration => _configuration;

  /// Updates the processing configuration
  void updateConfiguration(ProcessingConfiguration newConfiguration) {
    _configuration = newConfiguration;
  }

  /// Process an image through the complete Gemini AI Pipeline
  Future<void> startImageProcessing({
    required SelectedImage selectedImage,
    required String prompt,
    required ProcessingContext processingContext,
    AnnotatedImage? annotatedImage,
  }) async {
    // Cancel any existing processing
    if (state.isProcessing) {
      cancelProcessing('Starting new processing');
    }

    // Create new cancellation token
    _cancellationSource.reset();
    final requestId = RequestSigningService.generateRequestId();
    final startTime = DateTime.now();

    try {
      // Validate inputs
      if (selectedImage.bytes == null) {
        emit(state.copyWith(
          status: GeminiPipelineStatus.error,
          errorMessage: 'Selected image data is missing.',
        ));
        return;
      }

      // Check rate limiting
      if (SecurityUtils.isRateLimited(
        'ai_processing',
        maxRequests: _configuration.rateLimitMaxRequests,
        window: _configuration.rateLimitWindow,
      )) {
        emit(state.copyWith(
          status: GeminiPipelineStatus.error,
          errorMessage: 'Rate limit exceeded. Please try again later.',
        ));
        return;
      }

      // Start processing
      emit(state.copyWith(
        status: GeminiPipelineStatus.processing,
        detailedProgress: ProcessingProgress.initializing(
          message: 'Starting AI processing...',
        ),
        cancellationToken: _cancellationSource.token,
        requestId: requestId,
        startTime: startTime,
        canCancel: true,
      ));

      // Start progress tracking
      _startProgressTracking();

      await _executeProcessingPipeline(
        selectedImage: selectedImage,
        prompt: prompt,
        processingContext: processingContext,
        annotatedImage: annotatedImage,
      );

    } catch (e) {
      await _handleProcessingError(e);
    }
  }

  /// Cancels the current processing operation
  void cancelProcessing([String? reason]) {
    if (!state.isProcessing) return;

    _cancellationSource.cancel(reason ?? 'Processing cancelled by user');
    _stopProgressTracking();

    emit(state.copyWith(
      status: GeminiPipelineStatus.cancelled,
      detailedProgress: ProcessingProgress.cancelled(
        message: _cancellationSource.token.reason,
      ),
      endTime: DateTime.now(),
      canCancel: false,
    ));
  }

  /// Clear the current pipeline state
  void clearPipeline() {
    _cancellationSource.cancel('Pipeline cleared');
    _stopProgressTracking();
    emit(const GeminiPipelineState());
  }

  /// Executes the complete processing pipeline
  Future<void> _executeProcessingPipeline({
    required SelectedImage selectedImage,
    required String prompt,
    required ProcessingContext processingContext,
    AnnotatedImage? annotatedImage,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Step 1: Validation
      _cancellationSource.token.throwIfCancelled();
      await _updateProgress(ProcessingProgress.validating(
        message: 'Validating image and configuration...',
      ));

      // Step 2: Image preprocessing
      _cancellationSource.token.throwIfCancelled();
      PreprocessingResult? preprocessingResult;
      
      if (_configuration.enableImagePreprocessing) {
        preprocessingResult = await _preprocessImage(selectedImage.bytes!);
      }

      // Step 3: AI processing
      _cancellationSource.token.throwIfCancelled();
      await _updateProgress(ProcessingProgress.analyzing(
        progress: 0.0,
        message: 'Analyzing image with Gemini...',
      ));

      final imageData = preprocessingResult?.processedData ?? selectedImage.bytes!;
      final result = await _processImageWithGeminiUseCase(
        imageData,
        imageName: selectedImage.name,
        markedAreas: processingContext.markers.map((m) => m.toAIMap()).toList(),
      );

      _cancellationSource.token.throwIfCancelled();

      result.fold(
        success: (pipelineResult) => _handleProcessingSuccess(pipelineResult, prompt, stopwatch),
        failure: (exception) => _handleProcessingFailure(exception),
      );

    } on OperationCancelledException {
      // Cancellation is handled in cancelProcessing method
      return;
    } catch (e) {
      await _handleProcessingError(e);
    } finally {
      _stopProgressTracking();
      // Clean up memory
      if (selectedImage.bytes != null) {
        ImagePreprocessingUtils.disposeImageData(selectedImage.bytes!);
      }
    }
  }

  /// Preprocesses the image for optimization
  Future<PreprocessingResult> _preprocessImage(Uint8List imageData) async {
    return await ImagePreprocessingUtils.preprocessImage(
      imageData: imageData,
      config: _configuration,
      cancellationToken: _cancellationSource.token,
      onProgress: (progress) {
        if (!isClosed) {
          emit(state.copyWith(detailedProgress: progress));
        }
      },
    );
  }

  /// Handles successful processing
  void _handleProcessingSuccess(
    dynamic pipelineResult,
    String prompt,
    Stopwatch stopwatch,
  ) {
    final processingResult = ProcessingResult(
      processedImageData: pipelineResult.generatedImage,
      originalPrompt: prompt,
      enhancedPrompt: pipelineResult.analysisPrompt,
      processingTime: stopwatch.elapsed,
    );

    emit(state.copyWith(
      status: GeminiPipelineStatus.success,
      processingResult: processingResult,
      detailedProgress: ProcessingProgress.completed(
        message: 'Processing completed successfully!',
      ),
      endTime: DateTime.now(),
      canCancel: false,
    ));
  }

  /// Handles processing failure
  void _handleProcessingFailure(dynamic exception) {
    String errorMessage = exception.toString();

    if (errorMessage.contains('400') ||
        errorMessage.toLowerCase().contains('not initiated')) {
      errorMessage = '''
Firebase AI (Gemini) Setup Required:

1. Enable Gemini AI in Firebase Console.
2. Verify API key configuration.
3. Ensure Firebase AI Logic is properly initialized.

Original error: ${exception.toString()}''';
    }

    emit(state.copyWith(
      status: GeminiPipelineStatus.error,
      errorMessage: SecurityUtils.maskSensitiveData(errorMessage),
      detailedProgress: ProcessingProgress.error(
        message: 'Processing failed',
      ),
      endTime: DateTime.now(),
      canCancel: false,
    ));
  }

  /// Handles processing errors
  Future<void> _handleProcessingError(dynamic error) async {
    final maskedError = SecurityUtils.maskSensitiveData(error.toString());
    
    emit(state.copyWith(
      status: GeminiPipelineStatus.error,
      errorMessage: maskedError,
      detailedProgress: ProcessingProgress.error(
        message: 'Unexpected error occurred',
      ),
      endTime: DateTime.now(),
      canCancel: false,
    ));
  }

  /// Starts progress tracking timer
  void _startProgressTracking() {
    if (!_configuration.enableProgressTracking) return;

    _progressTimer = Timer.periodic(
      _configuration.progressUpdateInterval,
      (timer) {
        if (!state.isProcessing) {
          timer.cancel();
          return;
        }

        // Update estimated time remaining based on current progress
        final currentProgress = state.detailedProgress;
        if (currentProgress != null && currentProgress.progress > 0) {
          final elapsed = state.processingDuration ?? Duration.zero;
          final estimatedTotal = Duration(
            milliseconds: (elapsed.inMilliseconds / currentProgress.progress).round(),
          );
          final remaining = estimatedTotal - elapsed;

          if (remaining.inSeconds > 0) {
            emit(state.copyWith(
              detailedProgress: currentProgress.copyWith(
                estimatedTimeRemaining: remaining,
              ),
            ));
          }
        }
      },
    );
  }

  /// Stops progress tracking timer
  void _stopProgressTracking() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  /// Updates progress state
  Future<void> _updateProgress(ProcessingProgress progress) async {
    if (!isClosed) {
      emit(state.copyWith(detailedProgress: progress));
    }
    
    // Small delay to allow UI updates
    await Future.delayed(const Duration(milliseconds: 50));
  }

  @override
  Future<void> close() {
    _cancellationSource.cancel('Cubit closed');
    _stopProgressTracking();
    return super.close();
  }
}

}

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_context.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_result.dart';
import 'package:revision/features/ai_processing/domain/usecases/process_image_with_ai_usecase.dart';
import 'package:revision/features/ai_processing/presentation/cubit/ai_processing_state.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';

/// Cubit for managing AI processing state and operations.
///
/// This cubit handles the complete AI processing workflow including
/// progress tracking, cancellation, and result handling.
class AiProcessingCubit extends Cubit<AiProcessingState> {
  AiProcessingCubit(this._processImageWithAiUseCase)
      : super(const AiProcessingInitial());

  final ProcessImageWithAiUseCase _processImageWithAiUseCase;
  StreamSubscription<ProcessingProgress>? _progressSubscription;

  /// Process an image with AI using the provided prompt and context
  Future<void> processImage({
    required SelectedImage image,
    required String userPrompt,
    required ProcessingContext context,
  }) async {
    print(
        '🔄 AiProcessingCubit: Starting processImage with prompt: $userPrompt');
    print('🔄 AiProcessingCubit: Context markers: ${context.markers.length}');

    if (state is AiProcessingInProgress) {
      // Prevent multiple simultaneous processing
      print('⚠️ AiProcessingCubit: Already processing, ignoring request');
      return;
    }
    emit(
      const AiProcessingInProgress(
        progress: ProcessingProgress(
          stage: ProcessingStage.analyzing,
          progress: 0.1,
          message: 'Loading image data...',
        ),
      ),
    );
    try {
      // Get image data from the SelectedImage
      Uint8List imageData;
      if (image.bytes != null) {
        // Use bytes directly if available (most reliable)
        imageData = image.bytes!;
        print('✅ AiProcessingCubit: Using image bytes directly (${imageData.length} bytes)');
      } else if (image.path != null) {
        // Load from file path
        imageData = await _loadImageData(image.path!);
        print('✅ AiProcessingCubit: Loaded image from path (${imageData.length} bytes)');
      } else {
        throw Exception('Image has neither path nor bytes - cannot process');
      }

      // Validate image data
      if (imageData.isEmpty) {
        throw Exception('Image data is empty - cannot process');
      }

      print('✅ AiProcessingCubit: Image data validated, size: ${imageData.length} bytes');

      // Update progress
      emit(
        const AiProcessingInProgress(
          progress: ProcessingProgress(
            stage: ProcessingStage.promptEngineering,
            progress: 0.3,
            message: 'Preparing AI prompt...',
          ),
        ),
      );
      print('🔄 AiProcessingCubit: Calling processImageWithAiUseCase...');

      // Update progress before AI call
      emit(
        const AiProcessingInProgress(
          progress: ProcessingProgress(
            stage: ProcessingStage.aiProcessing,
            progress: 0.5,
            message: 'Processing with AI...',
          ),
        ),
      );

      final result = await _processImageWithAiUseCase(
        imageData: imageData,
        userPrompt: userPrompt,
        context: context,
      );
      result.fold(
        success: (processingResult) {
          print('✅ AiProcessingCubit: AI processing succeeded!');
          print('✅ Result job ID: ${processingResult.jobId}');
          print('✅ Processed image size: ${processingResult.processedImageData.length} bytes');
          print('✅ Original prompt: "${processingResult.originalPrompt}"');
          print('✅ Enhanced prompt: "${processingResult.enhancedPrompt}"');
          emit(
            AiProcessingSuccess(
              result: processingResult,
              originalImage: image,
            ),
          );
        },
        failure: (exception) {
          print('❌ AiProcessingCubit: AI processing failed: $exception');
          print('❌ Exception type: ${exception.runtimeType}');
          final errorMessage = exception.toString();
          print('❌ Error details: $errorMessage');
          emit(
            AiProcessingError(
              message: errorMessage,
              originalImage: image,
            ),
          );
        },
      );
    } catch (e, stackTrace) {
      print('❌ AiProcessingCubit: Unexpected error: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: $stackTrace');
      emit(
        AiProcessingError(
          message: 'Unexpected error during processing: $e',
          originalImage: image,
        ),
      );
    }
  }

  /// Cancel ongoing processing
  Future<void> cancelProcessing() async {
    if (state is AiProcessingInProgress) {
      await _progressSubscription?.cancel();
      _progressSubscription = null;

      emit(const AiProcessingCancelled());
    }
  }

  /// Reset to initial state
  void reset() {
    _progressSubscription?.cancel();
    _progressSubscription = null;
    emit(const AiProcessingInitial());
  }

  /// Load image data from file path or bytes
  Future<Uint8List> _loadImageData(String imagePath) async {
    try {
      print('🔄 AiProcessingCubit: Loading image from path: $imagePath');
      
      // Check if it's a file path or URL
      if (imagePath.startsWith('http')) {
        // For network images, we'd need to download
        // For MVP, throw an error for now
        throw Exception('Network images not supported in MVP');
      } else {
        // Load from file system
        final file = File(imagePath);
        print('🔄 AiProcessingCubit: Checking if file exists...');
        if (!await file.exists()) {
          throw Exception('Image file does not exist: $imagePath');
        }
        
        print('🔄 AiProcessingCubit: Reading file bytes...');
        final bytes = await file.readAsBytes();
        print('✅ AiProcessingCubit: Successfully loaded ${bytes.length} bytes from file');
        return bytes;
      }
    } catch (e, stackTrace) {
      print('❌ AiProcessingCubit: Error loading image from path: $e');
      print('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> close() {
    _progressSubscription?.cancel();
    return super.close();
  }
}

import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/core/utils/result.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_context.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_result.dart';
import 'package:revision/features/ai_processing/domain/usecases/process_image_with_ai_usecase.dart';
import 'package:revision/features/ai_processing/presentation/cubit/ai_processing_cubit.dart';
import 'package:revision/features/ai_processing/presentation/cubit/ai_processing_state.dart';
import 'package:revision/features/image_selection/domain/entities/image_source.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';

class MockProcessImageWithAiUseCase extends Mock
    implements ProcessImageWithAiUseCase {}

void main() {
  group('AiProcessingCubit', () {
    late AiProcessingCubit cubit;
    late MockProcessImageWithAiUseCase mockProcessImageWithAiUseCase;
    setUpAll(() {
      // Register fallback values for mocktail
      registerFallbackValue(Uint8List(0));
      registerFallbackValue(
        const ProcessingContext(
          processingType: ProcessingType.enhance,
          qualityLevel: QualityLevel.standard,
          performancePriority: PerformancePriority.balanced,
        ),
      );
      registerFallbackValue(
        const SelectedImage(
          path: '/test/path/image.jpg',
          name: 'test_image.jpg',
          sizeInBytes: 1024000,
          source: ImageSource.gallery,
        ),
      );
    });

    setUp(() {
      mockProcessImageWithAiUseCase = MockProcessImageWithAiUseCase();
      cubit = AiProcessingCubit(mockProcessImageWithAiUseCase);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is AiProcessingInitial', () {
      expect(cubit.state, const AiProcessingInitial());
    });

    group('processImage', () {
      const selectedImage = SelectedImage(
        path: '/path/to/image.jpg',
        name: 'image.jpg',
        sizeInBytes: 1024000,
        source: ImageSource.gallery,
      );

      const processingContext = ProcessingContext(
        processingType: ProcessingType.enhance,
        qualityLevel: QualityLevel.standard,
        performancePriority: PerformancePriority.balanced,
      );

      blocTest<AiProcessingCubit, AiProcessingState>(
        'emits [AiProcessingInProgress, AiProcessingSuccess] when processing succeeds',
        build: () {
          final mockResult = ProcessingResult(
            processedImageData: Uint8List.fromList([1, 2, 3, 4]),
            originalPrompt: 'test prompt',
            enhancedPrompt: 'Enhanced test prompt',
            processingTime: const Duration(seconds: 5),
            jobId: 'test-job-123',
            metadata: const <String, dynamic>{
              'mock_processing': true,
              'quality_level': 'standard',
            },
          );
          when(
            () => mockProcessImageWithAiUseCase(
              imageData: any(named: 'imageData'),
              userPrompt: any(named: 'userPrompt'),
              context: any(named: 'context'),
            ),
          ).thenAnswer((_) async => Success(mockResult));
          return cubit;
        },
        act: (cubit) => cubit.processImage(
          image: selectedImage,
          userPrompt: 'Test prompt',
          context: processingContext,
        ),
        expect: () => [
          const AiProcessingInProgress(
            progress: ProcessingProgress(
              stage: ProcessingStage.analyzing,
              progress: 0,
              message: 'Starting AI processing...',
            ),
          ),
          isA<AiProcessingSuccess>().having(
            (state) => state.originalImage,
            'originalImage',
            selectedImage,
          ),
        ],
      );

      blocTest<AiProcessingCubit, AiProcessingState>(
        'emits [AiProcessingInProgress, AiProcessingError] when processing fails',
        build: () {
          when(
            () => mockProcessImageWithAiUseCase(
              imageData: any(named: 'imageData'),
              userPrompt: any(named: 'userPrompt'),
              context: any(named: 'context'),
            ),
          ).thenAnswer((_) async => Failure(Exception('Processing failed')));
          return cubit;
        },
        act: (cubit) => cubit.processImage(
          image: selectedImage,
          userPrompt: 'Test prompt',
          context: processingContext,
        ),
        expect: () => [
          const AiProcessingInProgress(
            progress: ProcessingProgress(
              stage: ProcessingStage.analyzing,
              progress: 0,
              message: 'Starting AI processing...',
            ),
          ),
          isA<AiProcessingError>().having(
            (state) => state.originalImage,
            'originalImage',
            selectedImage,
          ),
        ],
      );
    });

    group('cancelProcessing', () {
      blocTest<AiProcessingCubit, AiProcessingState>(
        'emits AiProcessingCancelled when cancelling during processing',
        build: () => cubit,
        seed: () => const AiProcessingInProgress(
          progress: ProcessingProgress(
            stage: ProcessingStage.aiProcessing,
            progress: 0.5,
            message: 'Processing...',
          ),
        ),
        act: (cubit) => cubit.cancelProcessing(),
        expect: () => [
          const AiProcessingCancelled(),
        ],
      );

      blocTest<AiProcessingCubit, AiProcessingState>(
        'does nothing when not processing',
        build: () => cubit,
        act: (cubit) => cubit.cancelProcessing(),
        expect: () => <AiProcessingState>[],
      );
    });

    group('reset', () {
      blocTest<AiProcessingCubit, AiProcessingState>(
        'emits AiProcessingInitial when reset is called',
        build: () => cubit,
        seed: () => const AiProcessingError(
          message: 'Some error',
          originalImage: SelectedImage(
            path: '/path/to/image.jpg',
            name: 'image.jpg',
            sizeInBytes: 1024000,
            source: ImageSource.gallery,
          ),
        ),
        act: (cubit) => cubit.reset(),
        expect: () => [
          const AiProcessingInitial(),
        ],
      );
    });
  });
}

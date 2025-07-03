import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:revision/helpers/test_data.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/core/services/gemini_pipeline_service.dart';
import 'package:revision/features/ai_processing/domain/usecases/process_image_with_gemini_usecase_improved.dart';
import 'package:revision/features/ai_processing/domain/value_objects/marked_area.dart';
import 'package:revision/features/authentication/data/datasources/firebase_auth_data_source.dart';
import 'package:revision/features/authentication/data/repositories/firebase_authentication_repository.dart';

// Mock classes
class MockFirebaseAuthDataSource extends Mock
    implements FirebaseAuthDataSource {}

class MockGeminiPipelineService extends Mock implements GeminiPipelineService {}

void main() {
  group('Feature Implementation Tests', () {
    late MockFirebaseAuthDataSource mockAuthDataSource;
    late MockGeminiPipelineService mockGeminiService;

    setUpAll(() {
      // Register fallback values for mocktail
      registerFallbackValue(Uint8List.fromList([]));
    });

    setUp(() {
      mockAuthDataSource = MockFirebaseAuthDataSource();
      mockGeminiService = MockGeminiPipelineService();
    });

    group('Authentication Repository getIdToken', () {
      test('should successfully get ID token', () async {
        // Arrange
        const expectedToken = 'test-id-token-12345';
        when(() => mockAuthDataSource.getIdToken())
            .thenAnswer((_) async => expectedToken);

        final repository = FirebaseAuthenticationRepository(
          firebaseAuthDataSource: mockAuthDataSource,
        );

        // Act
        final result = await repository.getIdToken();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) =>
              fail('Expected success but got failure: ${failure.message}'),
          (token) => expect(token, expectedToken),
        );
        verify(() => mockAuthDataSource.getIdToken()).called(1);
      });
    });

    group('Gemini Pipeline Service', () {
      test('should process image with basic prompt', () async {
        // Arrange
        final imageBytes = kTestPng;
        const prompt = 'Test prompt';
        final expectedResult = GeminiPipelineResult(
          originalImage: imageBytes,
          generatedImage: imageBytes,
          analysisPrompt: prompt,
          markedAreas: [],
          processingTimeMs: 100,
        );

        when(() => mockGeminiService.processImage(imageBytes, prompt))
            .thenAnswer((_) async => expectedResult);

        // Act
        final result = await mockGeminiService.processImage(imageBytes, prompt);

        // Assert
        expect(result.originalImage, imageBytes);
        expect(result.analysisPrompt, prompt);
        expect(result.markedAreas, isEmpty);
        verify(() => mockGeminiService.processImage(imageBytes, prompt))
            .called(1);
      });

      test('should process image with marked objects', () async {
        // Arrange
        final imageBytes = kTestPng;
        final markedAreas = [
          {
            'x': 10.0,
            'y': 20.0,
            'width': 30.0,
            'height': 40.0,
            'description': 'test object'
          }
        ];
        final expectedResult = GeminiPipelineResult(
          originalImage: imageBytes,
          generatedImage: imageBytes,
          analysisPrompt: 'Remove test object',
          markedAreas: ['test object'],
          processingTimeMs: 150,
        );

        when(() => mockGeminiService.processImageWithMarkedObjects(
              imageData: imageBytes,
              markedAreas: markedAreas,
            )).thenAnswer((_) async => expectedResult);

        // Act
        final result = await mockGeminiService.processImageWithMarkedObjects(
          imageData: imageBytes,
          markedAreas: markedAreas,
        );

        // Assert
        expect(result.originalImage, imageBytes);
        expect(result.markedAreas, ['test object']);
        verify(() => mockGeminiService.processImageWithMarkedObjects(
              imageData: imageBytes,
              markedAreas: markedAreas,
            )).called(1);
      });
    });

    group('Process Image UseCase', () {
      test('should use marked object removal when areas provided', () async {
        // Arrange
        final imageBytes = kTestPng;
        final markedAreas = [
          const MarkedArea(
            x: 10.0,
            y: 20.0,
            width: 30.0,
            height: 40.0,
            description: 'unwanted object',
          ),
        ];

        final expectedResult = GeminiPipelineResult(
          originalImage: imageBytes,
          generatedImage: imageBytes,
          analysisPrompt: 'Remove unwanted object',
          markedAreas: ['unwanted object'],
          processingTimeMs: 200,
        );

        when(() => mockGeminiService.processImageWithMarkedObjects(
              imageData: any(named: 'imageData'),
              markedAreas: any(named: 'markedAreas'),
            )).thenAnswer((_) async => expectedResult);

        final useCase =
            ProcessImageWithGeminiUseCaseImproved(mockGeminiService);

        // Act
        final result = await useCase.call(imageBytes, markedAreas: markedAreas);

        // Assert
        expect(result.isSuccess, true);
        result.when(
          success: (data) {
            expect(data.markedAreas, ['unwanted object']);
          },
          failure: (error) => fail('Expected success but got failure: $error'),
        );
      });

      test('should use general processing when no marked areas', () async {
        // Arrange
        final imageBytes = kTestPng;
        final markedAreas = <MarkedArea>[];

        final expectedResult = GeminiPipelineResult(
          originalImage: imageBytes,
          generatedImage: imageBytes,
          analysisPrompt:
              'Process and enhance this image for better quality and appearance',
          markedAreas: [],
          processingTimeMs: 150,
        );

        when(() => mockGeminiService.processImage(
              any(),
              'Process and enhance this image for better quality and appearance',
            )).thenAnswer((_) async => expectedResult);

        final useCase =
            ProcessImageWithGeminiUseCaseImproved(mockGeminiService);

        // Act
        final result = await useCase.call(imageBytes, markedAreas: markedAreas);

        // Assert
        expect(result.isSuccess, true);
        result.when(
          success: (data) {
            expect(data.markedAreas, isEmpty);
            expect(data.analysisPrompt, contains('enhance'));
          },
          failure: (error) => fail('Expected success but got failure: $error'),
        );
      });
    });
  });
}

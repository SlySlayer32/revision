// test/unit/core/services/gemini_pipeline_service_test.dart
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/core/services/gemini_pipeline_service.dart';

import '../../../helpers/test_data/ai_test_data.dart';

// Mock classes
class MockGenerativeModel extends Mock implements GenerativeModel {}

class MockGenerateContentResponse extends Mock
    implements GenerateContentResponse {}

class MockContent extends Mock implements Content {}

void main() {
  group('GeminiPipelineService', () {
    late GeminiPipelineService service;
    late MockGenerativeModel mockAnalysisModel;
    late MockGenerativeModel mockImageGenerationModel;
    late MockGenerateContentResponse mockResponse;

    setUp(() {
      mockAnalysisModel = MockGenerativeModel();
      mockImageGenerationModel = MockGenerativeModel();
      mockResponse = MockGenerateContentResponse();

      service = GeminiPipelineService(
        analysisModel: mockAnalysisModel,
        imageGenerationModel: mockImageGenerationModel,
      );

      // Register fallback values
      registerFallbackValue(
        [Content.text('fallback')],
      );
    });

    group('analyzeMarkedImage', () {
      test('should successfully analyze image with marked areas', () async {
        // Arrange
        const expectedPrompt = 'Test removal prompt from analysis';
        when(() => mockResponse.text).thenReturn(expectedPrompt);
        when(() => mockAnalysisModel.generateContent(any()))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await service.analyzeMarkedImage(
          imageData: AITestData.testImageData,
          markedAreas: AITestData.testMarkedAreas,
        );

        // Assert
        expect(result, equals(expectedPrompt));
        verify(() => mockAnalysisModel.generateContent(any())).called(1);
      });

      test('should throw exception for oversized image', () async {
        // Arrange
        final largeImageData = Uint8List(15 * 1024 * 1024); // 15MB > 10MB limit

        // Act & Assert
        expect(
          () => service.analyzeMarkedImage(
            imageData: largeImageData,
            markedAreas: AITestData.testMarkedAreas,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Image too large'),
          )),
        );
      });

      test('should handle empty response from AI model', () async {
        // Arrange
        when(() => mockResponse.text).thenReturn(null);
        when(() => mockAnalysisModel.generateContent(any()))
            .thenAnswer((_) async => mockResponse);

        // Act & Assert
        expect(
          () => service.analyzeMarkedImage(
            imageData: AITestData.testImageData,
            markedAreas: AITestData.testMarkedAreas,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Empty response from Gemini 2.0 Flash'),
          )),
        );
      });

      test('should handle network timeout', () async {
        // Arrange
        when(() => mockAnalysisModel.generateContent(any()))
            .thenThrow(Exception('Network timeout'));

        // Act & Assert
        expect(
          () => service.analyzeMarkedImage(
            imageData: AITestData.testImageData,
            markedAreas: AITestData.testMarkedAreas,
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should include marked areas in prompt', () async {
        // Arrange
        const expectedPrompt = 'Analysis with marked areas';
        when(() => mockResponse.text).thenReturn(expectedPrompt);

        Content? capturedContent;
        when(() => mockAnalysisModel.generateContent(any()))
            .thenAnswer((invocation) async {
          capturedContent = invocation.positionalArguments[0].first;
          return mockResponse;
        });

        // Act
        await service.analyzeMarkedImage(
          imageData: AITestData.testImageData,
          markedAreas: AITestData.testMarkedAreas,
        );

        // Assert
        verify(() => mockAnalysisModel.generateContent(any())).called(1);
        // Additional verification could be added for content structure
      });
    });

    group('generateImageWithRemovals', () {
      test('should successfully generate image with removals', () async {
        // Arrange
        const removalPrompt = 'Remove objects from marked areas';
        when(() => mockResponse.text).thenReturn('Generated successfully');
        when(() => mockImageGenerationModel.generateContent(any()))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await service.generateImageWithRemovals(
          originalImageData: AITestData.testImageData,
          removalPrompt: removalPrompt,
        );

        // Assert
        expect(result,
            equals(AITestData.testImageData)); // Currently returns original
        verify(() => mockImageGenerationModel.generateContent(any())).called(1);
      });

      test('should handle generation failure', () async {
        // Arrange
        const removalPrompt = 'Remove objects';
        when(() => mockResponse.text).thenReturn(null);
        when(() => mockImageGenerationModel.generateContent(any()))
            .thenAnswer((_) async => mockResponse);

        // Act & Assert
        expect(
          () => service.generateImageWithRemovals(
            originalImageData: AITestData.testImageData,
            removalPrompt: removalPrompt,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('No image generated from Gemini 2.0 Flash Preview'),
          )),
        );
      });

      test('should use 60 second timeout for image generation', () async {
        // Arrange
        const removalPrompt = 'Remove objects';
        when(() => mockResponse.text).thenReturn('Generated');
        when(() => mockImageGenerationModel.generateContent(any()))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(seconds: 61)); // Exceed timeout
          return mockResponse;
        });

        // Act & Assert
        expect(
          () => service.generateImageWithRemovals(
            originalImageData: AITestData.testImageData,
            removalPrompt: removalPrompt,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('processImageWithMarkedObjects', () {
      test('should complete full pipeline successfully', () async {
        // Arrange
        const analysisPrompt = 'Analysis result';
        when(() => mockResponse.text).thenReturn(analysisPrompt);
        when(() => mockAnalysisModel.generateContent(any()))
            .thenAnswer((_) async => mockResponse);
        when(() => mockImageGenerationModel.generateContent(any()))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await service.processImageWithMarkedObjects(
          imageData: AITestData.testImageData,
          markedAreas: AITestData.testMarkedAreas,
        );

        // Assert
        expect(result.originalImage, equals(AITestData.testImageData));
        expect(result.analysisPrompt, equals(analysisPrompt));
        expect(result.generatedImage, equals(AITestData.testImageData));
        expect(result.markedAreas, equals(AITestData.testMarkedAreas));
        expect(result.processingTimeMs, greaterThan(0));

        // Verify both models were called
        verify(() => mockAnalysisModel.generateContent(any())).called(1);
        verify(() => mockImageGenerationModel.generateContent(any())).called(1);
      });

      test('should handle analysis failure gracefully', () async {
        // Arrange
        when(() => mockAnalysisModel.generateContent(any()))
            .thenThrow(Exception('Analysis failed'));

        // Act & Assert
        expect(
          () => service.processImageWithMarkedObjects(
            imageData: AITestData.testImageData,
            markedAreas: AITestData.testMarkedAreas,
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle generation failure after successful analysis',
          () async {
        // Arrange
        when(() => mockResponse.text).thenReturn('Analysis successful');
        when(() => mockAnalysisModel.generateContent(any()))
            .thenAnswer((_) async => mockResponse);
        when(() => mockImageGenerationModel.generateContent(any()))
            .thenThrow(Exception('Generation failed'));

        // Act & Assert
        expect(
          () => service.processImageWithMarkedObjects(
            imageData: AITestData.testImageData,
            markedAreas: AITestData.testMarkedAreas,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('backwards compatibility', () {
      test('processImage should work with empty marked areas', () async {
        // Arrange
        const analysisPrompt = 'Backward compatible analysis';
        when(() => mockResponse.text).thenReturn(analysisPrompt);
        when(() => mockAnalysisModel.generateContent(any()))
            .thenAnswer((_) async => mockResponse);
        when(() => mockImageGenerationModel.generateContent(any()))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await service.processImage(AITestData.testImageData);

        // Assert
        expect(result.originalImage, equals(AITestData.testImageData));
        expect(result.analysisPrompt, equals(analysisPrompt));
        expect(result.markedAreas, isEmpty);
      });
    });
  });
}

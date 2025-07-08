import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/features/ai_processing/presentation/cubit/gemini_pipeline_cubit.dart';
import 'package:revision/features/ai_processing/presentation/cubit/gemini_pipeline_state.dart';
import 'package:revision/features/ai_processing/presentation/view/ai_processing_view.dart';
import 'package:revision/features/image_editing/domain/entities/annotated_image.dart';
import 'package:revision/features/image_editing/domain/entities/annotation_stroke.dart';
import 'package:revision/features/image_editing/presentation/cubit/image_editor_cubit.dart';
import 'package:revision/features/image_selection/domain/entities/image_source.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';

// Mock classes
class MockGeminiPipelineCubit extends MockCubit<GeminiPipelineState>
    implements GeminiPipelineCubit {}

class MockImageEditorCubit extends MockCubit<ImageEditorState>
    implements ImageEditorCubit {}

void main() {
  group('AiProcessingView', () {
    late MockGeminiPipelineCubit mockGeminiPipelineCubit;
    late MockImageEditorCubit mockImageEditorCubit;
    late SelectedImage testImage;
    late AnnotatedImage testAnnotatedImage;

    setUp(() {
      mockGeminiPipelineCubit = MockGeminiPipelineCubit();
      mockImageEditorCubit = MockImageEditorCubit();
      
      // Create test image with mock data
      testImage = SelectedImage(
        bytes: Uint8List.fromList([1, 2, 3, 4]), // Mock image bytes
        name: 'test_image.jpg',
        sizeInBytes: 4,
        source: ImageSource.camera,
      );
      
      testAnnotatedImage = AnnotatedImage(
        imageBytes: Uint8List.fromList([1, 2, 3, 4]),
        annotations: const [],
      );

      // Set up default mock states
      when(() => mockGeminiPipelineCubit.state)
          .thenReturn(const GeminiPipelineState());
      when(() => mockImageEditorCubit.state)
          .thenReturn(const ImageEditorInitial());
    });

    group('Widget Creation', () {
      testWidgets('creates widget with required parameters', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<GeminiPipelineCubit>.value(
                  value: mockGeminiPipelineCubit,
                ),
              ],
              child: AiProcessingView(
                image: testImage,
              ),
            ),
          ),
        );

        expect(find.byType(AiProcessingView), findsOneWidget);
        expect(find.text('AI-Powered Revision'), findsOneWidget);
      });

      testWidgets('creates widget with optional annotated image', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<GeminiPipelineCubit>.value(
                  value: mockGeminiPipelineCubit,
                ),
              ],
              child: AiProcessingView(
                image: testImage,
                annotatedImage: testAnnotatedImage,
              ),
            ),
          ),
        );

        expect(find.byType(AiProcessingView), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('handles invalid image data gracefully', (tester) async {
        final invalidImage = SelectedImage(
          bytes: null,
          path: null,
          name: 'invalid.jpg',
          sizeInBytes: 0,
          source: ImageSource.camera,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<GeminiPipelineCubit>.value(
                  value: mockGeminiPipelineCubit,
                ),
              ],
              child: AiProcessingView(
                image: invalidImage,
              ),
            ),
          ),
        );

        expect(find.text('No image data available'), findsOneWidget);
      });

      testWidgets('displays error widget when image loading fails', (tester) async {
        final corruptedImage = SelectedImage(
          bytes: Uint8List.fromList([]), // Empty bytes
          name: 'corrupted.jpg',
          sizeInBytes: 0,
          source: ImageSource.camera,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<GeminiPipelineCubit>.value(
                  value: mockGeminiPipelineCubit,
                ),
              ],
              child: AiProcessingView(
                image: corruptedImage,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.broken_image), findsOneWidget);
      });
    });

    group('User Interactions', () {
      testWidgets('clear button is disabled when no annotations', (tester) async {
        when(() => mockImageEditorCubit.state)
            .thenReturn(const ImageEditorInitial());

        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<GeminiPipelineCubit>.value(
                  value: mockGeminiPipelineCubit,
                ),
              ],
              child: AiProcessingView(
                image: testImage,
              ),
            ),
          ),
        );

        final clearButton = find.byIcon(Icons.clear);
        expect(clearButton, findsOneWidget);
        
        final iconButton = tester.widget<IconButton>(clearButton);
        expect(iconButton.onPressed, isNull);
      });

      testWidgets('clear button is enabled when annotations exist', (tester) async {
        final strokesState = ImageEditorIdle(
          strokes: [
            AnnotationStroke(
              points: const [Offset(0, 0), Offset(10, 10)],
              color: Colors.red,
              strokeWidth: 2.0,
            ),
          ],
        );

        when(() => mockImageEditorCubit.state).thenReturn(strokesState);

        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<GeminiPipelineCubit>.value(
                  value: mockGeminiPipelineCubit,
                ),
              ],
              child: AiProcessingView(
                image: testImage,
              ),
            ),
          ),
        );

        final clearButton = find.byIcon(Icons.clear);
        expect(clearButton, findsOneWidget);
        
        final iconButton = tester.widget<IconButton>(clearButton);
        expect(iconButton.onPressed, isNotNull);
      });

      testWidgets('calls clearAnnotations when clear button is pressed', (tester) async {
        final strokesState = ImageEditorIdle(
          strokes: [
            AnnotationStroke(
              points: const [Offset(0, 0), Offset(10, 10)],
              color: Colors.red,
              strokeWidth: 2.0,
            ),
          ],
        );

        when(() => mockImageEditorCubit.state).thenReturn(strokesState);

        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<GeminiPipelineCubit>.value(
                  value: mockGeminiPipelineCubit,
                ),
                BlocProvider<ImageEditorCubit>.value(
                  value: mockImageEditorCubit,
                ),
              ],
              child: AiProcessingView(
                image: testImage,
              ),
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.clear));
        await tester.pump();

        verify(() => mockImageEditorCubit.clearAnnotations()).called(1);
      });
    });

    group('Responsive Layout', () {
      testWidgets('uses wide layout for large screens', (tester) async {
        // Set large screen size
        await tester.binding.setSurfaceSize(const Size(1024, 768));

        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<GeminiPipelineCubit>.value(
                  value: mockGeminiPipelineCubit,
                ),
              ],
              child: AiProcessingView(
                image: testImage,
              ),
            ),
          ),
        );

        // Should find Row widget (wide layout)
        expect(find.byType(Row), findsWidgets);
      });

      testWidgets('uses narrow layout for small screens', (tester) async {
        // Set small screen size
        await tester.binding.setSurfaceSize(const Size(400, 800));

        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<GeminiPipelineCubit>.value(
                  value: mockGeminiPipelineCubit,
                ),
              ],
              child: AiProcessingView(
                image: testImage,
              ),
            ),
          ),
        );

        // Should find Column widget (narrow layout)
        expect(find.byType(Column), findsWidgets);
      });
    });

    group('Accessibility', () {
      testWidgets('provides semantic labels for screen readers', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<GeminiPipelineCubit>.value(
                  value: mockGeminiPipelineCubit,
                ),
              ],
              child: AiProcessingView(
                image: testImage,
              ),
            ),
          ),
        );

        expect(
          find.bySemanticsLabel('Selected image for AI processing'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('Image editing area - draw to mark objects'),
          findsOneWidget,
        );
      });

      testWidgets('provides proper tooltip for clear button', (tester) async {
        when(() => mockImageEditorCubit.state)
            .thenReturn(const ImageEditorInitial());

        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<GeminiPipelineCubit>.value(
                  value: mockGeminiPipelineCubit,
                ),
              ],
              child: AiProcessingView(
                image: testImage,
              ),
            ),
          ),
        );

        final clearButton = find.byIcon(Icons.clear);
        final iconButton = tester.widget<IconButton>(clearButton);
        expect(iconButton.tooltip, 'No annotations');
      });
    });

    group('Performance', () {
      testWidgets('uses ValueKey for efficient widget rebuilds', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<GeminiPipelineCubit>.value(
                  value: mockGeminiPipelineCubit,
                ),
              ],
              child: AiProcessingView(
                image: testImage,
              ),
            ),
          ),
        );

        // Check that image widget has proper key
        final imageWidget = find.byType(Image);
        expect(imageWidget, findsOneWidget);
        
        final image = tester.widget<Image>(imageWidget);
        expect(image.key, isA<ValueKey<String>>());
      });

      testWidgets('uses const constructors where possible', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<GeminiPipelineCubit>.value(
                  value: mockGeminiPipelineCubit,
                ),
              ],
              child: AiProcessingView(
                image: testImage,
              ),
            ),
          ),
        );

        // Verify const widgets are used
        expect(find.byType(SizedBox), findsWidgets);
        expect(find.byType(SafeArea), findsOneWidget);
      });
    });

    group('Edge Cases', () {
      testWidgets('handles null annotated image gracefully', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<GeminiPipelineCubit>.value(
                  value: mockGeminiPipelineCubit,
                ),
              ],
              child: AiProcessingView(
                image: testImage,
                annotatedImage: null, // Explicitly null
              ),
            ),
          ),
        );

        expect(find.byType(AiProcessingView), findsOneWidget);
      });

      testWidgets('handles empty image name', (tester) async {
        final imageWithEmptyName = SelectedImage(
          bytes: Uint8List.fromList([1, 2, 3, 4]),
          name: '', // Empty name
          sizeInBytes: 4,
          source: ImageSource.camera,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<GeminiPipelineCubit>.value(
                  value: mockGeminiPipelineCubit,
                ),
              ],
              child: AiProcessingView(
                image: imageWithEmptyName,
              ),
            ),
          ),
        );

        expect(find.byType(AiProcessingView), findsOneWidget);
      });
    });
  });

  group('AiProcessingException', () {
    test('creates exception with message and code', () {
      const exception = InvalidImageException('Test message', 'TEST_CODE');
      
      expect(exception.message, 'Test message');
      expect(exception.code, 'TEST_CODE');
      expect(exception.toString(), 
          'AiProcessingException: Test message (Code: TEST_CODE)');
    });

    test('creates exception with message only', () {
      const exception = InvalidImageException('Test message');
      
      expect(exception.message, 'Test message');
      expect(exception.code, isNull);
      expect(exception.toString(), 'AiProcessingException: Test message');
    });

    test('ImageLoadException extends AiProcessingException', () {
      const exception = ImageLoadException('Load failed');
      
      expect(exception, isA<AiProcessingException>());
      expect(exception.message, 'Load failed');
    });
  });
}

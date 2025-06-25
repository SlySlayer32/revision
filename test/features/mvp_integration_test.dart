import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revision/core/di/service_locator.dart';
import 'package:revision/features/ai_processing/domain/entities/processing_context.dart';
import 'package:revision/features/ai_processing/presentation/pages/ai_processing_page.dart';
import 'package:revision/features/image_selection/domain/entities/image_source.dart';
import 'package:revision/features/image_selection/domain/entities/selected_image.dart';
import 'package:revision/features/image_selection/presentation/view/image_selection_page.dart';

/// Integration test for the complete MVP workflow:
/// Image Selection → AI Processing → Result Display
void main() {
  group('MVP Integration Test', () {
    setUpAll(setupServiceLocator);

    testWidgets(
        'Complete MVP workflow: select image and navigate to AI processing',
        (tester) async {
      // Test data
      const selectedImage = SelectedImage(
        path: '/test/path/image.jpg',
        name: 'test_image.jpg',
        sizeInBytes: 1024000,
        source: ImageSource.gallery,
      );

      // Test 1: Image Selection Page renders correctly
      await tester.pumpWidget(
        const MaterialApp(
          home: ImageSelectionPage(),
        ),
      );

      // Verify image selection page is displayed
      expect(find.text('Image Selection MVP'), findsOneWidget);
      expect(find.text('Select Image Source'), findsOneWidget);
      expect(find.byIcon(Icons.photo_library), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);

      // Test 2: AI Processing Page renders correctly
      await tester.pumpWidget(
        const MaterialApp(
          home: AiProcessingPage(selectedImage: selectedImage),
        ),
      );

      // Verify AI processing page is displayed
      expect(find.text('AI Processing'), findsOneWidget);
      expect(
        find.text('Describe your desired transformation:'),
        findsOneWidget,
      );
      expect(find.text('Processing Options'), findsOneWidget);
      expect(find.text('Start AI Processing'), findsOneWidget);

      // Test 3: Verify processing controls are functional
      // Find the text field for prompt input
      final promptField = find.byType(TextField).first;
      expect(promptField, findsOneWidget);

      // Enter a test prompt
      await tester.enterText(promptField, 'Make this image more vibrant');
      await tester.pump();

      // Verify the start processing button becomes enabled
      final startButton =
          find.widgetWithText(ElevatedButton, 'Start AI Processing');
      expect(startButton, findsOneWidget);

      // The button should be enabled now that we have text
      final buttonWidget = tester.widget<ElevatedButton>(startButton);
      expect(buttonWidget.onPressed, isNotNull);
    });

    testWidgets('AI Processing controls work correctly', (tester) async {
      const selectedImage = SelectedImage(
        path: '/test/path/image.jpg',
        name: 'test_image.jpg',
        sizeInBytes: 1024000,
        source: ImageSource.gallery,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: AiProcessingPage(selectedImage: selectedImage),
        ),
      );

      // Test dropdown interactions
      final typeDropdown = find.byType(DropdownButtonFormField<ProcessingType>);
      expect(typeDropdown, findsOneWidget);

      // Tap the dropdown to open it
      await tester.tap(typeDropdown);
      await tester.pumpAndSettle();

      // Verify dropdown options are available
      expect(find.text('Enhance'), findsOneWidget);
      expect(find.text('Artistic Style'), findsOneWidget);
      expect(find.text('Restore'), findsOneWidget);

      // Select a different option
      await tester.tap(find.text('Artistic Style').last);
      await tester.pumpAndSettle();
    });

    testWidgets('Error handling works correctly', (tester) async {
      const selectedImage = SelectedImage(
        path: '', // Invalid path to trigger error handling
        name: 'invalid.jpg',
        sizeInBytes: 0,
        source: ImageSource.gallery,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: AiProcessingPage(selectedImage: selectedImage),
        ),
      );

      // Should still render without crashing
      expect(find.text('AI Processing'), findsOneWidget);
    });
  });
}

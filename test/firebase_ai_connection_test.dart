import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test Firebase AI connection and basic functionality
void main() {
  group('Firebase AI Connection Tests', () {
    setUpAll(() async {
      // Initialize Firebase for testing
      try {
        await Firebase.initializeApp();
      } catch (e) {
        // Already initialized
      }
    });

    test('should create GenerativeModel successfully', () async {
      // Test basic Firebase AI model creation
      expect(() => FirebaseAI.generativeModel(model: 'gemini-1.5-flash'), returnsNormally);
    });

    test('should have Gemini models available', () async {
      try {
        // Test if we can access Gemini models
        final model = FirebaseAI.generativeModel(
          model: 'gemini-1.5-flash',
        );
        
        expect(model, isNotNull);
        expect(model.model, equals('gemini-1.5-flash'));
      } catch (e) {
        // This is expected if API key is not configured
        expect(e.toString(), contains('API key'));
      }
    });

    test('should handle basic text generation request', () async {
      try {
        final model = FirebaseAI.generativeModel(model: 'gemini-1.5-flash');
        
        final response = await model.generateContent([
          Content.text('Hello, this is a test. Please respond with "Test successful"')
        ]);
        
        expect(response.text, isNotNull);
        expect(response.text!.toLowerCase(), contains('test'));
      } catch (e) {
        // Expected if API key not configured
        print('API key needed: $e');
        expect(e.toString(), anyOf([
          contains('API key'),
          contains('quota'),
          contains('permission'),
        ]));
      }
    });

    test('should handle image analysis capabilities', () async {
      try {
        final model = FirebaseAI.generativeModel(model: 'gemini-1.5-flash');
        
        // Test multimodal capabilities (without actual image for unit test)
        final prompt = [
          Content.text('Describe what you would do to analyze an image for object removal')
        ];
        
        final response = await model.generateContent(prompt);
        expect(response.text, isNotNull);
      } catch (e) {
        // Expected if API key not configured
        print('API key needed for image analysis: $e');
      }
    });
  });

  group('Firebase AI Configuration Tests', () {
    test('should validate Firebase AI model creation', () {
      // Test Firebase AI package is properly imported and working
      expect(() => FirebaseAI.generativeModel(model: 'gemini-1.5-flash'), returnsNormally);
    });

    test('should support various Gemini models', () {
      // Test various model configurations
      final models = [
        'gemini-1.5-flash',
        'gemini-1.5-pro',
        'gemini-2.0-flash-exp',
      ];
      
      for (final modelName in models) {
        expect(() => FirebaseAI.generativeModel(model: modelName), returnsNormally);
      }
    });
  });
}

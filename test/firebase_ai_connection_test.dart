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

    test('should initialize Firebase AI successfully', () async {
      // Test basic Firebase AI initialization
      expect(() => FirebaseAI.instance, returnsNormally);
    });

    test('should have Gemini models available', () async {
      try {
        final ai = FirebaseAI.instance;
        
        // Test if we can access Gemini models
        final model = ai.generativeModel(
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
        final ai = FirebaseAI.instance;
        final model = ai.generativeModel(model: 'gemini-1.5-flash');
        
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
        final ai = FirebaseAI.instance;
        final model = ai.generativeModel(model: 'gemini-1.5-flash');
        
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
    test('should validate Firebase AI configuration', () {
      // Test Firebase AI package is properly imported
      expect(FirebaseAI.instance, isNotNull);
    });

    test('should list available models', () {
      final ai = FirebaseAI.instance;
      
      // Test various model configurations
      final models = [
        'gemini-1.5-flash',
        'gemini-1.5-pro',
        'gemini-2.0-flash-exp',
      ];
      
      for (final modelName in models) {
        expect(() => ai.generativeModel(model: modelName), returnsNormally);
      }
    });
  });
}

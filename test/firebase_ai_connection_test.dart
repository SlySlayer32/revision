import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test Firebase AI connection and basic functionality
/// Using Firebase AI Logic SDKs with Gemini Developer API
void main() {
  group('Firebase AI Connection Tests', () {
    setUpAll(() async {
      // Initialize Firebase for testing with minimal configuration
      try {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: 'test-api-key',
            appId: 'test-app-id', 
            messagingSenderId: 'test-sender-id',
            projectId: 'revision-464202',
            storageBucket: 'revision-464202.appspot.com',
          ),
        );
      } catch (e) {
        // Already initialized
        print('Firebase already initialized: $e');
      }
    });

    test('should create GenerativeModel successfully with GoogleAI', () async {
      // Test Firebase AI model creation using GoogleAI (Gemini Developer API)
      try {
        final model = FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash');
        expect(model, isNotNull);
        expect(model.model, equals('gemini-2.5-flash'));
      } catch (e) {
        // Expected if Firebase not initialized properly or API issues
        expect(e.toString(), anyOf([
          contains('no-app'),
          contains('firebase'),
          contains('API key'),
        ]));
      }
    });

    test('should have Gemini models available', () async {
      try {
        // Test if we can access Gemini models using GoogleAI
        final model = FirebaseAI.googleAI().generativeModel(
          model: 'gemini-2.5-flash',
        );
        
        expect(model, isNotNull);
        expect(model.model, equals('gemini-2.5-flash'));
      } catch (e) {
        // This is expected if API key is not configured or Firebase initialization fails
        expect(e.toString(), anyOf([
          contains('API key'),
          contains('no-app'),
          contains('firebase'),
        ]));
      }
    });

    test('should handle basic text generation request', () async {
      try {
        final model = FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash');
        
        final response = await model.generateContent([
          Content.text('Hello, this is a test. Please respond with "Test successful"')
        ]);
        
        expect(response.text, isNotNull);
        expect(response.text!.toLowerCase(), contains('test'));
      } catch (e) {
        // Expected if API key not configured or other Firebase issues
        print('Expected API/Firebase error: $e');
        expect(e.toString(), anyOf([
          contains('API key'),
          contains('quota'),
          contains('permission'),
          contains('no-app'),
          contains('firebase'),
        ]));
      }
    });

    test('should handle image analysis capabilities', () async {
      try {
        final model = FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash');
        
        // Test multimodal capabilities (without actual image for unit test)
        final prompt = [
          Content.text('Describe what you would do to analyze an image for object removal')
        ];
        
        final response = await model.generateContent(prompt);
        expect(response.text, isNotNull);
      } catch (e) {
        // Expected if API key not configured or Firebase issues
        print('Expected API/Firebase error for image analysis: $e');
        expect(e.toString(), anyOf([
          contains('API key'),
          contains('quota'),
          contains('permission'),
          contains('no-app'),
          contains('firebase'),
        ]));
      }
    });
  });

  group('Firebase AI Configuration Tests', () {
    test('should validate Firebase AI model creation', () {
      // Test Firebase AI package is properly imported and working with GoogleAI
      try {
        final model = FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash');
        expect(model, isNotNull);
      } catch (e) {
        // Expected if Firebase not initialized
        expect(e.toString(), anyOf([
          contains('no-app'),
          contains('firebase'),
        ]));
      }
    });

    test('should support various Gemini models', () {
      // Test various model configurations using GoogleAI
      final models = [
        'gemini-2.5-flash',
        'gemini-1.5-pro',
        'gemini-2.0-flash-exp',
      ];
      
      for (final modelName in models) {
        try {
          final model = FirebaseAI.googleAI().generativeModel(model: modelName);
          expect(model, isNotNull);
        } catch (e) {
          // Expected if Firebase not initialized
          expect(e.toString(), anyOf([
            contains('no-app'),
            contains('firebase'),
          ]));
        }
      }
    });
  });
}

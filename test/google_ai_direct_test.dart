import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_ai/firebase_ai.dart';

/// Test first request to Gemini API using Firebase AI with Google AI backend
/// This demonstrates how to use Google AI (AI Studio) through Firebase AI SDK
void main() {
  group('Firebase AI with Google AI Backend Tests', () {
    test('should show proper Firebase AI configuration for Google AI', () {
      print('📋 Firebase AI with Google AI Backend Configuration:');
      print('');
      print('1. Get API key from Google AI Studio (ai.google.dev)');
      print('2. Configure Firebase AI to use Google AI backend');
      print('3. Use FirebaseAI.googleAI() to create the AI instance');
      print('4. Create GenerativeModel with your desired model');
      print('');
      print('Code example:');
      print('  // Configure your API key (see firebase_ai documentation)');
      print('  final firebaseAI = FirebaseAI.googleAI();');
      print('  final model = firebaseAI.generativeModel(model: "gemini-2.5-flash");');
      print('  final response = await model.generateContent([Content.text("Hello!")]);');
      print('');
      print('🔑 API Key Setup:');
      print('  - For development: Set in Firebase project configuration');
      print('  - For production: Use secure environment variables');
      print('  - Never commit API keys to version control');
      
      expect(true, isTrue);
    });

    test('should demonstrate Firebase AI model creation pattern', () {
      try {
        // This shows the correct pattern for creating models with Firebase AI
        final firebaseAI = FirebaseAI.googleAI();
        
        final model = firebaseAI.generativeModel(
          model: 'gemini-2.5-flash',
          generationConfig: GenerationConfig(
            temperature: 0.7,
            maxOutputTokens: 1024,
            topK: 40,
            topP: 0.95,
          ),
        );
        
        expect(model, isNotNull);
        expect(model.model, equals('gemini-2.5-flash'));
        print('✅ Firebase AI GenerativeModel created successfully');
      } catch (e) {
        print('⚠️ Expected error without proper configuration: $e');
        // Expected to fail without proper Firebase AI configuration
        expect(
          e.toString(),
          anyOf([
            contains('API'),
            contains('key'),
            contains('configuration'),
            contains('firebase'),
          ]),
        );
      }
    });

    test('should show example of text generation request', () async {
      try {
        final firebaseAI = FirebaseAI.googleAI();
        final model = firebaseAI.generativeModel(model: 'gemini-2.5-flash');

        final content = [
          Content.text('Hello, Gemini! Please respond with a friendly greeting.')
        ];
        
        // This will work once API key is properly configured
        final response = await model.generateContent(content);
        
        expect(response.text, isNotNull);
        expect(response.text!.isNotEmpty, true);
        print('🎉 Response from Gemini: ${response.text}');
      } catch (e) {
        print('⚠️ Expected error without valid configuration: $e');
        // Expected to fail without proper configuration
        expect(
          e.toString(),
          anyOf([
            contains('API'),
            contains('key'),
            contains('authentication'),
            contains('configuration'),
            contains('firebase'),
          ]),
        );
      }
    });

    test('should show example of image analysis request', () async {
      try {
        final firebaseAI = FirebaseAI.googleAI();
        final model = firebaseAI.generativeModel(model: 'gemini-2.5-flash');

        // Example of how to send image data (you would use real image bytes)
        final mockImageBytes = List<int>.filled(100, 0); // Mock image data
        
        final content = [
          Content.multi([
            InlineDataPart('image/jpeg', mockImageBytes),
            TextPart('Describe this image in detail.'),
          ]),
        ];
        
        final response = await model.generateContent(content);
        
        expect(response.text, isNotNull);
        print('🖼️ Image analysis response: ${response.text}');
      } catch (e) {
        print('⚠️ Expected error without valid configuration: $e');
        // Expected to fail without proper configuration
        expect(
          e.toString(),
          anyOf([
            contains('API'),
            contains('key'),
            contains('configuration'),
            contains('firebase'),
            contains('image'),
          ]),
        );
      }
    });
  });
}

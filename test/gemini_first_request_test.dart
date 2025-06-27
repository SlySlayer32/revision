import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revision/core/services/gemini_ai_service.dart';
import 'package:revision/firebase_options_dev.dart';

/// Test first request to Gemini API using Google AI (AI Studio)
/// This test validates the complete Google AI setup and sends a real request
void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Gemini API First Request Tests', () {
    late GeminiAIService aiService;

    setUpAll(() async {
      try {
        // Initialize Firebase with development configuration
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print('✅ Firebase initialized successfully');

        // Initialize our Google AI service
        aiService = GeminiAIService();
        print('✅ Google AI service initialized successfully');
      } catch (e) {
        print('⚠️ Initialization error: $e');
        rethrow;
      }
    });

    test('should send first request to Gemini 2.5 Flash - Simple Text Generation',
        () async {
      try {
        // Provide a prompt that contains text - Simple test prompt
        final prompt = [
          Content.text(
              'Hello Gemini! Please respond with "Hello from Firebase AI!"')
        ];

        // Use our AI service to generate content
        final response = await aiService.processTextPrompt(prompt.first.text);

        print('🎉 First response from Gemini 2.5 Flash:');
        print(response);

        expect(response, isNotNull);
        expect(response.isNotEmpty, true);
        expect(response.toLowerCase(), contains('hello'));
      } catch (e) {
        print('⚠️ Error generating content: $e');
        rethrow;
      }
    });

    test('should test image editing specific prompt with Gemini 2.5 Flash',
        () async {
      try {
        // Test prompt related to your Revision app's use case
        final prompt = 
            'You are an AI assistant for a photo editing app called "Revision". '
            'Explain in 2-3 sentences how AI can help users remove unwanted objects from photos.';

        // Use our AI service to generate content
        final response = await aiService.processTextPrompt(prompt);

        print('🖼️ Image editing response from Gemini 2.5 Flash:');
        print(response);

        expect(response, isNotNull);
        expect(response.isNotEmpty, true);
        expect(
            response.toLowerCase(),
            anyOf([
              contains('photo'),
              contains('image'),
              contains('remove'),
              contains('object'),
              contains('edit'),
            ]));
      } catch (e) {
        print('⚠️ Error generating content: $e');
        rethrow;
      }
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:revision/test_firebase_ai.dart';

/// Unit test to verify Firebase AI setup
/// Run with: flutter test test/firebase_ai_test.dart
void main() {
  group('Firebase AI Tests', () {
    
    test('Firebase AI basic configuration test', () async {
      // This test doesn't require Firebase to be initialized
      // Just tests that we can create the objects without error
      
      expect(() {
        // Test that we can create Firebase AI instance
        final firebaseAI = FirebaseAI.googleAI();
        
        // Test that we can create a model instance
        final model = firebaseAI.generativeModel(
          model: 'gemini-1.5-flash',
          generationConfig: GenerationConfig(
            temperature: 0.4,
            maxOutputTokens: 100,
            topK: 40,
            topP: 0.95,
          ),
        );
        
        // If we get here without exceptions, basic setup is correct
        expect(model, isNotNull);
        
      }, returnsNormally);
    });
    
    test('Content creation test', () {
      // Test that we can create Content objects correctly
      final textContent = Content.text('Hello, world!');
      expect(textContent, isNotNull);
      
      final multiContent = Content.multi([
        TextPart('Hello'),
        TextPart('World'),
      ]);
      expect(multiContent, isNotNull);
    });
    
    test('Generation config test', () {
      // Test that we can create GenerationConfig with proper parameters
      final config = GenerationConfig(
        temperature: 0.4,
        maxOutputTokens: 1024,
        topK: 40,
        topP: 0.95,
      );
      expect(config, isNotNull);
    });
  });
}

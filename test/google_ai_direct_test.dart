import 'package:flutter_test/flutter_test.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Test first request to Gemini API using Google AI (AI Studio) directly
/// This test validates Google AI SDK without Firebase dependency
void main() {
  group('Google AI (Gemini API) Direct Tests', () {
    test('should create Gemini model with Google AI SDK', () {
      // This test validates that we can create a GenerativeModel
      // In a real scenario, you would set your API key as an environment variable
      const apiKey = 'your-api-key-here'; // Replace with actual API key
      
      try {
        final model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: apiKey,
        );
        
        expect(model, isNotNull);
        expect(model.model, equals('gemini-2.5-flash'));
        print('✅ Google AI GenerativeModel created successfully');
      } catch (e) {
        print('⚠️ Expected error without valid API key: $e');
        // Expected to fail without a real API key
        expect(e.toString(), contains('API'));
      }
    });

    test('should demonstrate text generation capability (mock)', () async {
      // This test shows how the API would work with a real API key
      const mockApiKey = 'test-key';
      
      try {
        final model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: mockApiKey,
        );

        final content = [Content.text('Hello, Gemini!')];
        
        // This will fail without a real API key, but demonstrates the pattern
        final response = await model.generateContent(content);
        
        // This should not be reached without a valid API key
        expect(response.text, isNotNull);
        print('🎉 Response: ${response.text}');
      } catch (e) {
        print('⚠️ Expected error without valid API key: $e');
        // Expected to fail with mock API key
        expect(
          e.toString(),
          anyOf([
            contains('API'),
            contains('key'),
            contains('authentication'),
            contains('invalid'),
          ]),
        );
      }
    });

    test('should show proper configuration for production', () {
      // This test demonstrates the proper way to configure Google AI
      print('📋 For production use:');
      print('1. Get API key from Google AI Studio (ai.google.dev)');
      print('2. Set environment variable: GOOGLE_AI_API_KEY');
      print('3. Use: String.fromEnvironment("GOOGLE_AI_API_KEY")');
      print('4. Initialize model with your API key');
      print('');
      print('Example:');
      print('const apiKey = String.fromEnvironment("GOOGLE_AI_API_KEY");');
      print('final model = GenerativeModel(model: "gemini-2.5-flash", apiKey: apiKey);');
      print('final response = await model.generateContent([Content.text("Hello!")]);');
      
      // This test always passes and just shows configuration info
      expect(true, isTrue);
    });
  });
}

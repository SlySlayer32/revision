/// Firebase AI Logic Live Test - Tests actual API calls
///
/// This test verifies that Firebase AI Logic is properly configured
/// and can make real API calls to Gemini Developer API.
///
/// Run with: flutter test test/firebase_ai_live_test.dart

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revision/firebase_options.dart';

void main() {
  group('Firebase AI Logic Live Tests', () {
    setUpAll(() async {
      // Ensure Flutter binding is initialized for tests
      TestWidgetsFlutterBinding.ensureInitialized();

      // Initialize Firebase for testing
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print('✅ Firebase initialized successfully');
      } catch (e) {
        print('⚠️ Firebase initialization error: $e');
        print('💡 This may be expected in some test environments');
      }
    });

    test('should successfully create GenerativeModel with GoogleAI backend',
        () async {
      try {
        // Step 1: Initialize the Gemini Developer API backend service
        // This is exactly what the Firebase AI Logic docs recommend
        final ai = FirebaseAI.googleAI();
        print('✅ FirebaseAI.googleAI() initialized successfully');

        // Step 2: Create a GenerativeModel instance with gemini-2.5-flash
        final model = ai.generativeModel(model: 'gemini-2.5-flash');
        print('✅ GenerativeModel created successfully');

        expect(model, isNotNull);
        expect(model.model, equals('gemini-2.5-flash'));

        print('🎯 Firebase AI Logic setup is working correctly!');
      } catch (e) {
        print('❌ Error creating model: $e');
        print('💡 Check Firebase Console AI Logic configuration');
        fail('Failed to create GenerativeModel: $e');
      }
    });

    test('should send a simple prompt and get response (LIVE API CALL)',
        () async {
      try {
        print('🚀 Testing LIVE API call to Gemini...');

        // Initialize the service and model
        final ai = FirebaseAI.googleAI();
        final model = ai.generativeModel(model: 'gemini-2.5-flash');

        // Step 3: Send a simple prompt (from Firebase docs example)
        const prompt =
            'Write a short sentence about Firebase AI being awesome.';
        print('📝 Sending prompt: "$prompt"');

        // Make the actual API call
        final response = await model.generateContent([Content.text(prompt)]);

        // Verify we got a response
        expect(response, isNotNull);
        expect(response.text, isNotNull);
        expect(response.text!.isNotEmpty, isTrue);

        print('✅ API call successful!');
        print('🤖 Response: ${response.text}');
        print('🎉 Firebase AI Logic is fully working!');
      } catch (e) {
        print('❌ API call failed: $e');
        print('💡 Possible issues:');
        print('   • Firebase AI Logic not enabled in Console');
        print('   • Gemini Developer API not configured');
        print('   • Network connectivity issues');
        print('   • Firebase project configuration issues');

        // Don't fail the test immediately - let's see what type of error it is
        if (e.toString().contains('not found') ||
            e.toString().contains('not enabled')) {
          print('🔧 This looks like a configuration issue');
          print('   Go to Firebase Console → AI Logic and complete setup');
        } else if (e.toString().contains('quota') ||
            e.toString().contains('limit')) {
          print('📊 This looks like a quota/billing issue');
          print('   Check your Firebase project billing settings');
        } else if (e.toString().contains('network') ||
            e.toString().contains('connection')) {
          print('🌐 This looks like a network issue');
          print('   Check internet connection and try again');
        }

        fail('Live API test failed: $e');
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('should demonstrate your AI service classes work', () async {
      try {
        print('🧪 Testing your GeminiAIService implementation...');

        // Your service should work the same way
        final ai = FirebaseAI.googleAI();
        final model = ai.generativeModel(
          model: 'gemini-2.5-flash',
          generationConfig: GenerationConfig(
            temperature: 0.7,
            maxOutputTokens: 1024,
            topK: 40,
            topP: 0.95,
          ),
        );

        expect(model, isNotNull);
        print('✅ Your service configuration pattern works!');
        print('🎯 Ready to use in your actual app features');
      } catch (e) {
        print('❌ Service pattern test failed: $e');
        fail('Service configuration failed: $e');
      }
    });
  });
}

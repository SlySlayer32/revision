import 'dart:developer';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';

/// Simple test function to verify Firebase AI setup
/// Call this from your main app to test the initial generateContent call
class FirebaseAITester {
  static Future<void> testFirebaseAI() async {
    try {
      log('🧪 Starting Firebase AI test...');
      
      // Check if Firebase is initialized
      if (Firebase.apps.isEmpty) {
        log('❌ Firebase not initialized! Please ensure Firebase.initializeApp() was called.');
        return;
      }
      
      log('✅ Firebase is initialized');
      
      // Initialize Firebase AI with Google AI backend
      log('🔧 Creating Firebase AI instance...');
      final firebaseAI = FirebaseAI.googleAI();
      log('✅ Firebase AI instance created');
      
      // Create a simple Gemini model
      log('🔧 Creating Gemini model instance...');
      final model = firebaseAI.generativeModel(
        model: 'gemini-1.5-flash', // Using stable model
        generationConfig: GenerationConfig(
          temperature: 0.4,
          maxOutputTokens: 100, // Small response for test
          topK: 40,
          topP: 0.95,
        ),
      );
      log('✅ Gemini model instance created');
      
      // Make a simple test call
      log('🚀 Making test API call to Gemini...');
      final prompt = 'Hello! Please respond with "Firebase AI is working!" if you can see this message.';
      
      final response = await model.generateContent([
        Content.text(prompt)
      ]).timeout(const Duration(seconds: 30));
      
      if (response.text != null && response.text!.isNotEmpty) {
        log('✅ SUCCESS! Gemini responded: ${response.text}');
        log('🎉 Firebase AI setup is working correctly!');
      } else {
        log('❌ FAILED: Empty response from Gemini');
        log('📝 Response object: ${response.toString()}');
      }
      
    } catch (e, stackTrace) {
      log('❌ FAILED: Firebase AI test failed with error: $e');
      log('📝 Stack trace: $stackTrace');
      
      // Provide specific error guidance
      if (e.toString().contains('API key')) {
        log('💡 SOLUTION: Check that Gemini API key is configured in Firebase Console');
        log('   1. Go to Firebase Console > Build > Firebase AI Logic');
        log('   2. Make sure Gemini Developer API is enabled');
        log('   3. Verify API key is properly configured');
      } else if (e.toString().contains('quota') || e.toString().contains('billing')) {
        log('💡 SOLUTION: Check API quotas and billing in Google Cloud Console');
      } else if (e.toString().contains('network') || e.toString().contains('timeout')) {
        log('💡 SOLUTION: Check internet connection and Firebase configuration');
      } else {
        log('💡 SOLUTION: Check the error details above and Firebase AI Logic setup');
      }
    }
  }
  
  /// Test with more detailed configuration matching your app's setup
  static Future<void> testWithAppConfig() async {
    try {
      log('🧪 Starting Firebase AI test with app configuration...');
      
      // Use the same configuration as your GeminiAIService
      final firebaseAI = FirebaseAI.googleAI();
      
      final model = firebaseAI.generativeModel(
        model: 'gemini-1.5-flash', // Your default model
        generationConfig: GenerationConfig(
          temperature: 0.4,        // Your default temperature
          maxOutputTokens: 1024,   // Your default max tokens
          topK: 40,                // Your default topK
          topP: 0.95,              // Your default topP
        ),
        systemInstruction: Content.text('''
You are an expert image analysis AI. Analyze the provided image and marked object to create precise editing instructions.

Focus on:
1. Object identification and boundaries
2. Background reconstruction techniques  
3. Lighting and shadow analysis
4. Color harmony considerations
5. Realistic removal strategies

Provide actionable editing instructions.
'''),
      );
      
      log('✅ Model created with app configuration');
      
      // Test the exact same call pattern as your service
      final testPrompt = 'Test: Can you confirm you are working and ready to analyze images?';
      
      final response = await model.generateContent([
        Content.text(testPrompt)
      ]).timeout(const Duration(seconds: 30));
      
      if (response.text != null && response.text!.isNotEmpty) {
        log('✅ SUCCESS with app config! Response: ${response.text}');
      } else {
        log('❌ FAILED with app config: Empty response');
      }
      
    } catch (e, stackTrace) {
      log('❌ FAILED with app config: $e');
      log('📝 Stack trace: $stackTrace');
    }
  }
}

import 'dart:developer';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ai/firebase_ai.dart';

// Import your Firebase options
import '../lib/firebase_options.dart';

/// Simple script to test Firebase AI setup
/// Run with: dart run scripts/test_firebase_ai.dart
Future<void> main() async {
  try {
    print('🧪 Starting Firebase AI Test Script...');
    
    // Initialize Firebase first
    print('🔥 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
    
    // Test Firebase AI
    print('🤖 Testing Firebase AI...');
    await testFirebaseAI();
    
    print('🎉 Test completed successfully!');
    exit(0);
    
  } catch (e, stackTrace) {
    print('❌ Test failed: $e');
    print('📝 Stack trace: $stackTrace');
    exit(1);
  }
}

Future<void> testFirebaseAI() async {
  try {
    print('🔧 Creating Firebase AI instance...');
    final firebaseAI = FirebaseAI.googleAI();
    print('✅ Firebase AI instance created');
    
    print('🔧 Creating Gemini model...');
    final model = firebaseAI.generativeModel(
      model: 'gemini-1.5-flash',
      generationConfig: GenerationConfig(
        temperature: 0.4,
        maxOutputTokens: 200,
        topK: 40,
        topP: 0.95,
      ),
    );
    print('✅ Gemini model created');
    
    print('🚀 Making API call...');
    final prompt = 'Hello! Can you respond with "Firebase AI is working correctly!" to confirm you are operational?';
    
    final response = await model.generateContent([
      Content.text(prompt)
    ]).timeout(const Duration(seconds: 30));
    
    if (response.text != null && response.text!.isNotEmpty) {
      print('✅ SUCCESS! Gemini API responded:');
      print('📝 Response: ${response.text}');
      print('🎉 Firebase AI is working correctly!');
    } else {
      print('❌ FAILED: Empty response from Gemini');
      throw Exception('Empty response from Gemini API');
    }
    
  } catch (e, stackTrace) {
    print('❌ Firebase AI test failed: $e');
    
    // Provide helpful error guidance
    final errorString = e.toString();
    if (errorString.contains('API key') || errorString.contains('INVALID_ARGUMENT')) {
      print('💡 SOLUTION: API Key Issue');
      print('   1. Go to Firebase Console: https://console.firebase.google.com');
      print('   2. Select your project: revision-464202');
      print('   3. Go to Build > Firebase AI Logic');
      print('   4. Make sure "Gemini Developer API" is enabled');
      print('   5. Check that API key is properly configured');
    } else if (errorString.contains('quota') || errorString.contains('RESOURCE_EXHAUSTED')) {
      print('💡 SOLUTION: API Quota Issue');
      print('   1. Check your Gemini API quota in Google AI Studio');
      print('   2. You may have hit the free tier limit');
      print('   3. Wait for quota to reset or upgrade to paid tier');
    } else if (errorString.contains('PERMISSION_DENIED')) {
      print('💡 SOLUTION: Permission Issue');
      print('   1. Make sure Gemini API is enabled in your Firebase project');
      print('   2. Check that your Firebase project has the correct permissions');
    } else if (errorString.contains('network') || errorString.contains('SocketException')) {
      print('💡 SOLUTION: Network Issue');
      print('   1. Check your internet connection');
      print('   2. Try again in a few moments');
    } else {
      print('💡 SOLUTION: Check Firebase AI Logic setup in Firebase Console');
    }
    
    rethrow;
  }
}

#!/usr/bin/env dart

import 'dart:io';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';

/// Simple test script to verify Gemini 2.5 Flash works with your API key
/// Run with: dart run scripts/test_gemini.dart
/// Or: flutter test --dart-define=GEMINI_API_KEY=your_key_here test/gemini_first_request_test.dart

Future<void> main() async {
  print('🚀 Testing Gemini 2.5 Flash with Firebase AI...');

  try {
    // Initialize Firebase with minimal config for testing
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'test-api-key',
        appId: 'test-app-id',
        messagingSenderId: 'test-sender-id',
        projectId: 'revision-464202',
        storageBucket: 'revision-464202.appspot.com',
      ),
    );
    print('✅ Firebase initialized');

    // Initialize the Gemini Developer API backend service
    final model =
        FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash');
    print('✅ Gemini 2.5 Flash model created');

    // Test 1: Simple greeting
    print('\n📝 Test 1: Simple greeting...');
    final prompt1 = [
      Content.text(
          'Hello Gemini! Please respond with "Hello from Firebase AI!"')
    ];
    final response1 = await model.generateContent(prompt1);
    print('Response: ${response1.text}');

    // Test 2: Magic backpack story (from Firebase docs)
    print('\n📚 Test 2: Magic backpack story...');
    final prompt2 = [Content.text('Write a story about a magic backpack.')];
    final response2 = await model.generateContent(prompt2);
    print('Story: ${response2.text}');

    // Test 3: Revision app specific
    print('\n🖼️ Test 3: Photo editing advice...');
    final prompt3 = [
      Content.text(
          'You are an AI assistant for a photo editing app called "Revision". '
          'Explain in 2-3 sentences how AI can help users remove unwanted objects from photos.')
    ];
    final response3 = await model.generateContent(prompt3);
    print('Advice: ${response3.text}');

    print('\n🎉 All tests completed successfully!');
    print('✅ Your Firebase AI + Gemini 2.5 Flash setup is working perfectly!');
  } catch (e) {
    if (e.toString().contains('API key')) {
      print('\n⚠️ API Key needed!');
      print('Get your API key from: https://aistudio.google.com/app/apikey');
      print(
          'Then run with: flutter test --dart-define=GEMINI_API_KEY=your_key test/gemini_first_request_test.dart');
    } else {
      print('\n❌ Error: $e');
    }
    exit(1);
  }
}

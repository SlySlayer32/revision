import 'package:firebase_ai/firebase_ai.dart';

void main() {
  // Test what enums and classes are available from firebase_ai
  print('Available from firebase_ai package:');

  // Try to access ResponseModality enum if it exists
  try {
    print('ResponseModality available');
  } catch (e) {
    print('ResponseModality not available: $e');
  }

  // Check GenerationConfig constructor
  GenerationConfig(
    temperature: 0.3,
    maxOutputTokens: 1024,
    topK: 32,
    topP: 0.9,
  );

  print('GenerationConfig created successfully');
}

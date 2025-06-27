import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:revision/firebase_options.dart';

/// Example demonstrating how to use Gemini 2.5 Flash model 
/// with Firebase AI Logic SDK
/// 
/// This follows the official Firebase AI documentation pattern
class GeminiService {
  late final GenerativeModel _model;
  bool _isInitialized = false;

  /// Initialize Firebase AI and create Gemini 2.5 Flash model
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Step 1: Initialize Firebase (if not already done)
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print('✅ Firebase initialized successfully');
      }

      // Step 2: Initialize the Gemini Developer API backend service
      // Create a GenerativeModel instance with Gemini 2.5 Flash
      _model = FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash');
      
      _isInitialized = true;
      print('✅ Gemini 2.5 Flash model initialized successfully');
      
    } catch (e) {
      print('❌ Failed to initialize Gemini service: $e');
      rethrow;
    }
  }

  /// Send a simple text prompt to Gemini 2.5 Flash
  Future<String?> generateText(String promptText) async {
    if (!_isInitialized) {
      throw Exception('GeminiService not initialized. Call initialize() first.');
    }

    try {
      // Provide a prompt that contains text
      final prompt = [Content.text(promptText)];
      
      // To generate text output, call generateContent with the text input
      final response = await _model.generateContent(prompt);
      
      print('🎉 Response from Gemini 2.5 Flash: ${response.text}');
      return response.text;
      
    } catch (e) {
      print('❌ Error generating content: $e');
      rethrow;
    }
  }

  /// Send an image analysis prompt to Gemini 2.5 Flash
  /// This is useful for the Revision app's object detection features
  Future<String?> analyzeImageDescription(String imageDescription) async {
    if (!_isInitialized) {
      throw Exception('GeminiService not initialized. Call initialize() first.');
    }

    try {
      // Create a prompt for image analysis
      final prompt = [Content.text(
        'You are an AI assistant for a photo editing app called "Revision". '
        'The user has an image with the following description: "$imageDescription". '
        'Suggest what objects or elements could be removed or edited to improve the photo. '
        'Provide 2-3 specific suggestions.'
      )];
      
      final response = await _model.generateContent(prompt);
      
      print('🖼️ Image analysis from Gemini 2.5 Flash: ${response.text}');
      return response.text;
      
    } catch (e) {
      print('❌ Error analyzing image: $e');
      rethrow;
    }
  }

  /// Example: Send the magic backpack story prompt from Firebase documentation
  Future<String?> generateMagicBackpackStory() async {
    if (!_isInitialized) {
      throw Exception('GeminiService not initialized. Call initialize() first.');
    }

    try {
      // Use the exact example from Firebase AI documentation
      final prompt = [Content.text('Write a story about a magic backpack.')];
      
      final response = await _model.generateContent(prompt);
      
      print('📚 Magic backpack story: ${response.text}');
      return response.text;
      
    } catch (e) {
      print('❌ Error generating story: $e');
      rethrow;
    }
  }
}

/// Example usage function
Future<void> exampleUsage() async {
  final geminiService = GeminiService();
  
  try {
    // Initialize the service
    await geminiService.initialize();
    
    // Example 1: Simple text generation
    final greeting = await geminiService.generateText(
      'Hello Gemini! Please respond with "Hello from Firebase AI!"'
    );
    print('Greeting: $greeting');
    
    // Example 2: Magic backpack story (from Firebase docs)
    final story = await geminiService.generateMagicBackpackStory();
    print('Story: $story');
    
    // Example 3: Image analysis for Revision app
    final analysis = await geminiService.analyzeImageDescription(
      'A landscape photo with a person walking in the foreground and mountains in the background'
    );
    print('Analysis: $analysis');
    
  } catch (e) {
    print('❌ Error in example usage: $e');
  }
}

import 'dart:typed_data';
import 'dart:developer';

import 'package:revision/core/services/ai_fallback_service.dart';
import 'package:revision/core/services/gemini_ai_service.dart';
// Vertex AI service removed - using Firebase AI Logic only
import 'package:revision/core/services/firebase_ai_remote_config_service.dart';

/// Demonstration of comprehensive error handling
/// Shows how the app gracefully handles AI service failures
void main() async {
  log('🎬 Starting Error Handling Demonstration');

  // Create test image data
  final testImageData = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);

  // Test 1: Direct fallback service
  await _testFallbackService(testImageData);

  // Test 2: Service selector with fallback
  await _testServiceSelector(testImageData);

  // Test 3: Individual service resilience
  await _testIndividualServices(testImageData);

  log('🎉 Error Handling Demonstration Complete!');
}

/// Test the fallback service directly
Future<void> _testFallbackService(Uint8List imageData) async {
  log('📌 Test 1: Fallback Service');

  final fallbackService = const AIFallbackService();

  try {
    // Test various operations
    await fallbackService.processImagePrompt(
        imageData, 'remove the person from background');
    log('✅ Fallback processImagePrompt: Working');

    await fallbackService.generateImageDescription(imageData);
    log('✅ Fallback generateImageDescription: Working');

    final result3 = await fallbackService.suggestImageEdits(imageData);
    log('✅ Fallback suggestImageEdits: ${result3.length} suggestions');

    await fallbackService.generateEditingPrompt(
      imageBytes: imageData,
      markers: [
        {'x': 100, 'y': 200}
      ],
    );
    log('✅ Fallback generateEditingPrompt: Working');

    final result5 = await fallbackService.processImageWithAI(
      imageBytes: imageData,
      editingPrompt: 'enhance image',
    );
    log('✅ Fallback processImageWithAI: ${result5.length} bytes');
  } catch (e) {
    log('❌ Fallback service test failed: $e');
  }
}

/// Test the service selector with multiple services
Future<void> _testServiceSelector(Uint8List imageData) async {
  log('📌 Test 2: Service Selector with Fallback');

  try {
    // Create services
    AIServiceSelector? serviceSelector;

    try {
      final remoteConfig = FirebaseAIRemoteConfigService();
      final primaryService = GeminiAIService(remoteConfigService: remoteConfig);
      // Secondary service removed - using Firebase AI Logic only
      // final secondaryService = VertexAIService();

      serviceSelector = AIServiceSelector(
        primaryService: primaryService,
        secondaryService: null, // No secondary service - Firebase AI Logic only
        fallbackService: const AIFallbackService(),
      );

      log('✅ Service selector created successfully');
    } catch (e) {
      log('⚠️ Could not create full service selector: $e');
      log('🔄 Using fallback-only selector');

      serviceSelector = AIServiceSelector(
        primaryService: const AIFallbackService(),
        fallbackService: const AIFallbackService(),
      );
    }

    // Test operations with selector
    await serviceSelector.processImagePrompt(imageData, 'enhance this photo');
    log('✅ Service selector processImagePrompt: Success');

    await serviceSelector.generateImageDescription(imageData);
    log('✅ Service selector generateImageDescription: Success');

    final result3 = await serviceSelector.suggestImageEdits(imageData);
    log('✅ Service selector suggestImageEdits: ${result3.length} suggestions');
  } catch (e) {
    log('❌ Service selector test failed: $e');
  }
}

/// Test individual services to show error handling
Future<void> _testIndividualServices(Uint8List imageData) async {
  log('📌 Test 3: Individual Service Error Handling');

  // Test each service individually to show error handling works
  await _testGeminiService(imageData);
  // Vertex AI service test removed - using Firebase AI Logic only
  // await _testVertexService(imageData);
}

/// Test Gemini service error handling
Future<void> _testGeminiService(Uint8List imageData) async {
  log('🔍 Testing GeminiAIService error handling...');

  try {
    final remoteConfig = FirebaseAIRemoteConfigService();
    final geminiService = GeminiAIService(remoteConfigService: remoteConfig);

    // Wait for initialization
    await geminiService.waitForInitialization();

    // Test with a simple operation that might trigger the parsing error
    final result = await geminiService.processImagePrompt(
        imageData, 'describe this image');

    log('✅ GeminiAIService working: ${result.substring(0, 50)}...');
  } catch (e) {
    if (e.toString().contains('role: model') ||
        e.toString().contains('Unhandled format')) {
      log('🎯 GeminiAIService: Detected known parsing error - Error handler will manage this');
    } else {
      log('⚠️ GeminiAIService: Different error - $e');
    }
  }
}

/// Vertex AI service test removed - using Firebase AI Logic only
/*
Future<void> _testVertexService(Uint8List imageData) async {
  log('🔍 Testing VertexAIService error handling...');
  
  try {
    final vertexService = VertexAIService();
    
    // Test with a simple operation
    final result = await vertexService.processImagePrompt(
      imageData,
      'analyze this image'
    );
    
    log('✅ VertexAIService working: ${result.substring(0, 50)}...');
    
  } catch (e) {
    if (e.toString().contains('role: model') || 
        e.toString().contains('Unhandled format')) {
      log('🎯 VertexAIService: Detected known parsing error - Error handler will manage this');
    } else {
      log('⚠️ VertexAIService: Different error - $e');
    }
  }
}
*/

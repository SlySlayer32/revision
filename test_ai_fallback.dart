import 'dart:typed_data';
import 'dart:developer';

import 'lib/core/services/ai_fallback_service.dart';
import 'lib/core/services/ai_service_factory.dart';

void main() async {
  log('🧪 Testing AI Fallback Service...');
  
  // Test fallback service directly
  final fallbackService = const AIFallbackService();
  final testImageData = Uint8List.fromList([1, 2, 3, 4, 5]); // Dummy image
  
  try {
    // Test image prompt processing
    final result1 = await fallbackService.processImagePrompt(
      testImageData, 
      'remove the person from this photo'
    );
    log('✅ Fallback processImagePrompt: ${result1.substring(0, 50)}...');
    
    // Test image description
    final result2 = await fallbackService.generateImageDescription(testImageData);
    log('✅ Fallback generateImageDescription: ${result2.substring(0, 50)}...');
    
    // Test edit suggestions
    final result3 = await fallbackService.suggestImageEdits(testImageData);
    log('✅ Fallback suggestImageEdits: ${result3.length} suggestions');
    
    // Test content safety
    final result4 = await fallbackService.checkContentSafety(testImageData);
    log('✅ Fallback checkContentSafety: $result4');
    
    // Test editing prompt generation
    final result5 = await fallbackService.generateEditingPrompt(
      imageBytes: testImageData,
      markers: [
        {'x': 100, 'y': 200, 'description': 'unwanted object'}
      ],
    );
    log('✅ Fallback generateEditingPrompt: ${result5.substring(0, 50)}...');
    
    // Test AI image processing
    final result6 = await fallbackService.processImageWithAI(
      imageBytes: testImageData,
      editingPrompt: 'remove marked objects',
    );
    log('✅ Fallback processImageWithAI: ${result6.length} bytes returned');
    
    log('🎉 All fallback tests passed!');
    
  } catch (e, stackTrace) {
    log('❌ Fallback test failed: $e');
    log('Stack trace: $stackTrace');
  }
  
  // Test service factory
  try {
    log('🧪 Testing AI Service Factory...');
    final serviceSelector = AIServiceFactory.getAIService();
    
    final status = AIServiceFactory.getServiceStatus();
    log('📊 Service status: $status');
    
    // Test with service selector
    final result = await serviceSelector.processImagePrompt(
      testImageData,
      'enhance this image'
    );
    log('✅ Service selector result: ${result.substring(0, 50)}...');
    
    log('🎉 Service factory tests passed!');
    
  } catch (e, stackTrace) {
    log('❌ Service factory test failed: $e');
    log('Stack trace: $stackTrace');
  }
}

import 'dart:typed_data';

import 'package:revision/core/services/gemini_request_builder.dart';
import 'package:revision/core/services/firebase_ai_remote_config_service.dart';

void main() async {
  print('🧪 Testing segmentation request building...');

  // Create a mock remote config using the actual constructor
  final remoteConfig = FirebaseAIRemoteConfigService();
  await remoteConfig.initialize(); // Initialize with defaults

  // Create request builder
  final requestBuilder = GeminiRequestBuilder(remoteConfig);

  // Create test image data
  final testImageBytes = Uint8List.fromList(List.filled(1024, 255));

  // Test segmentation prompt building
  final segmentationPrompt = GeminiRequestBuilder.buildSegmentationPrompt(
    targetObjects: 'people, cars',
  );

  print('📝 Segmentation prompt:');
  print(segmentationPrompt);
  print('');

  // Test request building
  final request = requestBuilder.buildSegmentationRequest(
    prompt: segmentationPrompt,
    imageBytes: testImageBytes,
  );

  print('🔧 Request structure:');
  print('Keys: ${request.keys.toList()}');

  if (request['contents'] != null) {
    final contents = request['contents'] as List;
    if (contents.isNotEmpty) {
      final firstContent = contents[0] as Map<String, dynamic>;
      print('Content keys: ${firstContent.keys.toList()}');

      if (firstContent['parts'] != null) {
        final parts = firstContent['parts'] as List;
        print('Parts count: ${parts.length}');

        for (int i = 0; i < parts.length; i++) {
          final part = parts[i] as Map<String, dynamic>;
          print('Part $i keys: ${part.keys.toList()}');
        }
      }
    }
  }

  if (request['generationConfig'] != null) {
    final config = request['generationConfig'] as Map<String, dynamic>;
    print('Generation config: ${config.keys.toList()}');
  }

  print('✅ Segmentation request building test completed!');
}

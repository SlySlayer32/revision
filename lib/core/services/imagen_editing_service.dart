import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:revision/core/constants/firebase_ai_constants.dart';

/// Service for Imagen-based image editing using Vertex AI REST API
/// This implements real image editing capabilities using Google's Imagen models
class ImagenEditingService {
  static const String _baseUrl =
      'https://us-central1-aiplatform.googleapis.com';
  static const String _location = 'us-central1';

  final String _projectId;
  final String _accessToken;

  ImagenEditingService({
    required String projectId,
    required String accessToken,
  })  : _projectId = projectId,
        _accessToken = accessToken;

  /// Edit an image using mask-free editing with Imagen 3
  /// This uses the latest Imagen 3 capability model for real image editing
  Future<Uint8List> editImageMaskFree({
    required Uint8List imageBytes,
    required String editingPrompt,
    String? negativePrompt,
    int sampleCount = 1,
  }) async {
    try {
      log('🔄 ImagenEditingService: Starting mask-free image editing');
      log('🔄 Image size: ${imageBytes.length} bytes');
      log('🔄 Prompt: $editingPrompt');

      // Convert image to base64
      final base64Image = base64Encode(imageBytes);

      // Prepare the request body for mask-free editing
      final requestBody = {
        'instances': [
          {
            'prompt': editingPrompt,
            'image': {
              'bytesBase64Encoded': base64Image,
            },
          }
        ],
        'parameters': {
          'sampleCount': sampleCount,
          'mode': 'edit', // Enable editing mode
          if (negativePrompt != null) 'negativePrompt': negativePrompt,
          'safetySetting': 'block_medium_and_above',
          'personGeneration': 'allow_adult',
        }
      };

      // Make the API call
      final url = '$_baseUrl/v1/projects/$_projectId/locations/$_location/'
          'publishers/google/models/${FirebaseAIConstants.imagenEditModel}:predict';

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $_accessToken',
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final predictions = responseData['predictions'] as List;

        if (predictions.isNotEmpty) {
          final firstPrediction = predictions[0] as Map<String, dynamic>;
          final editedImageBase64 =
              firstPrediction['bytesBase64Encoded'] as String;
          final editedImageBytes = base64Decode(editedImageBase64);

          log('✅ ImagenEditingService: Image editing completed successfully');
          log('✅ Result size: ${editedImageBytes.length} bytes');

          return editedImageBytes;
        } else {
          throw Exception('No predictions returned from Imagen API');
        }
      } else {
        log('❌ ImagenEditingService: API error ${response.statusCode}: ${response.body}');
        throw Exception(
            'Imagen API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      log('❌ ImagenEditingService: Image editing failed: $e',
          stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Generate a new image with Imagen 3 (for comparison or creation)
  Future<Uint8List> generateImage({
    required String prompt,
    String? negativePrompt,
    int sampleCount = 1,
    String aspectRatio = '1:1',
  }) async {
    try {
      log('🔄 ImagenEditingService: Generating new image');
      log('🔄 Prompt: $prompt');

      final requestBody = {
        'instances': [
          {
            'prompt': prompt,
          }
        ],
        'parameters': {
          'sampleCount': sampleCount,
          if (negativePrompt != null) 'negativePrompt': negativePrompt,
          'aspectRatio': aspectRatio,
          'safetySetting': 'block_medium_and_above',
          'personGeneration': 'allow_adult',
          'enhancePrompt': true, // Use prompt enhancement
        }
      };

      final url = '$_baseUrl/v1/projects/$_projectId/locations/$_location/'
          'publishers/google/models/${FirebaseAIConstants.imagenGenerateModel}:predict';

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $_accessToken',
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final predictions = responseData['predictions'] as List;

        if (predictions.isNotEmpty) {
          final firstPrediction = predictions[0] as Map<String, dynamic>;
          final imageBase64 = firstPrediction['bytesBase64Encoded'] as String;
          final imageBytes = base64Decode(imageBase64);

          log('✅ ImagenEditingService: Image generation completed successfully');
          return imageBytes;
        } else {
          throw Exception('No predictions returned from Imagen API');
        }
      } else {
        log('❌ ImagenEditingService: API error ${response.statusCode}: ${response.body}');
        throw Exception(
            'Imagen API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      log('❌ ImagenEditingService: Image generation failed: $e',
          stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Upscale an image using Imagen
  Future<Uint8List> upscaleImage({
    required Uint8List imageBytes,
    String upscaleFactor = 'x2', // 'x2' or 'x4'
  }) async {
    try {
      log('🔄 ImagenEditingService: Upscaling image');

      final base64Image = base64Encode(imageBytes);

      final requestBody = {
        'instances': [
          {
            'prompt': '', // Empty prompt for upscaling
            'image': {
              'bytesBase64Encoded': base64Image,
            },
          }
        ],
        'parameters': {
          'sampleCount': 1,
          'mode': 'upscale',
          'upscaleConfig': {
            'upscaleFactor': upscaleFactor,
          }
        }
      };

      final url = '$_baseUrl/v1/projects/$_projectId/locations/$_location/'
          'publishers/google/models/${FirebaseAIConstants.imagenModel}:predict';

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $_accessToken',
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final predictions = responseData['predictions'] as List;

        if (predictions.isNotEmpty) {
          final firstPrediction = predictions[0] as Map<String, dynamic>;
          final upscaledImageBase64 =
              firstPrediction['bytesBase64Encoded'] as String;
          final upscaledImageBytes = base64Decode(upscaledImageBase64);

          log('✅ ImagenEditingService: Image upscaling completed successfully');
          return upscaledImageBytes;
        } else {
          throw Exception('No predictions returned from Imagen API');
        }
      } else {
        log('❌ ImagenEditingService: API error ${response.statusCode}: ${response.body}');
        throw Exception(
            'Imagen API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      log('❌ ImagenEditingService: Image upscaling failed: $e',
          stackTrace: stackTrace);
      rethrow;
    }
  }
}

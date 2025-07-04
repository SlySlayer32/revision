import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:revision/core/config/env_config.dart';

void main() {
  testWidgets('Gemini API connectivity test', (WidgetTester tester) async {
    // Load environment variables
    await dotenv.load(fileName: ".env.development");

    log('🧪 Testing Gemini API connectivity...');

    final apiKey = EnvConfig.geminiApiKey;

    expect(apiKey, isNotNull, reason: 'API key should not be null');
    expect(apiKey, isNotEmpty, reason: 'API key should not be empty');

    log('✅ API key found (length: ${apiKey!.length})');

    // Test basic text request first
    await testBasicTextRequest(apiKey);

    // If basic text works, test multimodal
    await testSimpleImageRequest(apiKey);
  });
}

Future<void> testBasicTextRequest(String apiKey) async {
  log('🔍 Testing basic text request...');

  const url =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  final requestBody = {
    'contents': [
      {
        'parts': [
          {'text': 'Hello, respond with a simple greeting.'}
        ]
      }
    ],
    'generationConfig': {
      'temperature': 0.1,
      'maxOutputTokens': 100,
    }
  };

  try {
    final response = await http.post(
      Uri.parse('$url?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    log('📥 Text request status: ${response.statusCode}');
    log('📄 Text response length: ${response.body.length}');

    expect(response.statusCode, 200, reason: 'Text request should be successful');

    final data = jsonDecode(response.body);
    log('✅ Basic text request successful');
    log('📋 Response structure: ${data.keys.toList()}');

    expect(data.containsKey('candidates'), isTrue, reason: 'Response should contain candidates');
  } catch (e) {
    fail('Text request failed with error: $e');
  }
}

Future<void> testSimpleImageRequest(String apiKey) async {
  log('🔍 Testing simple image request (with dummy image)...');

  // Create a simple 1x1 pixel image in base64 (for testing structure only)
  const dummyImageBase64 =
      '/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/2wBDAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/wAARCAAABAAECAAAABxJREFUGBn/2Q==';

  const url =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  final requestBody = {
    'contents': [
      {
        'parts': [
          {'text': 'Describe this image briefly.'},
          {
            'inline_data': {
              'mime_type': 'image/jpeg',
              'data': dummyImageBase64,
            }
          }
        ]
      }
    ],
    'generationConfig': {
      'temperature': 0.1,
      'maxOutputTokens': 100,
    }
  };

  try {
    final response = await http.post(
      Uri.parse('$url?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    log('📥 Image request status: ${response.statusCode}');
    log('📄 Image response length: ${response.body.length}');

    expect(response.statusCode, 200, reason: 'Image request should be successful');

    final data = jsonDecode(response.body);
    log('✅ Image request successful');
    log('📋 Response structure: ${data.keys.toList()}');
  } catch (e) {
    fail('Image request failed with error: $e');
  }
}

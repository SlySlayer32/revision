import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:revision/core/config/env_config.dart';

/// Simple test to verify Gemini API connectivity and basic functionality
void main() async {
  log('🧪 Testing Gemini API connectivity...');
  
  final apiKey = EnvConfig.geminiApiKey;
  
  if (apiKey == null || apiKey.isEmpty) {
    log('❌ API key not found. Make sure to set GEMINI_API_KEY environment variable.');
    log('💡 Run with: dart run test_api_connectivity.dart --dart-define=GEMINI_API_KEY=your_key');
    exit(1);
  }
  
  log('✅ API key found (length: ${apiKey.length})');
  
  // Test basic text request first
  await testBasicTextRequest(apiKey);
  
  // If basic text works, test multimodal
  await testSimpleImageRequest(apiKey);
}

Future<void> testBasicTextRequest(String apiKey) async {
  log('🔍 Testing basic text request...');
  
  const url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';
  
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
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      log('✅ Basic text request successful');
      log('📋 Response structure: ${data.keys.toList()}');
      
      if (data.containsKey('candidates')) {
        final candidates = data['candidates'] as List;
        if (candidates.isNotEmpty) {
          final candidate = candidates.first;
          log('👤 Candidate keys: ${candidate.keys.toList()}');
          
          if (candidate.containsKey('content')) {
            final content = candidate['content'];
            log('📄 Content keys: ${content.keys.toList()}');
          }
        }
      }
    } else {
      log('❌ Text request failed: ${response.statusCode}');
      log('📄 Error response: ${response.body}');
    }
  } catch (e) {
    log('❌ Text request error: $e');
  }
}

Future<void> testSimpleImageRequest(String apiKey) async {
  log('🔍 Testing simple image request (with dummy image)...');
  
  // Create a simple 1x1 pixel image in base64 (for testing structure only)
  const dummyImageBase64 = '/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/2wBDAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/wAARCAAABAAECAAAABxJREFUGBn/2Q==';
  
  const url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';
  
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
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      log('✅ Image request successful');
      log('📋 Response structure: ${data.keys.toList()}');
    } else {
      log('❌ Image request failed: ${response.statusCode}');
      log('📄 Error response: ${response.body}');
    }
  } catch (e) {
    log('❌ Image request error: $e');
  }
}

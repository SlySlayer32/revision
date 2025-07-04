import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:revision/core/constants/gemini_constants.dart';

/// Handles API responses from Gemini
class GeminiResponseHandler {
  /// Handles HTTP response and extracts text content
  static String handleTextResponse(http.Response response) {
    try {
      _validateResponseStatus(response);
      
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return _extractTextContent(data);
    } catch (e, stackTrace) {
      log('❌ Error handling API response: $e');
      log('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Handles HTTP response and extracts image data
  static Uint8List? handleImageResponse(http.Response response) {
    try {
      _validateResponseStatus(response);
      
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return _extractImageData(data);
    } catch (e, stackTrace) {
      log('❌ Error handling image response: $e');
      log('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Validates HTTP response status code
  static void _validateResponseStatus(http.Response response) {
    switch (response.statusCode) {
      case GeminiConstants.httpOk:
        return; // Success
      
      case GeminiConstants.httpBadRequest:
        final errorBody = response.body;
        log('❌ Gemini API 400 error details: $errorBody');
        
        // Try to parse specific error details
        try {
          final errorData = jsonDecode(errorBody) as Map<String, dynamic>;
          if (errorData[GeminiConstants.errorKey] != null) {
            final error = errorData[GeminiConstants.errorKey] as Map<String, dynamic>;
            final errorMessage = error[GeminiConstants.messageKey] ?? 'Bad request';
            final errorCode = error[GeminiConstants.codeKey] ?? 400;
            throw Exception('Gemini API error ($errorCode): $errorMessage');
          }
        } catch (parseError) {
          log('⚠️ Could not parse error response: $parseError');
        }
        
        throw Exception('Gemini API bad request (400): Check your request format and API key');
      
      case GeminiConstants.httpUnauthorized:
        throw Exception('Gemini API unauthorized (401): Invalid API key');
      
      case GeminiConstants.httpForbidden:
        throw Exception('Gemini API forbidden (403): API key may be restricted or quota exceeded');
      
      case GeminiConstants.httpTooManyRequests:
        throw Exception('Gemini API rate limited (429): Too many requests');
      
      default:
        log('❌ Gemini API error: ${response.statusCode}');
        log('📝 Response: ${response.body}');
        throw Exception('Gemini API error: ${response.statusCode} - ${response.body}');
    }
  }

  /// Extracts text content from API response data
  static String _extractTextContent(Map<String, dynamic> data) {
    if (data[GeminiConstants.candidatesKey] == null || 
        (data[GeminiConstants.candidatesKey] as List).isEmpty) {
      throw Exception('No candidates in Gemini API response');
    }

    final candidates = data[GeminiConstants.candidatesKey] as List;
    final candidate = candidates[0] as Map<String, dynamic>;
    
    // Check for content filtering
    if (candidate[GeminiConstants.finishReasonKey] == GeminiConstants.safetyFinishReason) {
      throw Exception('Content was filtered by Gemini safety filters');
    }
    
    if (candidate[GeminiConstants.contentKey] == null ||
        candidate[GeminiConstants.contentKey][GeminiConstants.partsKey] == null) {
      throw Exception('No content parts in Gemini API response');
    }

    final content = candidate[GeminiConstants.contentKey] as Map<String, dynamic>;
    final parts = content[GeminiConstants.partsKey] as List;
    
    final textParts = parts
        .where((part) => (part as Map<String, dynamic>)[GeminiConstants.textKey] != null)
        .map((part) => (part as Map<String, dynamic>)[GeminiConstants.textKey] as String)
        .where((text) => text.trim().isNotEmpty);

    if (textParts.isEmpty) {
      throw Exception('No valid text content in Gemini API response');
    }

    return textParts.first.trim();
  }

  /// Extracts image data from API response
  static Uint8List? _extractImageData(Map<String, dynamic> data) {
    if (data[GeminiConstants.candidatesKey] == null || 
        (data[GeminiConstants.candidatesKey] as List).isEmpty) {
      log('⚠️ No candidates in image generation response');
      return null;
    }

    final candidates = data[GeminiConstants.candidatesKey] as List;
    final candidate = candidates[0] as Map<String, dynamic>;
    
    if (candidate[GeminiConstants.contentKey] == null || 
        candidate[GeminiConstants.contentKey][GeminiConstants.partsKey] == null) {
      log('⚠️ No content parts in image generation response');
      return null;
    }

    final content = candidate[GeminiConstants.contentKey] as Map<String, dynamic>;
    final parts = content[GeminiConstants.partsKey] as List;

    for (final part in parts) {
      final partMap = part as Map<String, dynamic>;
      
      if (partMap[GeminiConstants.inlineDataKey] != null) {
        final inlineData = partMap[GeminiConstants.inlineDataKey] as Map<String, dynamic>;
        
        if (inlineData[GeminiConstants.mimeTypeKey] != null &&
            inlineData[GeminiConstants.mimeTypeKey].toString().startsWith('image/') &&
            inlineData[GeminiConstants.dataKey] != null) {
          
          final base64Data = inlineData[GeminiConstants.dataKey] as String;
          final imageBytes = base64Decode(base64Data);
          log('🖼️ Successfully extracted generated image (${imageBytes.length} bytes)');
          return Uint8List.fromList(imageBytes);
        }
      }
    }

    log('⚠️ No image data found in generation response');
    return null;
  }

  /// Extract image data from API response
  static Uint8List? extractImageFromResponse(Map<String, dynamic> data) {
    if (data[GeminiConstants.candidatesKey] == null || 
        (data[GeminiConstants.candidatesKey] as List).isEmpty) {
      log('⚠️ No candidates in image generation response');
      return null;
    }

    final candidate = (data[GeminiConstants.candidatesKey] as List)[0] as Map<String, dynamic>;
    if (candidate[GeminiConstants.contentKey] == null || 
        candidate[GeminiConstants.contentKey][GeminiConstants.partsKey] == null) {
      log('⚠️ No content parts in image generation response');
      return null;
    }

    final parts = candidate[GeminiConstants.contentKey][GeminiConstants.partsKey] as List;

    for (final part in parts) {
      if (part[GeminiConstants.inlineDataKey] != null &&
          part[GeminiConstants.inlineDataKey][GeminiConstants.mimeTypeKey] != null &&
          part[GeminiConstants.inlineDataKey][GeminiConstants.mimeTypeKey]
              .toString()
              .startsWith('image/') &&
          part[GeminiConstants.inlineDataKey][GeminiConstants.dataKey] != null) {
        final base64Data = part[GeminiConstants.inlineDataKey][GeminiConstants.dataKey] as String;
        final imageBytes = base64Decode(base64Data);
        log('🖼️ Successfully extracted generated image (${imageBytes.length} bytes)');
        return Uint8List.fromList(imageBytes);
      }
    }

    log('⚠️ No image data found in generation response');
    return null;
  }

  /// Parses segmentation response from Gemini API
  static Map<String, dynamic> parseSegmentationResponse(String response) {
    try {
      // Clean up the response to extract JSON
      String cleanedResponse = response.trim();

      // Remove markdown code blocks if present
      if (cleanedResponse.startsWith('```json')) {
        final lines = cleanedResponse.split('\n');
        final startIndex = lines.indexWhere((line) => line.trim() == '```json') + 1;
        final endIndex = lines.lastIndexWhere((line) => line.trim() == '```');
        
        if (startIndex > 0 && endIndex > startIndex) {
          cleanedResponse = lines.sublist(startIndex, endIndex).join('\n');
        }
      }

      // Try to parse as JSON
      final jsonData = jsonDecode(cleanedResponse);

      if (jsonData is List) {
        // If it's a list of masks, wrap it in a container
        return {'masks': jsonData};
      } else if (jsonData is Map<String, dynamic>) {
        return jsonData;
      } else {
        log('⚠️ Unexpected JSON structure in segmentation response');
        return {'masks': []};
      }
    } catch (e) {
      log('❌ Failed to parse segmentation response: $e');
      log('📝 Raw response: $response');
      
      // Return empty structure on parse error
      return {'masks': []};
    }
  }

  /// Parses suggestions from text response
  static List<String> parseSuggestions(String response, {int maxSuggestions = 5}) {
    final suggestions = response
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) => line.replaceAll(RegExp(r'^\d+\.?\s*'), '').trim())
        .where((suggestion) => suggestion.isNotEmpty)
        .take(maxSuggestions)
        .toList();

    return suggestions.isNotEmpty ? suggestions : GeminiConstants.fallbackEditSuggestions;
  }

  /// Checks if response indicates content safety
  static bool parseContentSafety(String response) {
    final responseUpper = response.toUpperCase();
    return responseUpper.contains('SAFE') && !responseUpper.contains('UNSAFE');
  }

  /// Parses marker descriptions for editing prompts
  static String parseMarkerDescriptions(List<Map<String, dynamic>> markers) {
    return markers
        .map((marker) =>
            'Marker at (${marker['x']}, ${marker['y']}): ${marker['description'] ?? 'Object to edit'}')
        .join('\n');
  }

  /// Parse object detection response from Gemini API
  static List<Map<String, dynamic>> parseObjectDetectionResponse(String response) {
    try {
      // Clean up the response to extract JSON
      String cleanedResponse = response.trim();

      // Remove markdown code blocks if present
      if (cleanedResponse.startsWith('```json')) {
        final lines = cleanedResponse.split('\n');
        final startIndex =
            lines.indexWhere((line) => line.trim() == '```json') + 1;
        final endIndex = lines.lastIndexWhere((line) => line.trim() == '```');
        if (startIndex > 0 && endIndex > startIndex) {
          cleanedResponse = lines.sublist(startIndex, endIndex).join('\n');
        }
      }

      // Try to parse as JSON
      final jsonData = jsonDecode(cleanedResponse);

      if (jsonData is List) {
        return List<Map<String, dynamic>>.from(jsonData);
      } else if (jsonData is Map<String, dynamic> &&
          jsonData.containsKey('objects')) {
        return List<Map<String, dynamic>>.from(jsonData['objects']);
      } else {
        throw const FormatException(
            'Unexpected JSON structure for object detection');
      }
    } catch (e) {
      log('❌ Failed to parse object detection response: $e');
      log('📝 Raw response: $response');

      // Return empty list on parse error
      return [];
    }
  }
}

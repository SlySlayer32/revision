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
            final error =
                errorData[GeminiConstants.errorKey] as Map<String, dynamic>;
            final errorMessage =
                error[GeminiConstants.messageKey] ?? 'Bad request';
            final errorCode = error[GeminiConstants.codeKey] ?? 400;
            throw Exception('Gemini API error ($errorCode): $errorMessage');
          }
        } catch (parseError) {
          log('⚠️ Could not parse error response: $parseError');
        }

        throw Exception(
            'Gemini API bad request (400): Check your request format and API key');

      case GeminiConstants.httpUnauthorized:
        throw Exception('Gemini API unauthorized (401): Invalid API key');

      case GeminiConstants.httpForbidden:
        throw Exception(
            'Gemini API forbidden (403): API key may be restricted or quota exceeded');

      case GeminiConstants.httpTooManyRequests:
        throw Exception('Gemini API rate limited (429): Too many requests');

      default:
        log('❌ Gemini API error: ${response.statusCode}');
        log('📝 Response: ${response.body}');
        throw Exception(
            'Gemini API error: ${response.statusCode} - ${response.body}');
    }
  }

  /// Extracts text content from API response data with enhanced error handling
  static String _extractTextContent(Map<String, dynamic> data) {
    // Debug logging
    log('🔍 Extracting text content from response...');
    log('📋 Response keys: ${data.keys.toList()}');

    // Check for candidates
    if (data[GeminiConstants.candidatesKey] == null ||
        (data[GeminiConstants.candidatesKey] as List).isEmpty) {
      log('❌ No candidates found in response');
      log('📝 Full response structure: ${data.toString()}');
      throw Exception('No candidates in Gemini API response');
    }

    final candidates = data[GeminiConstants.candidatesKey] as List;
    final candidate = candidates[0] as Map<String, dynamic>;

    log('👤 Candidate keys: ${candidate.keys.toList()}');
    log('🏁 Finish reason: ${candidate[GeminiConstants.finishReasonKey]}');

    // Check for content filtering
    if (candidate[GeminiConstants.finishReasonKey] ==
        GeminiConstants.safetyFinishReason) {
      throw Exception('Content was filtered by Gemini safety filters');
    }

    // Enhanced debugging for content structure
    if (candidate[GeminiConstants.contentKey] == null) {
      log('❌ No content key found in candidate');
      log('📝 Candidate structure: ${candidate.toString()}');
      throw Exception('No content in Gemini API response candidate');
    }

    final content =
        candidate[GeminiConstants.contentKey] as Map<String, dynamic>;
    log('📄 Content keys: ${content.keys.toList()}');

    // Check for parts in content
    if (content[GeminiConstants.partsKey] == null) {
      log('❌ No parts key found in content');
      log('📝 Content structure: ${content.toString()}');

      // Try to handle cases where content might be structured differently
      if (content[GeminiConstants.textKey] != null) {
        log('🔄 Found text directly in content, extracting...');
        final directText = content[GeminiConstants.textKey] as String;
        return directText.trim();
      }

      // Special handling for responses that only contain "role" field
      if (content.keys.length == 1 && content.containsKey('role')) {
        log('⚠️ Response contains only role field - likely an error response');
        log('📋 Full response data for debugging: ${data.toString()}');
        
        // Check if there's an error field in the main response
        if (data.containsKey('error')) {
          final error = data['error'];
          throw Exception('Gemini API error: ${error.toString()}');
        }
        
        // This might be an authentication or quota issue
        throw Exception('Invalid Gemini API response - only role field present. '
            'This typically indicates an authentication issue, quota exceeded, '
            'or malformed request. Check your API key and request format.');
      }

      // If still no parts, this is likely an API structure change
      throw Exception('No content parts in Gemini API response. '
          'Content structure: ${content.keys.toList()}. '
          'This may indicate an API version change or malformed response.');
    }

    final parts = content[GeminiConstants.partsKey] as List;
    log('🧩 Found ${parts.length} parts in response');

    // If parts array is empty, provide more context
    if (parts.isEmpty) {
      log('❌ Parts array is empty');
      log('📝 Full response: ${data.toString()}');
      throw Exception('Content parts array is empty in Gemini API response. '
          'This may indicate content filtering or API issues.');
    }

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i] as Map<String, dynamic>;
      log('🧩 Part $i keys: ${part.keys.toList()}');
    }

    final textParts = parts
        .where((part) =>
            (part as Map<String, dynamic>)[GeminiConstants.textKey] != null)
        .map((part) =>
            (part as Map<String, dynamic>)[GeminiConstants.textKey] as String)
        .where((text) => text.trim().isNotEmpty);

    if (textParts.isEmpty) {
      log('❌ No text parts found after filtering');
      log('📝 Available part types: ${parts.map((p) => (p as Map<String, dynamic>).keys.toList()).toList()}');

      // Try to extract alternative content types
      for (final part in parts) {
        final partMap = part as Map<String, dynamic>;
        if (partMap.containsKey('functionCall') ||
            partMap.containsKey('functionResponse') ||
            partMap.containsKey('executableCode')) {
          log('⚠️ Response contains non-text content types that are not yet supported');
          throw Exception(
              'Response contains non-text content (function calls, code execution, etc.) '
              'that cannot be processed as text. Available keys: ${partMap.keys.toList()}');
        }
      }

      throw Exception('No valid text content in Gemini API response. '
          'Found ${parts.length} parts but none contained text. '
          'Part types: ${parts.map((p) => (p as Map<String, dynamic>).keys.toList()).toList()}');
    }

    final result = textParts.first.trim();
    log('✅ Extracted text content (${result.length} chars)');
    return result;
  }

  /// Extracts image data from API response with enhanced error handling
  static Uint8List? _extractImageData(Map<String, dynamic> data) {
    log('🔍 Extracting image data from response...');

    if (data[GeminiConstants.candidatesKey] == null ||
        (data[GeminiConstants.candidatesKey] as List).isEmpty) {
      log('⚠️ No candidates in image generation response');
      return null;
    }

    final candidates = data[GeminiConstants.candidatesKey] as List;
    final candidate = candidates[0] as Map<String, dynamic>;

    log('👤 Image candidate keys: ${candidate.keys.toList()}');
    log('🏁 Image finish reason: ${candidate[GeminiConstants.finishReasonKey]}');

    // Check for content filtering or safety issues
    if (candidate[GeminiConstants.finishReasonKey] ==
        GeminiConstants.safetyFinishReason) {
      log('⚠️ Image generation was filtered by safety filters');
      return null;
    }

    if (candidate[GeminiConstants.contentKey] == null ||
        candidate[GeminiConstants.contentKey][GeminiConstants.partsKey] ==
            null) {
      log('⚠️ No content parts in image generation response');
      log('📝 Candidate structure: ${candidate.toString()}');
      return null;
    }

    final content =
        candidate[GeminiConstants.contentKey] as Map<String, dynamic>;
    final parts = content[GeminiConstants.partsKey] as List;

    log('🧩 Found ${parts.length} parts in image response');

    if (parts.isEmpty) {
      log('⚠️ Parts array is empty in image response');
      return null;
    }

    for (int i = 0; i < parts.length; i++) {
      final partMap = parts[i] as Map<String, dynamic>;
      log('🧩 Image part $i keys: ${partMap.keys.toList()}');

      if (partMap[GeminiConstants.inlineDataKey] != null) {
        final inlineData =
            partMap[GeminiConstants.inlineDataKey] as Map<String, dynamic>;

        log('📎 Inline data keys: ${inlineData.keys.toList()}');

        if (inlineData[GeminiConstants.mimeTypeKey] != null &&
            inlineData[GeminiConstants.mimeTypeKey]
                .toString()
                .startsWith('image/') &&
            inlineData[GeminiConstants.dataKey] != null) {
          try {
            final base64Data = inlineData[GeminiConstants.dataKey] as String;
            final imageBytes = base64Decode(base64Data);
            log('🖼️ Successfully extracted generated image (${imageBytes.length} bytes)');
            log('🎨 MIME type: ${inlineData[GeminiConstants.mimeTypeKey]}');
            return Uint8List.fromList(imageBytes);
          } catch (e) {
            log('❌ Failed to decode base64 image data: $e');
            return null;
          }
        } else {
          log('⚠️ Inline data missing required fields:');
          log('  - MIME type: ${inlineData[GeminiConstants.mimeTypeKey]}');
          log('  - Has data: ${inlineData[GeminiConstants.dataKey] != null}');
        }
      }
    }

    log('⚠️ No image data found in generation response after checking all parts');
    return null;
  }

  /// Extract image data from API response
  static Uint8List? extractImageFromResponse(Map<String, dynamic> data) {
    if (data[GeminiConstants.candidatesKey] == null ||
        (data[GeminiConstants.candidatesKey] as List).isEmpty) {
      log('⚠️ No candidates in image generation response');
      return null;
    }

    final candidate = (data[GeminiConstants.candidatesKey] as List)[0]
        as Map<String, dynamic>;
    if (candidate[GeminiConstants.contentKey] == null ||
        candidate[GeminiConstants.contentKey][GeminiConstants.partsKey] ==
            null) {
      log('⚠️ No content parts in image generation response');
      return null;
    }

    final parts =
        candidate[GeminiConstants.contentKey][GeminiConstants.partsKey] as List;

    for (final part in parts) {
      if (part[GeminiConstants.inlineDataKey] != null &&
          part[GeminiConstants.inlineDataKey][GeminiConstants.mimeTypeKey] !=
              null &&
          part[GeminiConstants.inlineDataKey][GeminiConstants.mimeTypeKey]
              .toString()
              .startsWith('image/') &&
          part[GeminiConstants.inlineDataKey][GeminiConstants.dataKey] !=
              null) {
        final base64Data = part[GeminiConstants.inlineDataKey]
            [GeminiConstants.dataKey] as String;
        final imageBytes = base64Decode(base64Data);
        log('🖼️ Successfully extracted generated image (${imageBytes.length} bytes)');
        return Uint8List.fromList(imageBytes);
      }
    }

    log('⚠️ No image data found in generation response');
    return null;
  }

  /// Parses segmentation response from Gemini API with enhanced error handling
  static Map<String, dynamic> parseSegmentationResponse(String response) {
    try {
      // Clean up the response to extract JSON
      String cleanedResponse = response.trim();

      log('🔍 Parsing segmentation response (${cleanedResponse.length} chars)');

      // Remove markdown code blocks if present
      if (cleanedResponse.startsWith('```json')) {
        final lines = cleanedResponse.split('\n');
        final startIndex =
            lines.indexWhere((line) => line.trim() == '```json') + 1;
        final endIndex = lines.lastIndexWhere((line) => line.trim() == '```');

        if (startIndex > 0 && endIndex > startIndex) {
          cleanedResponse = lines.sublist(startIndex, endIndex).join('\n');
          log('📝 Extracted JSON from markdown block');
        }
      }

      // Additional cleanup for common response patterns
      cleanedResponse = cleanedResponse
          .replaceAll(
              RegExp(r'^```[a-z]*\n?'), '') // Remove opening code blocks
          .replaceAll(RegExp(r'\n?```$'), '') // Remove closing code blocks
          .trim();

      if (cleanedResponse.isEmpty) {
        log('⚠️ Empty response after cleanup');
        return {'masks': [], 'error': 'Empty response from API'};
      }

      // Try to parse as JSON
      final jsonData = jsonDecode(cleanedResponse);

      if (jsonData is List) {
        // If it's a list of masks, wrap it in a container
        log('✅ Parsed segmentation response as list (${jsonData.length} items)');
        return {'masks': jsonData};
      } else if (jsonData is Map<String, dynamic>) {
        log('✅ Parsed segmentation response as map');
        // Ensure masks key exists
        if (!jsonData.containsKey('masks')) {
          jsonData['masks'] = [];
        }
        return jsonData;
      } else {
        log('⚠️ Unexpected JSON structure in segmentation response');
        return {
          'masks': [],
          'error': 'Unexpected response format: ${jsonData.runtimeType}'
        };
      }
    } catch (e) {
      log('❌ Failed to parse segmentation response: $e');
      log('📝 Raw response (first 500 chars): ${response.length > 500 ? response.substring(0, 500) + "..." : response}');

      // Try to extract any JSON-like content as fallback
      try {
        final jsonMatch = RegExp(r'\[.*?\]').firstMatch(response);
        if (jsonMatch != null) {
          final jsonStr = jsonMatch.group(0)!;
          final fallbackData = jsonDecode(jsonStr);
          log('🔄 Fallback parsing successful');
          return {'masks': fallbackData is List ? fallbackData : []};
        }
      } catch (fallbackError) {
        log('❌ Fallback parsing also failed: $fallbackError');
      }

      // Return empty structure with error details for production debugging
      return {
        'masks': [],
        'error': 'Parse error: ${e.toString()}',
        'originalResponse': response.length > 1000
            ? response.substring(0, 1000) + '...[truncated]'
            : response,
        'errorType': 'json_parse_error'
      };
    }
  }

  /// Parses suggestions from text response
  static List<String> parseSuggestions(String response,
      {int maxSuggestions = 5}) {
    final suggestions = response
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) => line.replaceAll(RegExp(r'^\d+\.?\s*'), '').trim())
        .where((suggestion) => suggestion.isNotEmpty)
        .take(maxSuggestions)
        .toList();

    return suggestions.isNotEmpty
        ? suggestions
        : GeminiConstants.fallbackEditSuggestions;
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
  static List<Map<String, dynamic>> parseObjectDetectionResponse(
      String response) {
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

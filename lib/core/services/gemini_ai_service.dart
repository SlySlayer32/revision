import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:revision/core/config/env_config.dart';
import 'package:revision/core/constants/firebase_ai_constants.dart';
import 'package:revision/core/constants/gemini_constants.dart';
import 'package:revision/core/services/ai_error_handler.dart';
import 'package:revision/core/services/ai_service.dart';
import 'package:revision/core/services/firebase_ai_remote_config_service.dart';
import 'package:revision/core/services/gemini_request_validator.dart';
import 'package:revision/core/services/gemini_response_handler.dart';
import 'package:revision/core/services/gemini_request_builder.dart';
import 'package:revision/features/ai_processing/domain/entities/segmentation_result.dart';

/// Gemini REST API service implementation
/// Uses direct Gemini REST API for all operations since Firebase AI Logic doesn't support image input
///
/// Configuration:
/// - Requires GEMINI_API_KEY in .env file
/// - Model parameters controlled via Firebase Remote Config
/// - Uses Gemini Developer API (not Vertex AI)
/// - Supports both text-only and multimodal (text + image) operations
class GeminiAIService implements AIService {
  GeminiAIService({
    FirebaseAIRemoteConfigService? remoteConfigService,
    http.Client? httpClient,
    GeminiRequestValidator? requestValidator,
    GeminiResponseHandler? responseHandler,
    GeminiRequestBuilder? requestBuilder,
  })  : _remoteConfig = remoteConfigService ?? FirebaseAIRemoteConfigService(),
        _httpClient = httpClient ?? http.Client(),
        _requestValidator = requestValidator ?? GeminiRequestValidator(),
        _responseHandler = responseHandler ?? GeminiResponseHandler(),
        _requestBuilder = requestBuilder ?? GeminiRequestBuilder() {
    log('🏗️ Creating GeminiAIService instance...');
    // Don't call _initializeService() in constructor to avoid blocking
    // Service locator registration. Call it later via waitForInitialization()
  }

  final FirebaseAIRemoteConfigService _remoteConfig;
  final http.Client _httpClient;
  final GeminiRequestValidator _requestValidator;
  final GeminiResponseHandler _responseHandler;
  final GeminiRequestBuilder _requestBuilder;
  final AIErrorHandler _errorHandler = AIErrorHandler();

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  bool _isInitialized = false;
  Completer<void>? _initializationCompleter;

  Future<void> _initializeService() async {
    if (_isInitialized) return;

    if (_initializationCompleter != null) {
      return _initializationCompleter!.future;
    }

    _initializationCompleter = Completer<void>();

    try {
      log('🚀 Initializing Gemini REST API service...');

      // Check API key
      final apiKey = EnvConfig.geminiApiKey;
      if (apiKey == null || apiKey.isEmpty) {
        log('❌ Gemini API key validation failed');
        log('🔧 Available debug info: ${EnvConfig.getDebugInfo()}');
        throw StateError(
            'Gemini API key not configured. Please add GEMINI_API_KEY to your .env file or pass it via --dart-define=GEMINI_API_KEY=your_key');
      }

      log('✅ Gemini API key found (length: ${apiKey.length})');

      // Initialize Remote Config for parameter management
      // Only initialize if it hasn't been initialized yet
      try {
        await _remoteConfig.initialize();
        log('✅ Remote Config initialized successfully');
      } catch (e) {
        log('⚠️ Remote Config initialization failed, continuing with defaults: $e');
        // Continue with defaults - the service should handle this gracefully
      }

      // Test API connectivity
      await _testApiConnectivity();

      _isInitialized = true;
      _initializationCompleter!.complete();
      log('✅ Gemini REST API service initialized successfully');
      log('📊 Using Remote Config values: ${_remoteConfig.exportConfig()}');
    } catch (e) {
      log('❌ Failed to initialize Gemini REST API service: $e');
      _initializationCompleter!.completeError(e);
      rethrow;
    }
  }

  /// Test API connectivity with a simple request
  Future<void> _testApiConnectivity() async {
    try {
      log('🧪 Testing Gemini API connectivity...');

      final response = await _makeTextOnlyRequest(
        prompt: 'Hello, are you working?',
        model: _remoteConfig.geminiModel,
      );

      if (response.isNotEmpty) {
        log('✅ Gemini API connectivity test successful');
      } else {
        log('⚠️ Gemini API test returned empty response');
      }
    } catch (e) {
      log('🚨 Gemini API connectivity test failed: $e');
      throw StateError('Failed to connect to Gemini API: $e');
    }
  }

  /// Wait for the service to be fully initialized
  Future<void> waitForInitialization() async {
    if (_isInitialized) return;

    if (_initializationCompleter != null) {
      return _initializationCompleter!.future;
    }

    // Start initialization if it hasn't been started yet
    return _initializeService();
  }

  /// Make a text-only request to Gemini API
  Future<String> _makeTextOnlyRequest({
    required String prompt,
    String? model,
  }) async {
    // Validate request parameters
    _validateApiRequest(prompt: prompt, model: model);
    
    final apiKey = EnvConfig.geminiApiKey!;
    final modelName = model ?? _remoteConfig.geminiModel;

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'temperature': _remoteConfig.temperature,
        'maxOutputTokens': _remoteConfig.maxOutputTokens,
        'topK': _remoteConfig.topK,
        'topP': _remoteConfig.topP,
      },
    };

    final response = await _httpClient
        .post(
          Uri.parse('$_baseUrl/$modelName:generateContent?key=$apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        )
        .timeout(_remoteConfig.requestTimeout);

    return _handleApiResponse(response);
  }

  /// Make a multimodal request to Gemini API
  Future<String> _makeMultimodalRequest({
    required String prompt,
    required Uint8List imageBytes,
    String? model,
  }) async {
    // Validate request parameters
    _validateApiRequest(prompt: prompt, imageBytes: imageBytes, model: model);
    
    final apiKey = EnvConfig.geminiApiKey!;
    final modelName = model ?? _remoteConfig.geminiModel;
    final base64Image = base64Encode(imageBytes);

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Image,
              },
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': _remoteConfig.temperature,
        'maxOutputTokens': _remoteConfig.maxOutputTokens,
        'topK': _remoteConfig.topK,
        'topP': _remoteConfig.topP,
      },
    };

    log('📡 Making multimodal Gemini API request...');
    log('🔧 Model: $modelName');
    log('📷 Image size: ${imageBytes.length} bytes');

    final response = await _httpClient
        .post(
          Uri.parse('$_baseUrl/$modelName:generateContent?key=$apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        )
        .timeout(_remoteConfig.requestTimeout);

    return _handleApiResponse(response);
  }

  /// Make an image generation request to Gemini API
  Future<Uint8List?> _makeImageGenerationRequest({
    required String prompt,
    Uint8List? inputImage,
  }) async {
    final apiKey = EnvConfig.geminiApiKey!;
    final modelName = _remoteConfig.geminiImageModel;

    final parts = <Map<String, dynamic>>[];
    parts.add({'text': prompt});

    if (inputImage != null) {
      final base64Image = base64Encode(inputImage);
      parts.add({
        'inline_data': {
          'mime_type': 'image/jpeg',
          'data': base64Image,
        },
      });
    }

    final requestBody = {
      'contents': [
        {
          'parts': parts,
        },
      ],
      'generationConfig': {
        'temperature':
            _remoteConfig.temperature * 0.75, // Lower for image generation
        'maxOutputTokens': _remoteConfig.maxOutputTokens * 2,
        'topK': 32,
        'topP': 0.9,
      },
    };

    log('🎨 Making image generation request...');
    log('📡 Model: $modelName');

    final response = await _httpClient
        .post(
          Uri.parse('$_baseUrl/$modelName:generateContent?key=$apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        )
        .timeout(_remoteConfig.requestTimeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return _extractImageFromResponse(data);
    } else {
      log('❌ Image generation API error: ${response.statusCode}');
      log('📝 Response: ${response.body}');
      throw Exception(
          'Gemini API error: ${response.statusCode} - ${response.body}');
    }
  }

  /// Validate API request before sending
  void _validateApiRequest({
    required String prompt,
    Uint8List? imageBytes,
    String? model,
  }) {
    if (prompt.trim().isEmpty) {
      throw ArgumentError('Prompt cannot be empty');
    }

    if (prompt.length > 20000) {
      throw ArgumentError('Prompt too long (max 20000 characters)');
    }

    if (imageBytes != null) {
      if (imageBytes.isEmpty) {
        throw ArgumentError('Image bytes cannot be empty');
      }

      // Check image size limit (20MB for Gemini)
      if (imageBytes.length > 20 * 1024 * 1024) {
        throw ArgumentError('Image too large (max 20MB)');
      }
    }

    final apiKey = EnvConfig.geminiApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw StateError('GEMINI_API_KEY not configured');
    }

    if (apiKey.length < 30) {
      throw ArgumentError('Invalid API key format');
    }
  }

  /// Handle API response and extract text
  String _handleApiResponse(http.Response response) {
    try {
      if (response.statusCode == 400) {
        final errorBody = response.body;
        log('❌ Gemini API 400 error details: $errorBody');
        
        // Parse specific 400 errors
        try {
          final errorData = jsonDecode(errorBody);
          if (errorData['error'] != null) {
            final errorMessage = errorData['error']['message'] ?? 'Bad request';
            final errorCode = errorData['error']['code'] ?? 400;
            throw Exception('Gemini API error ($errorCode): $errorMessage');
          }
        } catch (parseError) {
          log('⚠️ Could not parse error response: $parseError');
        }
        
        throw Exception('Gemini API bad request (400): Check your request format and API key');
      }
      
      if (response.statusCode == 401) {
        throw Exception('Gemini API unauthorized (401): Invalid API key');
      }
      
      if (response.statusCode == 403) {
        throw Exception('Gemini API forbidden (403): API key may be restricted or quota exceeded');
      }
      
      if (response.statusCode == 429) {
        throw Exception('Gemini API rate limited (429): Too many requests');
      }
      
      if (response.statusCode != 200) {
        log('❌ Gemini API error: ${response.statusCode}');
        log('📝 Response: ${response.body}');
        throw Exception('Gemini API error: ${response.statusCode} - ${response.body}');
      }

      final data = jsonDecode(response.body);

      if (data['candidates'] == null || data['candidates'].isEmpty) {
        throw Exception('No candidates in Gemini API response');
      }

      final candidate = data['candidates'][0];
      
      // Check for content filtering
      if (candidate['finishReason'] == 'SAFETY') {
        throw Exception('Content was filtered by Gemini safety filters');
      }
      
      if (candidate['content'] == null || candidate['content']['parts'] == null) {
        throw Exception('No content parts in Gemini API response');
      }

      final parts = candidate['content']['parts'] as List;
      final textParts = parts
          .where((part) => part['text'] != null)
          .map((part) => part['text'] as String)
          .where((text) => text.trim().isNotEmpty);

      if (textParts.isEmpty) {
        throw Exception('No valid text content in Gemini API response');
      }

      return textParts.first.trim();
    } catch (e, stackTrace) {
      log('❌ Error handling API response: $e');
      log('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Extract image data from API response
  Uint8List? _extractImageFromResponse(Map<String, dynamic> data) {
    if (data['candidates'] == null || data['candidates'].isEmpty) {
      log('⚠️ No candidates in image generation response');
      return null;
    }

    final candidate = data['candidates'][0];
    if (candidate['content'] == null || candidate['content']['parts'] == null) {
      log('⚠️ No content parts in image generation response');
      return null;
    }

    final parts = candidate['content']['parts'] as List;

    for (final part in parts) {
      if (part['inline_data'] != null &&
          part['inline_data']['mime_type'] != null &&
          part['inline_data']['mime_type'].toString().startsWith('image/') &&
          part['inline_data']['data'] != null) {
        final base64Data = part['inline_data']['data'] as String;
        final imageBytes = base64Decode(base64Data);
        log('🖼️ Successfully extracted generated image (${imageBytes.length} bytes)');
        return Uint8List.fromList(imageBytes);
      }
    }

    log('⚠️ No image data found in generation response');
    return null;
  }

  @override
  Future<String> processTextPrompt(String prompt) async {
    await waitForInitialization();

    return _errorHandler
        .executeWithRetry<String>(
      () => _makeTextOnlyRequest(prompt: prompt),
      'processTextPrompt',
    )
        .catchError((e) {
      log('❌ processTextPrompt failed after all retries: $e');
      return 'Sorry, I encountered an error processing your request. Please try again.';
    });
  }

  @override
  Future<String> processImagePrompt(Uint8List imageData, String prompt) async {
    await waitForInitialization();

    return _errorHandler.executeWithRetry<String>(
      () async {
        // Validate image size
        if (imageData.length >
            FirebaseAIConstants.maxImageSizeMB * 1024 * 1024) {
          throw Exception(
            'Image too large: ${imageData.length ~/ (1024 * 1024)}MB',
          );
        }

        final fullPrompt = '''
Analyze this image and provide editing instructions based on: $prompt

Focus on:
1. Object identification and removal suggestions
2. Background reconstruction techniques
3. Lighting and shadow adjustments
4. Color harmony maintenance

Provide clear, actionable editing steps.
''';

        return _makeMultimodalRequest(
          prompt: fullPrompt,
          imageBytes: imageData,
        );
      },
      'processImagePrompt',
    ).catchError((e) {
      log('❌ processImagePrompt failed after all retries: $e');
      return '''
I apologize, but I'm currently unable to analyze this image due to a technical issue.

For object removal, I generally recommend:
1. Identify the object boundaries carefully
2. Consider the background pattern for reconstruction
3. Use content-aware tools for seamless blending
4. Adjust lighting and shadows to match surroundings

Please try again or contact support if the issue persists.
''';
    });
  }

  @override
  Future<String> generateImageDescription(Uint8List imageData) async {
    await waitForInitialization();

    return _errorHandler.executeWithRetry<String>(
      () async {
        const prompt = '''
Describe this image in detail for photo editing purposes.

Include:
1. Main subjects and objects
2. Lighting conditions
3. Colors and composition
4. Background elements
5. Overall mood and style

Keep the description clear and technical.
''';

        return _makeMultimodalRequest(
          prompt: prompt,
          imageBytes: imageData,
        );
      },
      'generateImageDescription',
    ).catchError((e) {
      log('❌ generateImageDescription failed after all retries: $e');
      return 'Unable to analyze image at this time.';
    });
  }

  @override
  Future<List<String>> suggestImageEdits(Uint8List imageData) async {
    await waitForInitialization();

    return _errorHandler.executeWithRetry<List<String>>(
      () async {
        const prompt = '''
Analyze this image and provide 5 specific editing suggestions to improve it.

Focus on:
1. Object removal opportunities
2. Lighting improvements
3. Composition enhancements
4. Color corrections
5. Background improvements

Provide each suggestion as a clear, actionable sentence.
''';

        final response = await _makeMultimodalRequest(
          prompt: prompt,
          imageBytes: imageData,
        );

        // Parse response into suggestions
        final suggestions = response
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .map((line) => line.replaceAll(RegExp(r'^\d+\.?\s*'), '').trim())
            .where((suggestion) => suggestion.isNotEmpty)
            .take(5)
            .toList();

        return suggestions.isNotEmpty ? suggestions : _getFallbackSuggestions();
      },
      'suggestImageEdits',
    ).catchError((e) {
      log('❌ suggestImageEdits failed after all retries: $e');
      return _getFallbackSuggestions();
    });
  }

  @override
  Future<bool> checkContentSafety(Uint8List imageData) async {
    await waitForInitialization();

    return _errorHandler.executeWithRetry<bool>(
      () async {
        const prompt = '''
Analyze this image for content safety. Is this image appropriate for a photo editing application?

Consider:
1. Does it contain inappropriate content?
2. Is it suitable for general audiences?
3. Does it violate content policies?

Respond with "SAFE" if appropriate, "UNSAFE" if not appropriate, followed by a brief reason.
''';

        final response = await _makeMultimodalRequest(
          prompt: prompt,
          imageBytes: imageData,
        );

        final responseUpper = response.toUpperCase();
        return responseUpper.contains('SAFE') &&
            !responseUpper.contains('UNSAFE');
      },
      'checkContentSafety',
    ).catchError((e) {
      log('❌ checkContentSafety failed after all retries: $e');
      return true; // Default to safe on error
    });
  }

  @override
  Future<String> generateEditingPrompt({
    required Uint8List imageBytes,
    required List<Map<String, dynamic>> markers,
  }) async {
    await waitForInitialization();

    return _errorHandler.executeWithRetry<String>(
      () async {
        final markerDescriptions = markers
            .map((marker) =>
                'Marker at (${marker['x']}, ${marker['y']}): ${marker['description'] ?? 'Object to edit'}')
            .join('\n');

        final prompt = '''
Generate a detailed editing prompt for this image based on the user's markers:

$markerDescriptions

Create a comprehensive editing instruction that includes:
1. What objects/areas to modify
2. How to handle the background
3. Lighting and shadow considerations
4. Color matching requirements
5. Specific techniques to use

Provide a clear, actionable editing prompt.
''';

        return _makeMultimodalRequest(
          prompt: prompt,
          imageBytes: imageBytes,
        );
      },
      'generateEditingPrompt',
    ).catchError((e) {
      log('❌ generateEditingPrompt failed after all retries: $e');
      return 'Remove marked objects and blend the background seamlessly.';
    });
  }

  @override
  Future<Uint8List> processImageWithAI({
    required Uint8List imageBytes,
    required String editingPrompt,
  }) async {
    await waitForInitialization();

    return _errorHandler.executeWithRetry<Uint8List>(
      () async {
        log('🤖 Processing image with AI using prompt: $editingPrompt');

        final prompt = '''
Generate a new image based on this editing request: $editingPrompt

Create a high-quality image that represents the desired result after the editing operation.
Focus on creating a clean, professional result that matches the editing intent.
''';

        final generatedImage = await _makeImageGenerationRequest(
          prompt: prompt,
          inputImage: imageBytes,
        );

        if (generatedImage != null) {
          log('✅ AI image generation completed successfully');
          return generatedImage;
        } else {
          log('⚠️ No image generated, returning original');
          return imageBytes;
        }
      },
      'processImageWithAI',
    ).catchError((e) {
      log('❌ processImageWithAI failed after all retries: $e');
      return imageBytes; // Return original image on error
    });
  }

  /// Refresh Remote Config and update parameters
  Future<void> refreshConfig() async {
    if (!_isInitialized) return;

    try {
      log('🔄 Refreshing Remote Config...');
      await _remoteConfig.refresh();
      log('✅ Remote Config refreshed successfully');
    } catch (e) {
      log('⚠️ Failed to refresh Remote Config: $e');
    }
  }

  /// Get current Remote Config values for debugging
  Map<String, dynamic> getConfigDebugInfo() {
    return {
      'initialized': _isInitialized,
      'apiKeyConfigured': EnvConfig.isGeminiRestApiConfigured,
      ...EnvConfig.getDebugInfo(),
      ..._remoteConfig.getAllValues(),
    };
  }

  /// Check if advanced features are enabled
  bool get isAdvancedFeaturesEnabled => _remoteConfig.enableAdvancedFeatures;

  List<String> _getFallbackSuggestions() {
    return [
      'Remove any unwanted objects or distractions from the image',
      'Adjust brightness and contrast for better visual impact',
      'Enhance colors to make them more vibrant and appealing',
      'Crop or straighten the image for better composition',
      'Apply subtle sharpening to improve image clarity',
    ];
  }

  /// Dispose of resources
  void dispose() {
    _httpClient.close();
  }

  /// Generate segmentation masks for objects in the image using Gemini 2.5
  ///
  /// Uses Gemini 2.5's enhanced segmentation capabilities to detect objects
  /// and provide their contour masks as base64 encoded PNG probability maps.
  ///
  /// For best results:
  /// - Set thinking budget to 0
  /// - Use specific prompts for target objects
  /// - Images should be resized to max 1024x1024 for efficiency
  Future<SegmentationResult> generateSegmentationMasks({
    required Uint8List imageBytes,
    String? targetObjects,
    double confidenceThreshold = 0.5,
  }) async {
    await waitForInitialization();

    return _errorHandler.executeWithRetry<SegmentationResult>(
      () async {
        final stopwatch = Stopwatch()..start();

        // Create the segmentation prompt
        final prompt = targetObjects != null && targetObjects.isNotEmpty
            ? '''
Give the segmentation masks for the $targetObjects.
Output a JSON list of segmentation masks where each entry contains the 2D
bounding box in the key "box_2d", the segmentation mask in key "mask", and
the text label in the key "label". Use descriptive labels.
'''
            : '''
Give the segmentation masks for all prominent objects in this image.
Output a JSON list of segmentation masks where each entry contains the 2D
bounding box in the key "box_2d", the segmentation mask in key "mask", and
the text label in the key "label". Use descriptive labels.
''';

        final response = await _makeSegmentationRequest(
          prompt: prompt,
          imageBytes: imageBytes,
        );

        stopwatch.stop();

        // Parse the segmentation response
        final segmentationData = _parseSegmentationResponse(response);

        // Get image dimensions (placeholder - in practice you'd decode the image)
        // For now, assume common dimensions
        const imageWidth = 1024;
        const imageHeight = 1024;

        final result = SegmentationResult.fromJson(
          segmentationData,
          imageWidth,
          imageHeight,
          stopwatch.elapsedMilliseconds,
        );

        log('✅ Generated ${result.masks.length} segmentation masks');
        log('📊 Average confidence: ${result.stats.averageConfidence.toStringAsFixed(2)}');

        return result;
      },
      'generateSegmentationMasks',
    ).catchError((e) {
      log('❌ generateSegmentationMasks failed after all retries: $e');
      // Return empty result on error
      return const SegmentationResult(
        masks: [],
        processingTimeMs: 0,
        imageWidth: 1024,
        imageHeight: 1024,
        confidence: 0.0,
      );
    });
  }

  /// Make a segmentation request to Gemini 2.5 with optimized config
  Future<String> _makeSegmentationRequest({
    required String prompt,
    required Uint8List imageBytes,
  }) async {
    final apiKey = EnvConfig.geminiApiKey!;
    const modelName = 'gemini-2.5-flash'; // Use 2.5 for segmentation
    final base64Image = base64Encode(imageBytes);

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Image,
              },
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.1, // Low temperature for consistent results
        'maxOutputTokens': _remoteConfig.maxOutputTokens,
        'topK': 32,
        'topP': 0.9,
        'response_mime_type': 'application/json', // Request JSON response
      },
      // Disable thinking for better object detection results
      'systemInstruction': {
        'parts': [
          {
            'text':
                'You are an expert computer vision system. Provide accurate segmentation masks in the requested JSON format. Focus on precision and avoid hallucinations.'
          }
        ]
      },
      'thinking_config': {
        'thinking_budget': 0 // Disable thinking for better results
      }
    };

    log('🎭 Making segmentation request to Gemini 2.5...');
    log('🔧 Model: $modelName');
    log('📷 Image size: ${imageBytes.length} bytes');

    final response = await _httpClient
        .post(
          Uri.parse('$_baseUrl/$modelName:generateContent?key=$apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        )
        .timeout(_remoteConfig.requestTimeout);

    return _handleApiResponse(response);
  }

  /// Parse segmentation response from Gemini API
  Map<String, dynamic> _parseSegmentationResponse(String response) {
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
        // If it's a list of masks, wrap it in a container
        return {'masks': jsonData};
      } else if (jsonData is Map<String, dynamic>) {
        // If it's already properly formatted
        return jsonData;
      } else {
        throw FormatException(
            'Unexpected JSON structure: ${jsonData.runtimeType}');
      }
    } catch (e) {
      log('❌ Failed to parse segmentation response: $e');
      log('📝 Raw response: $response');

      // Return empty structure on parse error
      return {'masks': []};
    }
  }

  /// Enhanced object detection using Gemini 2.0+ bounding box capabilities
  ///
  /// Uses the new object detection features available in Gemini 2.0 and later
  /// to detect objects and get their bounding box coordinates in normalized format.
  Future<List<Map<String, dynamic>>> detectObjectsWithBoundingBoxes({
    required Uint8List imageBytes,
    String? targetObjects,
  }) async {
    await waitForInitialization();

    return _errorHandler.executeWithRetry<List<Map<String, dynamic>>>(
      () async {
        final prompt = targetObjects != null && targetObjects.isNotEmpty
            ? 'Detect the $targetObjects in the image. The box_2d should be [ymin, xmin, ymax, xmax] normalized to 0-1000.'
            : 'Detect all of the prominent items in the image. The box_2d should be [ymin, xmin, ymax, xmax] normalized to 0-1000.';

        final response = await _makeObjectDetectionRequest(
          prompt: prompt,
          imageBytes: imageBytes,
        );

        // Parse the object detection response
        final detectionData = _parseObjectDetectionResponse(response);

        log('✅ Detected ${detectionData.length} objects with bounding boxes');

        return detectionData;
      },
      'detectObjectsWithBoundingBoxes',
    ).catchError((e) {
      log('❌ detectObjectsWithBoundingBoxes failed after all retries: $e');
      return <Map<String, dynamic>>[];
    });
  }

  /// Make an object detection request to Gemini 2.0+
  Future<String> _makeObjectDetectionRequest({
    required String prompt,
    required Uint8List imageBytes,
  }) async {
    final apiKey = EnvConfig.geminiApiKey!;
    const modelName = 'gemini-2.0-flash-exp'; // Use 2.0+ for object detection
    final base64Image = base64Encode(imageBytes);

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Image,
              },
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.1, // Low temperature for consistent results
        'maxOutputTokens': _remoteConfig.maxOutputTokens,
        'topK': 32,
        'topP': 0.9,
        'response_mime_type': 'application/json', // Request JSON response
      },
    };

    log('🔍 Making object detection request to Gemini 2.0...');
    log('🔧 Model: $modelName');

    final response = await _httpClient
        .post(
          Uri.parse('$_baseUrl/$modelName:generateContent?key=$apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        )
        .timeout(_remoteConfig.requestTimeout);

    return _handleApiResponse(response);
  }

  /// Parse object detection response from Gemini API
  List<Map<String, dynamic>> _parseObjectDetectionResponse(String response) {
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

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:revision/core/config/env_config.dart';
import 'package:revision/core/constants/firebase_ai_constants.dart';
import 'package:revision/core/services/ai_error_handler.dart';
import 'package:revision/core/services/ai_service.dart';
import 'package:revision/core/services/firebase_ai_remote_config_service.dart';

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
  })  : _remoteConfig = remoteConfigService ?? FirebaseAIRemoteConfigService(),
        _httpClient = httpClient ?? http.Client() {
    log('🏗️ Creating GeminiAIService instance...');
    // Don't call _initializeService() in constructor to avoid blocking
    // Service locator registration. Call it later via waitForInitialization()
  }

  final FirebaseAIRemoteConfigService _remoteConfig;
  final http.Client _httpClient;
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
        throw StateError(
            'Gemini API key not configured. Please add GEMINI_API_KEY to your .env file.');
      }

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

  /// Handle API response and extract text
  String _handleApiResponse(http.Response response) {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['candidates'] == null || data['candidates'].isEmpty) {
        throw Exception('No candidates in Gemini API response');
      }

      final candidate = data['candidates'][0];
      if (candidate['content'] == null ||
          candidate['content']['parts'] == null) {
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
    } else {
      log('❌ Gemini API error: ${response.statusCode}');
      log('📝 Response: ${response.body}');
      throw Exception(
          'Gemini API error: ${response.statusCode} - ${response.body}');
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
}

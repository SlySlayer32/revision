import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:revision/core/config/env_config.dart';
import 'package:revision/core/constants/gemini_constants.dart';
import 'package:revision/core/services/ai_error_handler.dart';
import 'package:revision/core/services/ai_service.dart';
import 'package:revision/core/services/firebase_ai_remote_config_service.dart';
import 'package:revision/core/services/gemini_request_builder.dart';
import 'package:revision/core/services/gemini_request_validator.dart';
import 'package:revision/core/services/gemini_response_handler.dart';
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
  })  : _remoteConfig = remoteConfigService ?? FirebaseAIRemoteConfigService(),
        _httpClient = httpClient ?? http.Client(),
        _requestValidator = requestValidator ?? GeminiRequestValidator() {
    log('🏗️ Creating GeminiAIService instance...');
    // _requestBuilder is now initialized in _initializeService
  }

  final FirebaseAIRemoteConfigService _remoteConfig;
  final http.Client _httpClient;
  final GeminiRequestValidator _requestValidator;
  late final GeminiRequestBuilder _requestBuilder;
  final AIErrorHandler _errorHandler = AIErrorHandler();

  static const String _baseUrl = GeminiConstants.baseUrl;

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

      // Initialize the request builder now that remote config is ready
      _requestBuilder = GeminiRequestBuilder(_remoteConfig);
      log('✅ GeminiRequestBuilder initialized');

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
      throw StateError('${GeminiConstants.connectivityTestFailedError}: $e');
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
    // Validate request parameters using extracted validator
    final validationResult = _requestValidator.validateTextRequest(
      prompt: prompt,
      model: model,
    );

    if (!validationResult.isValid) {
      throw ArgumentError(validationResult.errorMessage);
    }

    final apiKey = EnvConfig.geminiApiKey!;
    final modelName = model ?? _remoteConfig.geminiModel;

    final requestBody = _requestBuilder.buildTextOnlyRequest(
      prompt: prompt,
      model: modelName,
    );

    final response = await _httpClient
        .post(
          Uri.parse('$_baseUrl/$modelName:generateContent?key=$apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        )
        .timeout(_remoteConfig.requestTimeout);

    try {
      return GeminiResponseHandler.handleTextResponse(response);
    } catch (e) {
      if (e is Exception) {
        return _handleResponseError(e, 'text processing');
      }
      rethrow;
    }
  }

  /// Make a multimodal request to Gemini API
  Future<String> _makeMultimodalRequest({
    required String prompt,
    required Uint8List imageBytes,
    String? model,
  }) async {
    // Validate request parameters using extracted validator
    final validationResult = _requestValidator.validateMultimodalRequest(
      prompt: prompt,
      imageBytes: imageBytes,
      model: model,
    );

    if (!validationResult.isValid) {
      throw ArgumentError(validationResult.errorMessage);
    }

    final apiKey = EnvConfig.geminiApiKey!;
    final modelName = model ?? _remoteConfig.geminiModel;

    final requestBody = _requestBuilder.buildMultimodalRequest(
      prompt: prompt,
      imageBytes: imageBytes,
      model: modelName,
    );

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

    try {
      return GeminiResponseHandler.handleTextResponse(response);
    } catch (e) {
      if (e is Exception) {
        return _handleResponseError(e, 'image analysis');
      }
      rethrow;
    }
  }

  /// Make an image generation request to Gemini API
  Future<Uint8List?> _makeImageGenerationRequest({
    required String prompt,
    Uint8List? inputImage,
  }) async {
    final apiKey = EnvConfig.geminiApiKey!;
    final modelName = _remoteConfig.geminiImageModel;

    final requestBody = _requestBuilder.buildImageGenerationRequest(
      prompt: prompt,
      inputImage: inputImage,
    );

    log('🎨 Making image generation request...');
    log('📡 Model: $modelName');

    final response = await _httpClient
        .post(
          Uri.parse('$_baseUrl/$modelName:generateContent?key=$apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        )
        .timeout(_remoteConfig.requestTimeout);

    if (response.statusCode == GeminiConstants.httpOk) {
      final data = jsonDecode(response.body);
      return GeminiResponseHandler.extractImageFromResponse(data);
    } else {
      log('❌ Image generation API error: ${response.statusCode}');
      log('📝 Response: ${response.body}');
      throw Exception(
          'Gemini API error: ${response.statusCode} - ${response.body}');
    }
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
        // Validate image size using constants
        if (imageData.length > GeminiConstants.maxImageSizeBytes) {
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
  /// Production-grade features:
  /// - Enhanced validation for all input parameters
  /// - Robust error handling with detailed logging
  /// - Optimized API configuration for segmentation tasks
  /// - Fallback mechanisms for edge cases
  ///
  /// For best results:
  /// - Use images 1024x1024 or smaller
  /// - Provide specific target objects when possible
  /// - Set confidence threshold based on use case needs
  Future<SegmentationResult> generateSegmentationMasks({
    required Uint8List imageBytes,
    String? targetObjects,
    double confidenceThreshold = 0.5,
  }) async {
    await waitForInitialization();

    return _errorHandler.executeWithRetry<SegmentationResult>(
      () async {
        final stopwatch = Stopwatch()..start();

        // Enhanced validation using production-grade validator
        final validationResult = _requestValidator.validateSegmentationRequest(
          prompt: 'segmentation_request', // Placeholder for validation
          imageBytes: imageBytes,
          targetObjects: targetObjects,
          confidenceThreshold: confidenceThreshold,
        );

        if (!validationResult.isValid) {
          throw ArgumentError(
              validationResult.errorMessage ?? 'Invalid segmentation request');
        }

        // Create the enhanced segmentation prompt using the builder
        final prompt = GeminiRequestBuilder.buildSegmentationPrompt(
          targetObjects: targetObjects,
        );

        log('🎯 Starting enhanced segmentation with Gemini 2.5');
        log('📏 Image size: ${(imageBytes.length / 1024 / 1024).toStringAsFixed(2)}MB');
        log('🎯 Target objects: ${targetObjects ?? "all prominent objects"}');
        log('📊 Confidence threshold: $confidenceThreshold');

        final response = await _makeSegmentationRequest(
          prompt: prompt,
          imageBytes: imageBytes,
        );

        stopwatch.stop();

        // Parse the segmentation response with enhanced error handling
        final segmentationData = _parseSegmentationResponse(response);

        // Check for parsing errors in response
        if (segmentationData.containsKey('error')) {
          log('⚠️ Segmentation parsing issue: ${segmentationData['error']}');
          // Continue with what we have, but log the issue
        }

        // Get image dimensions (placeholder - in practice you'd decode the image)
        // For now, assume common dimensions from constants
        const imageWidth = GeminiConstants.defaultImageWidth;
        const imageHeight = GeminiConstants.defaultImageHeight;

        final result = SegmentationResult.fromJson(
          segmentationData,
          imageWidth,
          imageHeight,
          stopwatch.elapsedMilliseconds,
        );

        // Filter masks by confidence threshold
        final filteredMasks = result.masks
            .where((mask) => mask.confidence >= confidenceThreshold)
            .toList();

        final finalResult = filteredMasks.length != result.masks.length
            ? SegmentationResult(
                masks: filteredMasks,
                processingTimeMs: result.processingTimeMs,
                imageWidth: result.imageWidth,
                imageHeight: result.imageHeight,
                modelVersion: result.modelVersion,
                confidence: filteredMasks.isNotEmpty
                    ? filteredMasks
                            .map((m) => m.confidence)
                            .reduce((a, b) => a + b) /
                        filteredMasks.length
                    : 0.0,
              )
            : result;

        log('✅ Generated ${finalResult.masks.length} segmentation masks (filtered from ${result.masks.length})');
        log('📊 Average confidence: ${finalResult.stats.averageConfidence.toStringAsFixed(2)}');
        log('⏱️ Processing time: ${finalResult.processingTimeMs}ms');
        log('🎯 Confidence threshold applied: $confidenceThreshold');

        if (finalResult.masks.isEmpty) {
          log('⚠️ No masks met confidence threshold ${confidenceThreshold}. Consider lowering threshold.');
        }

        return finalResult;
      },
      'generateSegmentationMasks',
    ).catchError((e) {
      log('❌ generateSegmentationMasks failed after all retries: $e');
      // Return empty result with error context for production debugging
      return const SegmentationResult(
        masks: [],
        processingTimeMs: 0,
        imageWidth: GeminiConstants.defaultImageWidth,
        imageHeight: GeminiConstants.defaultImageHeight,
        confidence: 0.0,
        modelVersion: 'gemini-2.5-flash-error',
      );
    });
  }

  /// Make a segmentation request to Gemini 2.5 with optimized config
  Future<String> _makeSegmentationRequest({
    required String prompt,
    required Uint8List imageBytes,
  }) async {
    final apiKey = EnvConfig.geminiApiKey!;
    const modelName = GeminiConstants.gemini2_5FlashModel;

    // Validate API key format
    if (apiKey.length < 30) {
      throw Exception('Invalid Gemini API key format - too short');
    }

    final requestBody = _requestBuilder.buildSegmentationRequest(
      prompt: prompt,
      imageBytes: imageBytes,
    );

    log('🎭 Making segmentation request to Gemini 2.5...');
    log('🔧 Model: $modelName');
    log('📷 Image size: ${imageBytes.length} bytes');
    log('📝 Prompt length: ${prompt.length} characters');
    log('🔍 Request structure: ${requestBody.keys.toList()}');
    log('🔑 API key prefix: ${apiKey.substring(0, 10)}...');

    final url = '$_baseUrl/$modelName:generateContent?key=$apiKey';
    log('🌐 Request URL: ${url.replaceAll(apiKey, 'API_KEY_HIDDEN')}');

    final response = await _httpClient
        .post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        )
        .timeout(_remoteConfig.requestTimeout);

    log('📥 Response status: ${response.statusCode}');
    log('📄 Response length: ${response.body.length} characters');
    log('📋 Response preview: ${response.body.length > 500 ? response.body.substring(0, 500) + "..." : response.body}');

    try {
      return GeminiResponseHandler.handleTextResponse(response);
    } catch (e) {
      if (e is Exception) {
        return _handleResponseError(e, 'segmentation');
      }
      rethrow;
    }
  }

  /// Parse segmentation response from Gemini API
  Map<String, dynamic> _parseSegmentationResponse(String response) {
    return GeminiResponseHandler.parseSegmentationResponse(response);
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

    final requestBody = _requestBuilder.buildObjectDetectionRequest(
      prompt: prompt,
      imageBytes: imageBytes,
    );

    log('🔍 Making object detection request to Gemini 2.0...');
    log('🔧 Model: $modelName');

    final response = await _httpClient
        .post(
          Uri.parse('$_baseUrl/$modelName:generateContent?key=$apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        )
        .timeout(_remoteConfig.requestTimeout);

    try {
      return GeminiResponseHandler.handleTextResponse(response);
    } catch (e) {
      if (e is Exception) {
        return _handleResponseError(e, 'object detection');
      }
      rethrow;
    }
  }

  /// Parse object detection response from Gemini API
  List<Map<String, dynamic>> _parseObjectDetectionResponse(String response) {
    return GeminiResponseHandler.parseObjectDetectionResponse(response);
  }

  /// Handle Gemini API response errors with fallback strategies
  String _handleResponseError(Exception error, String operation) {
    final errorMessage = error.toString();

    log('❌ Gemini API error in $operation: $errorMessage');

    // Check for specific error types and provide appropriate fallbacks
    if (errorMessage.contains('No content parts')) {
      log('🔄 Handling "No content parts" error - likely API structure change');
      return _getFallbackResponse(operation);
    } else if (errorMessage.contains('No candidates')) {
      log('🔄 Handling "No candidates" error - likely empty response');
      return _getFallbackResponse(operation);
    } else if (errorMessage.contains('Content was filtered')) {
      log('🔄 Handling content filtering - using safe fallback');
      return _getSafeContentFallback(operation);
    } else if (errorMessage.contains('safety filters')) {
      log('🔄 Handling safety filter block - using safe fallback');
      return _getSafeContentFallback(operation);
    } else {
      // For other errors, rethrow to maintain existing error handling
      throw error;
    }
  }

  /// Get fallback response for different operations
  String _getFallbackResponse(String operation) {
    switch (operation.toLowerCase()) {
      case 'text processing':
      case 'text prompt':
        return 'I apologize, but I\'m experiencing technical difficulties processing your request. Please try again in a moment.';
      case 'image analysis':
      case 'image processing':
        return 'Unable to analyze the image at this time due to technical issues. Please try uploading the image again.';
      case 'segmentation':
        return '{"masks": [], "error": "Segmentation temporarily unavailable", "fallback": true}';
      case 'object detection':
        return '[]'; // Empty array for object detection
      default:
        return 'Service temporarily unavailable. Please try again later.';
    }
  }

  /// Get safe content fallback for filtered responses
  String _getSafeContentFallback(String operation) {
    switch (operation.toLowerCase()) {
      case 'text processing':
      case 'text prompt':
        return 'I cannot process this request as it may violate content guidelines. Please try rephrasing your request.';
      case 'image analysis':
      case 'image processing':
        return 'Unable to analyze this image due to content guidelines. Please try a different image.';
      case 'segmentation':
        return '{"masks": [], "error": "Content filtered for safety", "filtered": true}';
      case 'object detection':
        return '[]'; // Empty array for object detection
      default:
        return 'Content cannot be processed due to safety guidelines.';
    }
  }
}

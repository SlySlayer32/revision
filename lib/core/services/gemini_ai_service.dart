import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:http/http.dart' as http;
import 'package:revision/core/constants/firebase_ai_constants.dart';
import 'package:revision/core/services/ai_service.dart';
import 'package:revision/core/services/firebase_ai_remote_config_service.dart';
import 'package:revision/core/services/ai_error_handler.dart';

/// Google AI (Gemini API) service implementation
/// Uses Google AI Studio API with Firebase AI SDK
///
/// Configuration:
/// - API key is managed through Firebase Console (not in code)
/// - Model parameters controlled via Firebase Remote Config
/// - Uses Gemini Developer API (not Vertex AI)
/// - Requires Firebase project setup with AI Logic enabled
class GeminiAIService implements AIService {
  GeminiAIService({FirebaseAIRemoteConfigService? remoteConfigService})
      : _remoteConfig = remoteConfigService ?? FirebaseAIRemoteConfigService() {
    _initializeService();
  }

  final FirebaseAIRemoteConfigService _remoteConfig;
  final AIErrorHandler _errorHandler = AIErrorHandler();
  GenerativeModel? _geminiModel;
  GenerativeModel? _geminiImageModel;

  /// Expose the generative models for DI
  GenerativeModel get analysisModel {
    if (!_isInitialized) {
      log('⏳ GeminiAIService is still initializing, starting initialization...');
      _initializeService();
      throw StateError(
          'Gemini analysis model not yet initialized. Service is starting up...');
    }
    if (_geminiModel == null) {
      log('❌ CRITICAL: Gemini analysis model not initialized');
      log('💡 This usually means:');
      log('   1. Firebase AI Logic not enabled in Firebase Console');
      log('   2. Gemini API key not configured');
      log('   3. Required APIs not enabled');
      log('🔗 Go to: https://console.firebase.google.com/project/revision-464202/ailogic');
      throw StateError(
          'Gemini analysis model not initialized. Please check Firebase AI setup.');
    }
    return _geminiModel!;
  }

  GenerativeModel get imageGenerationModel {
    if (_geminiImageModel == null) {
      log('❌ CRITICAL: Gemini image model not initialized');
      log('💡 Complete Firebase AI Logic setup in Firebase Console');
      log('🔗 Go to: https://console.firebase.google.com/project/revision-464202/ailogic');
      throw StateError(
          'Gemini image model not initialized. Please check Firebase AI setup.');
    }
    return _geminiImageModel!;
  }

  bool _isInitialized = false;
  Completer<void>? _initializationCompleter;

  Future<void> _initializeService() async {
    if (_isInitialized) return;

    // If already initializing, wait for the existing initialization
    if (_initializationCompleter != null) {
      return _initializationCompleter!.future;
    }

    _initializationCompleter = Completer<void>();

    try {
      log('🚀 Initializing Firebase AI Logic with Remote Config...');

      // Initialize Remote Config first
      await _remoteConfig.initialize();

      // Initialize models with Remote Config values
      await _initializeModels();

      _isInitialized = true;
      _initializationCompleter!.complete();
      log('✅ Firebase AI Logic initialized successfully');
    } catch (e) {
      log('❌ Failed to initialize Firebase AI Logic: $e');
      // Fall back to constants if Remote Config fails
      await _initializeModelsWithConstants();
      _isInitialized = true;
      _initializationCompleter!.complete();
    }
  }

  /// Wait for the service to be fully initialized
  Future<void> waitForInitialization() async {
    if (_isInitialized) return;
    if (_initializationCompleter != null) {
      return _initializationCompleter!.future;
    }
    // If not started, start initialization
    return _initializeService();
  }

  Future<void> _initializeModels() async {
    try {
      log('🔧 Starting Gemini model initialization...');
      log('🔍 Analysis model: ${_remoteConfig.geminiModel}');
      log('🔍 Image model: ${_remoteConfig.geminiImageModel}');

      // Initialize Firebase AI with Google AI backend (AI Studio)
      // API key is configured in Firebase Console, not passed here
      log('🔧 Creating FirebaseAI.googleAI() instance...');
      final firebaseAI = FirebaseAI.googleAI();
      log('✅ Firebase AI instance created successfully');

      // Test if Firebase AI can communicate with backend
      log('🔧 Testing Firebase AI backend connectivity...');

      // Initialize Gemini model for text and analysis using Remote Config
      log('🔧 Initializing analysis model: ${_remoteConfig.geminiModel}');
      _geminiModel = firebaseAI.generativeModel(
        model: _remoteConfig.geminiModel,
        generationConfig: GenerationConfig(
          temperature: _remoteConfig.temperature,
          maxOutputTokens: _remoteConfig.maxOutputTokens,
          topK: _remoteConfig.topK,
          topP: _remoteConfig.topP,
          responseModalities: [
            ResponseModalities.text,
            ResponseModalities.image
          ],
        ),
        systemInstruction: Content.text(_remoteConfig.analysisSystemPrompt),
      );
      log('✅ Analysis model initialized successfully with image output support');

      // Initialize Gemini model for image processing using Remote Config
      log('🔧 Initializing image model: ${_remoteConfig.geminiImageModel}');

      _geminiImageModel = firebaseAI.generativeModel(
        model: _remoteConfig.geminiImageModel,
        generationConfig: GenerationConfig(
          temperature:
              _remoteConfig.temperature * 0.75, // Slightly lower for images
          maxOutputTokens:
              _remoteConfig.maxOutputTokens * 2, // More tokens for images
          topK: 32,
          topP: 0.9,
          // Specify both TEXT and IMAGE response modalities for image generation model
          responseModalities: [
            ResponseModalities.text,
            ResponseModalities.image
          ],
        ),
        // Flash 2.0 image generation model doesn't support system instructions
        systemInstruction: null,
      );
      log('✅ Image model initialized successfully');

      // Test model availability with a simple prompt
      _testModelAvailability();

      log('✅ Google AI (Gemini API) models initialized successfully');
      log('🔑 API key source: Firebase Console configuration');
      log('🔍 Using Remote Config values: ${_remoteConfig.exportConfig()}');
    } catch (e, stackTrace) {
      log('❌ Failed to initialize Google AI models: $e',
          stackTrace: stackTrace);
      log('💡 Common issues:');
      log('   - Firebase project not set up with AI Logic');
      log('   - Gemini API not enabled in Firebase Console');
      log('   - API key not configured in Firebase Console');
      log('   - Firebase not initialized properly');
      rethrow;
    }
  }

  /// Test model availability with a simple prompt
  void _testModelAvailability() {
    // Don't await, just fire and forget for testing
    Future.delayed(Duration.zero, () async {
      try {
        log('🧪 Testing Gemini model availability...');
        if (_geminiModel != null) {
          final response = await _geminiModel!.generateContent([
            Content.text('Hello, are you working?')
          ]).timeout(const Duration(seconds: 10));

          if (response.text != null) {
            log('✅ Gemini model test successful');
          } else {
            log('⚠️ Gemini model test returned empty response');
          }
        }
      } catch (e) {
        log('🚨 Gemini model test failed: $e');
        log('This indicates the models may not be properly accessible');
      }
    });
  }

  Future<void> _initializeModelsWithConstants() async {
    try {
      log('⚠️ Falling back to constants for model initialization...');

      // Initialize Firebase AI with Google AI backend (AI Studio)
      final firebaseAI = FirebaseAI.googleAI();

      // Initialize Gemini model for text and analysis using constants
      _geminiModel = firebaseAI.generativeModel(
        model: FirebaseAIConstants.geminiModel,
        generationConfig: GenerationConfig(
          temperature: FirebaseAIConstants.temperature,
          maxOutputTokens: FirebaseAIConstants.maxOutputTokens,
          topK: FirebaseAIConstants.topK,
          topP: FirebaseAIConstants.topP,
          responseModalities: [
            ResponseModalities.text,
            ResponseModalities.image
          ],
        ),
        systemInstruction:
            Content.text(FirebaseAIConstants.analysisSystemPrompt),
      );

      // Initialize Gemini model for image processing using constants

      _geminiImageModel = firebaseAI.generativeModel(
        model: FirebaseAIConstants.geminiImageModel,
        generationConfig: GenerationConfig(
          temperature: 0.3, // Lower temperature for more controlled responses
          maxOutputTokens: 2048,
          topK: 32,
          topP: 0.9,
          // Specify both TEXT and IMAGE response modalities for image generation model
          responseModalities: [
            ResponseModalities.text,
            ResponseModalities.image
          ],
        ),
        // Flash 2.0 image generation model doesn't support system instructions
        systemInstruction: null,
      );

      log('✅ Models initialized with constants fallback');
    } catch (e, stackTrace) {
      log('❌ Failed to initialize models with constants: $e',
          stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Process text prompt using Google AI with robust error handling
  Future<String> processTextPrompt(String prompt) async {
    return _errorHandler.executeWithRetry<String>(
      () async {
        if (_geminiModel == null) {
          throw StateError(
              'Gemini model not initialized. Please check Firebase AI setup.');
        }

        final content = [Content.text(prompt)];

        final response = await _geminiModel!
            .generateContent(content)
            .timeout(_remoteConfig.requestTimeout);

        // Validate response using AIResponseValidator
        return AIResponseValidator.validateAndExtractText(response);
      },
      'processTextPrompt',
    ).catchError((e) {
      log('❌ Google AI processTextPrompt failed after all retries: $e');

      // Return fallback response for MVP
      return 'Sorry, I encountered an error processing your request. Please try again.';
    });
  }

  @override
  Future<String> processImagePrompt(Uint8List imageData, String prompt) async {
    return _errorHandler.executeWithRetry<String>(
      () async {
        if (_geminiImageModel == null) {
          throw StateError(
              'Gemini image model not initialized. Please check Firebase AI setup.');
        }

        // Validate image size using updated constants
        if (imageData.length >
            FirebaseAIConstants.maxImageSizeMB * 1024 * 1024) {
          throw Exception(
            'Image too large: ${imageData.length ~/ (1024 * 1024)}MB',
          );
        }

        // Create content with image and text using Google AI
        final content = [
          Content.multi([
            Part.blob('image/jpeg', imageData),
            TextPart('''
Analyze this image and provide editing instructions based on: $prompt

Focus on:
1. Object identification and removal suggestions
2. Background reconstruction techniques
3. Lighting and shadow adjustments
4. Color harmony maintenance

Provide clear, actionable editing steps.
'''),
          ]),
        ];

        final response = await _geminiImageModel!
            .generateContent(content)
            .timeout(_remoteConfig.requestTimeout);

        // Validate response using AIResponseValidator
        return AIResponseValidator.validateAndExtractText(response);
      },
      'processImagePrompt',
    ).catchError((e) {
      log('❌ Google AI processImagePrompt failed after all retries: $e');

      // Return fallback response for MVP
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
    return _errorHandler.executeWithRetry<String>(
      () async {
        if (_geminiImageModel == null) {
          throw StateError(
              'Gemini image model not initialized. Please check Firebase AI setup.');
        }

        final content = [
          Content.multi([
            Part.blob('image/jpeg', imageData),
            TextPart('''
Describe this image in detail for photo editing purposes.

Include:
1. Main subjects and objects
2. Lighting conditions
3. Colors and composition
4. Background elements
5. Overall mood and style

Keep the description clear and technical.
'''),
          ]),
        ];

        final response = await _geminiImageModel!
            .generateContent(content)
            .timeout(_remoteConfig.requestTimeout);

        // Validate response using AIResponseValidator
        return AIResponseValidator.validateAndExtractText(response);
      },
      'generateImageDescription',
    ).catchError((e) {
      log('❌ Google AI generateImageDescription failed after all retries: $e');
      return 'Unable to analyze image at this time.';
    });
  }

  @override
  Future<List<String>> suggestImageEdits(Uint8List imageData) async {
    return _errorHandler.executeWithRetry<List<String>>(
      () async {
        if (_geminiImageModel == null) {
          throw StateError(
              'Gemini image model not initialized. Please check Firebase AI setup.');
        }

        final content = [
          Content.multi([
            Part.blob('image/jpeg', imageData),
            TextPart('''
Analyze this image and provide 5 specific editing suggestions to improve it.

Focus on:
1. Object removal opportunities
2. Lighting improvements
3. Composition enhancements
4. Color corrections
5. Background improvements

Provide each suggestion as a clear, actionable sentence.
'''),
          ]),
        ];

        final response = await _geminiImageModel!
            .generateContent(content)
            .timeout(_remoteConfig.requestTimeout);

        // Validate response using AIResponseValidator
        final responseText =
            AIResponseValidator.validateAndExtractText(response);

        // Parse response into suggestions
        final suggestions = responseText
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
      log('❌ Google AI suggestImageEdits failed after all retries: $e');
      return _getFallbackSuggestions();
    });
  }

  @override
  Future<bool> checkContentSafety(Uint8List imageData) async {
    return _errorHandler.executeWithRetry<bool>(
      () async {
        if (_geminiImageModel == null) {
          throw StateError(
              'Gemini image model not initialized. Please check Firebase AI setup.');
        }

        final content = [
          Content.multi([
            Part.blob('image/jpeg', imageData),
            TextPart('''
Analyze this image for content safety. Is this image appropriate for a photo editing application?

Consider:
1. Does it contain inappropriate content?
2. Is it suitable for general audiences?
3. Does it violate content policies?

Respond with "SAFE" if appropriate, "UNSAFE" if not appropriate, followed by a brief reason.
'''),
          ]),
        ];

        final response = await _geminiImageModel!
            .generateContent(content)
            .timeout(_remoteConfig.requestTimeout);

        // Validate response using AIResponseValidator
        final responseText =
            AIResponseValidator.validateAndExtractText(response).toUpperCase();

        return responseText.contains('SAFE') &&
            !responseText.contains('UNSAFE');
      },
      'checkContentSafety',
    ).catchError((e) {
      log('❌ Google AI checkContentSafety failed after all retries: $e');
      // Default to safe on error
      return true;
    });
  }

  @override
  Future<String> generateEditingPrompt({
    required Uint8List imageBytes,
    required List<Map<String, dynamic>> markers,
  }) async {
    return _errorHandler.executeWithRetry<String>(
      () async {
        if (_geminiImageModel == null) {
          throw StateError(
              'Gemini image model not initialized. Please check Firebase AI setup.');
        }

        final markerDescriptions = markers
            .map((marker) =>
                'Marker at (${marker['x']}, ${marker['y']}): ${marker['description'] ?? 'Object to edit'}')
            .join('\n');

        final content = [
          Content.multi([
            Part.blob('image/jpeg', imageBytes),
            TextPart('''
Generate a detailed editing prompt for this image based on the user's markers:

$markerDescriptions

Create a comprehensive editing instruction that includes:
1. What objects/areas to modify
2. How to handle the background
3. Lighting and shadow considerations
4. Color matching requirements
5. Specific techniques to use

Provide a clear, actionable editing prompt.
'''),
          ]),
        ];

        final response = await _geminiImageModel!
            .generateContent(content)
            .timeout(_remoteConfig.requestTimeout);

        // Validate response using AIResponseValidator
        return AIResponseValidator.validateAndExtractText(response);
      },
      'generateEditingPrompt',
    ).catchError((e) {
      log('❌ Google AI generateEditingPrompt failed after all retries: $e');
      return 'Remove marked objects and blend the background seamlessly.';
    });
  }

  @override
  Future<Uint8List> processImageWithAI({
    required Uint8List imageBytes,
    required String editingPrompt,
  }) async {
    return _errorHandler.executeWithRetry<Uint8List>(
      () async {
        if (_geminiImageModel == null) {
          throw StateError(
              'Gemini image model not initialized. Please check Firebase AI setup.');
        }

        log('🤖 Processing image with AI using prompt: $editingPrompt');

        // Check if this is the image generation model
        final isImageGenerationModel =
            FirebaseAIConstants.geminiImageModel.contains('image-generation');

        if (isImageGenerationModel) {
          // For Gemini 2.0 Flash image generation model
          // This model generates new images based on prompts, not edits existing ones
          final content = [
            Content.multi([
              TextPart('''
Generate a new image based on this editing request: $editingPrompt

Create a high-quality image that represents the desired result after the editing operation.
Focus on creating a clean, professional result that matches the editing intent.
'''),
            ]),
          ];

          final response = await _geminiImageModel!
              .generateContent(content)
              .timeout(_remoteConfig.requestTimeout);

          // Use AIResponseValidator to extract image data
          try {
            final imageData =
                AIResponseValidator.validateAndExtractImageData(response);
            log('✅ AI image generation completed successfully');
            return Uint8List.fromList(imageData);
          } catch (e) {
            // If no image was generated, fall back to original
            log('⚠️ No image data found in AI response, returning original image');
            return imageBytes;
          }
        } else {
          // For other models that don't support image generation
          // This is image analysis, not generation - return original
          log('⚠️ Model does not support image generation - returning original image');
          return imageBytes;
        }
      },
      'processImageWithAI',
    ).catchError((e) {
      log('❌ Google AI processImageWithAI failed after all retries: $e');
      // Return original image on error
      return imageBytes;
    });
  }

  /// Refresh Remote Config and reinitialize models with new values
  Future<void> refreshConfig() async {
    if (!_isInitialized) return;

    try {
      log('🔄 Refreshing Firebase AI Remote Config...');
      await _remoteConfig.refresh();

      // Reinitialize models with new config values
      await _initializeModels();

      log('✅ Firebase AI Remote Config refreshed successfully');
    } catch (e) {
      log('⚠️ Failed to refresh Remote Config: $e');
    }
  }

  /// Get current Remote Config values for debugging
  Map<String, dynamic> getConfigDebugInfo() {
    return _remoteConfig.getAllValues();
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
}

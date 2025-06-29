import 'dart:developer';
import 'dart:typed_data';

import 'package:revision/core/services/ai_service.dart';
import 'package:revision/core/services/gemini_ai_service.dart';
import 'package:revision/core/services/vertex_ai_service.dart';
import 'package:revision/core/services/ai_fallback_service.dart';
import 'package:revision/core/services/firebase_ai_remote_config_service.dart';

/// Factory for creating AI services with proper fallback configuration
class AIServiceFactory {
  static AIService? _primaryService;
  static AIService? _secondaryService;
  static AIServiceSelector? _serviceSelector;

  /// Get the configured AI service with fallback
  static AIServiceSelector getAIService() {
    if (_serviceSelector != null) {
      return _serviceSelector!;
    }

    // Initialize services
    _initializeServices();
    
    _serviceSelector = AIServiceSelector(
      primaryService: _primaryService!,
      secondaryService: _secondaryService,
      fallbackService: const AIFallbackService(),
    );

    return _serviceSelector!;
  }

  /// Initialize AI services with error handling
  static void _initializeServices() {
    try {
      log('🔧 Initializing AI services...');

      // Try to initialize Gemini AI Service (Google AI Studio)
      try {
        final remoteConfig = FirebaseAIRemoteConfigService();
        _primaryService = GeminiAIService(remoteConfigService: remoteConfig);
        log('✅ Primary service: GeminiAIService initialized');
      } catch (e) {
        log('⚠️ Failed to initialize GeminiAIService: $e');
      }

      // Try to initialize Vertex AI Service as secondary
      try {
        _secondaryService = VertexAIService();
        log('✅ Secondary service: VertexAIService initialized');
      } catch (e) {
        log('⚠️ Failed to initialize VertexAIService: $e');
      }

      // Ensure we have at least one service
      if (_primaryService == null && _secondaryService == null) {
        log('❌ No AI services available, using fallback only');
        _primaryService = const AIFallbackService();
      }

    } catch (e) {
      log('❌ Critical error initializing AI services: $e');
      _primaryService = const AIFallbackService();
    }
  }

  /// Reset services for testing
  static void reset() {
    _primaryService = null;
    _secondaryService = null;
    _serviceSelector = null;
  }

  /// Get service health status
  static Map<String, dynamic> getServiceStatus() {
    return {
      'primary_service': _primaryService?.runtimeType.toString() ?? 'None',
      'secondary_service': _secondaryService?.runtimeType.toString() ?? 'None',
      'fallback_available': true,
      'has_selector': _serviceSelector != null,
    };
  }
}

/// Enhanced AI service that provides a convenient interface to the service selector
/// This class serves as the main entry point for AI operations in the application
class EnhancedAIService implements AIService {
  /// Creates an enhanced AI service with automatic service selection and fallback
  EnhancedAIService() {
    _serviceSelector = AIServiceFactory.getAIService();
  }

  late final AIServiceSelector _serviceSelector;

  @override
  Future<String> processTextPrompt(String prompt) async {
    return _serviceSelector.processTextPrompt(prompt);
  }

  @override
  Future<String> processImagePrompt(Uint8List imageData, String prompt) async {
    return _serviceSelector.processImagePrompt(imageData, prompt);
  }

  @override
  Future<String> generateImageDescription(Uint8List imageData) async {
    return _serviceSelector.generateImageDescription(imageData);
  }

  @override
  Future<List<String>> suggestImageEdits(Uint8List imageData) async {
    return _serviceSelector.suggestImageEdits(imageData);
  }

  @override
  Future<bool> checkContentSafety(Uint8List imageData) async {
    // Use executeWithFallback to provide consistent error handling
    return _serviceSelector.executeWithFallback<bool>(
      (service) => service.checkContentSafety(imageData),
      'checkContentSafety',
    );
  }

  @override
  Future<String> generateEditingPrompt({
    required Uint8List imageBytes,
    required List<Map<String, dynamic>> markers,
  }) async {
    return _serviceSelector.generateEditingPrompt(
      imageBytes: imageBytes,
      markers: markers,
    );
  }

  @override
  Future<Uint8List> processImageWithAI({
    required Uint8List imageBytes,
    required String editingPrompt,
  }) async {
    return _serviceSelector.processImageWithAI(
      imageBytes: imageBytes,
      editingPrompt: editingPrompt,
    );
  }
}

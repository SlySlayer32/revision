import 'dart:developer';
import 'dart:typed_data';

import 'package:revision/core/services/ai_service.dart';
import 'package:revision/core/services/gemini_ai_service.dart';
import 'package:revision/core/services/ai_fallback_service.dart';
import 'package:revision/core/services/firebase_ai_remote_config_service.dart';

/// Factory for creating AI services with Firebase AI Logic only
///
/// This factory provides a centralized way to initialize Firebase AI Logic service
/// with proper error handling and fallback mechanisms. Uses only Firebase AI Logic
/// (not Vertex AI) to ensure backend-free operation.
class AIServiceFactory {
  static AIService? _primaryService;
  static AIServiceSelector? _serviceSelector;
  static bool _isInitialized = false;

  /// Get the configured AI service with fallback
  ///
  /// Returns a service selector that automatically handles service failures
  /// and provides fallback capabilities for robust AI operations.
  static AIServiceSelector getAIService() {
    if (_serviceSelector != null) {
      return _serviceSelector!;
    }

    // Initialize services
    _initializeServices();

    _serviceSelector = AIServiceSelector(
      primaryService: _primaryService!,
      secondaryService: null, // No secondary service - Firebase AI Logic only
      fallbackService: const AIFallbackService(),
    );

    _isInitialized = true;
    return _serviceSelector!;
  }

  /// Initialize AI services with comprehensive error handling
  ///
  /// Attempts to initialize Firebase AI Logic service only.
  /// Falls back to AIFallbackService if initialization fails.
  static void _initializeServices() {
    if (_isInitialized) {
      return;
    }

    try {
      log('🔧 Initializing Firebase AI Logic service...');

      // Try to initialize Firebase AI Logic Service (Google AI backend only)
      _initializePrimaryService();

      // Ensure we have at least one service
      _ensureServiceAvailability();

      log('✅ AI services initialization completed');
    } catch (e) {
      log('❌ Critical error initializing AI services: $e');
      _primaryService = const AIFallbackService();
    }
  }

  /// Initialize the primary AI service (Firebase AI Logic)
  static void _initializePrimaryService() {
    try {
      final remoteConfig = FirebaseAIRemoteConfigService();
      _primaryService = GeminiAIService(remoteConfigService: remoteConfig);
      log('✅ Primary service: GeminiAIService (Firebase AI Logic) initialized');
    } catch (e) {
      log('⚠️ Failed to initialize GeminiAIService: $e');
      _primaryService = null;
    }
  }

  /// Ensure at least one service is available
  static void _ensureServiceAvailability() {
    if (_primaryService == null) {
      log('❌ No AI services available, using fallback only');
      _primaryService = const AIFallbackService();
    }
  }

  /// Reset services for testing
  ///
  /// This method is primarily used for testing to reset the factory state
  /// and allow for fresh initialization in test environments.
  static void reset() {
    _primaryService = null;
    _serviceSelector = null;
    _isInitialized = false;
  }

  /// Get comprehensive service health status
  ///
  /// Returns detailed information about the current state of Firebase AI Logic service
  /// including initialization status and available services.
  static Map<String, dynamic> getServiceStatus() {
    return {
      'is_initialized': _isInitialized,
      'primary_service': _primaryService?.runtimeType.toString() ?? 'None',
      'secondary_service': 'None (Firebase AI Logic only)',
      'fallback_available': true,
      'has_selector': _serviceSelector != null,
      'service_count': _primaryService != null ? 1 : 0,
    };
  }

  /// Create a direct instance of the enhanced AI service
  ///
  /// This is a convenience method for creating an EnhancedAIService instance
  /// that automatically handles service selection and fallback.
  static EnhancedAIService createEnhancedService() {
    return EnhancedAIService();
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

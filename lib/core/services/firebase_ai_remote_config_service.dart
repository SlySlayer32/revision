import 'dart:convert';
import 'dart:developer';

import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Service for managing Firebase Remote Config for AI model parameters
/// 
/// This service allows you to control AI model behavior from the Firebase Console
/// without needing to rebuild your app. You can dynamically update:
/// - Model names and versions
/// - Generation parameters (temperature, tokens, etc.)
/// - System instructions and prompts
/// - Feature flags for AI capabilities
/// 
/// Setup in Firebase Console:
/// 1. Go to Firebase Console > Remote Config
/// 2. Add the parameters defined in this class
/// 3. Set default values and publish
/// 4. Optionally create conditions for A/B testing
class FirebaseAIRemoteConfigService {
  static const String _geminiModelKey = 'ai_gemini_model';
  static const String _geminiImageModelKey = 'ai_gemini_image_model';
  static const String _temperatureKey = 'ai_temperature';
  static const String _maxOutputTokensKey = 'ai_max_output_tokens';
  static const String _topKKey = 'ai_top_k';
  static const String _topPKey = 'ai_top_p';
  static const String _analysisSystemPromptKey = 'ai_analysis_system_prompt';
  static const String _editingSystemPromptKey = 'ai_editing_system_prompt';
  static const String _requestTimeoutSecondsKey = 'ai_request_timeout_seconds';
  static const String _enableAdvancedFeaturesKey = 'ai_enable_advanced_features';
  static const String _debugModeKey = 'ai_debug_mode';

  late final FirebaseRemoteConfig _remoteConfig;
  bool _isInitialized = false;

  /// Default values that match current FirebaseAIConstants
  static const Map<String, dynamic> _defaultValues = {
    _geminiModelKey: 'gemini-2.5-flash',
    _geminiImageModelKey: 'gemini-2.0-flash-preview-image-generation',
    _temperatureKey: 0.4,
    _maxOutputTokensKey: 1024,
    _topKKey: 40,
    _topPKey: 0.95,
    _analysisSystemPromptKey: '''
You are an expert image analysis AI. Analyze the provided image and marked object to create precise editing instructions.

Focus on:
1. Object identification and boundaries
2. Background reconstruction techniques  
3. Lighting and shadow analysis
4. Color harmony considerations
5. Realistic removal strategies

Provide actionable editing instructions.
''',
    _editingSystemPromptKey: '''
You are an expert AI image editor using Gemini 2.0 Flash Preview Image Generation. Edit the provided image based on user instructions with these requirements:

1. Generate a new version of the image with the requested edits applied
2. If removing objects: use content-aware reconstruction to fill the space naturally
3. If enhancing: improve lighting, contrast, color balance, and composition
4. Maintain original image resolution and quality
5. Preserve overall composition and visual coherence
6. Apply changes seamlessly and realistically

Return the edited image directly as the output.
''',
    _requestTimeoutSecondsKey: 30,
    _enableAdvancedFeaturesKey: true,
    _debugModeKey: false,
  };

  /// Initialize Remote Config with default values
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      log('🔧 Initializing Firebase Remote Config for AI parameters...');
      
      _remoteConfig = FirebaseRemoteConfig.instance;
      
      // Set config settings
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1), // Cache for 1 hour
      ));

      // Set default values
      await _remoteConfig.setDefaults(_defaultValues);

      // Fetch and activate latest values
      await _remoteConfig.fetchAndActivate();

      _isInitialized = true;
      log('✅ Firebase Remote Config initialized successfully');
      _logCurrentValues();
      
    } catch (e) {
      log('❌ Failed to initialize Firebase Remote Config: $e');
      // Continue with default values
      _isInitialized = true;
    }
  }

  /// Fetch latest config values from Firebase
  Future<void> refresh() async {
    if (!_isInitialized) await initialize();
    
    try {
      log('🔄 Refreshing Remote Config values...');
      await _remoteConfig.fetchAndActivate();
      log('✅ Remote Config refreshed successfully');
      _logCurrentValues();
    } catch (e) {
      log('⚠️ Failed to refresh Remote Config: $e');
    }
  }

  /// Get Gemini model name for text/analysis
  String get geminiModel {
    if (!_isInitialized) return _defaultValues[_geminiModelKey] as String;
    return _remoteConfig.getString(_geminiModelKey);
  }

  /// Get Gemini model name for image generation
  String get geminiImageModel {
    if (!_isInitialized) return _defaultValues[_geminiImageModelKey] as String;
    return _remoteConfig.getString(_geminiImageModelKey);
  }

  /// Get temperature parameter for generation
  double get temperature {
    if (!_isInitialized) return _defaultValues[_temperatureKey] as double;
    return _remoteConfig.getDouble(_temperatureKey);
  }

  /// Get max output tokens
  int get maxOutputTokens {
    if (!_isInitialized) return _defaultValues[_maxOutputTokensKey] as int;
    return _remoteConfig.getInt(_maxOutputTokensKey);
  }

  /// Get top-K parameter
  int get topK {
    if (!_isInitialized) return _defaultValues[_topKKey] as int;
    return _remoteConfig.getInt(_topKKey);
  }

  /// Get top-P parameter
  double get topP {
    if (!_isInitialized) return _defaultValues[_topPKey] as double;
    return _remoteConfig.getDouble(_topPKey);
  }

  /// Get analysis system prompt
  String get analysisSystemPrompt {
    if (!_isInitialized) return _defaultValues[_analysisSystemPromptKey] as String;
    return _remoteConfig.getString(_analysisSystemPromptKey);
  }

  /// Get editing system prompt
  String get editingSystemPrompt {
    if (!_isInitialized) return _defaultValues[_editingSystemPromptKey] as String;
    return _remoteConfig.getString(_editingSystemPromptKey);
  }

  /// Get request timeout in seconds
  int get requestTimeoutSeconds {
    if (!_isInitialized) return _defaultValues[_requestTimeoutSecondsKey] as int;
    return _remoteConfig.getInt(_requestTimeoutSecondsKey);
  }

  /// Get request timeout as Duration
  Duration get requestTimeout => Duration(seconds: requestTimeoutSeconds);

  /// Check if advanced features are enabled
  bool get enableAdvancedFeatures {
    if (!_isInitialized) return _defaultValues[_enableAdvancedFeaturesKey] as bool;
    return _remoteConfig.getBool(_enableAdvancedFeaturesKey);
  }

  /// Check if debug mode is enabled
  bool get debugMode {
    if (!_isInitialized) return _defaultValues[_debugModeKey] as bool;
    return _remoteConfig.getBool(_debugModeKey);
  }

  /// Get all current config values as a map (useful for debugging)
  Map<String, dynamic> getAllValues() {
    return {
      'geminiModel': geminiModel,
      'geminiImageModel': geminiImageModel,
      'temperature': temperature,
      'maxOutputTokens': maxOutputTokens,
      'topK': topK,
      'topP': topP,
      'analysisSystemPrompt': analysisSystemPrompt.length > 100 
          ? '${analysisSystemPrompt.substring(0, 100)}...' 
          : analysisSystemPrompt,
      'editingSystemPrompt': editingSystemPrompt.length > 100 
          ? '${editingSystemPrompt.substring(0, 100)}...' 
          : editingSystemPrompt,
      'requestTimeoutSeconds': requestTimeoutSeconds,
      'enableAdvancedFeatures': enableAdvancedFeatures,
      'debugMode': debugMode,
    };
  }

  void _logCurrentValues() {
    if (_remoteConfig.getBool(_debugModeKey)) {
      log('🔍 Current AI Remote Config values:');
      log('  Model: ${geminiModel}');
      log('  Image Model: ${geminiImageModel}');
      log('  Temperature: ${temperature}');
      log('  Max Tokens: ${maxOutputTokens}');
      log('  Top-K: ${topK}');
      log('  Top-P: ${topP}');
      log('  Timeout: ${requestTimeoutSeconds}s');
      log('  Advanced Features: ${enableAdvancedFeatures}');
      log('  Debug Mode: ${debugMode}');
    }
  }

  /// Export current config for backup/sharing
  String exportConfig() {
    return jsonEncode(getAllValues());
  }
}

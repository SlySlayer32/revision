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
  // System prompts removed - Flash 2.0 image generation model doesn't support them
  static const String _requestTimeoutSecondsKey = 'ai_request_timeout_seconds';
  static const String _enableAdvancedFeaturesKey =
      'ai_enable_advanced_features';
  static const String _debugModeKey = 'ai_debug_mode';

  late final FirebaseRemoteConfig _remoteConfig;
  bool _isInitialized = false;

  /// Default values that match current FirebaseAIConstants
  static const Map<String, dynamic> _defaultValues = {
    _geminiModelKey: 'gemini-1.5-flash-002',
    _geminiImageModelKey: 'gemini-2.0-flash-preview-image-generation',
    _temperatureKey: 0.4,
    _maxOutputTokensKey: 1024,
    _topKKey: 40,
    _topPKey: 0.95,
    // System prompts removed - Flash 2.0 image generation model doesn't support them
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
      log('🔄 Fetching Remote Config from Firebase...');
      final fetchSuccess = await _remoteConfig.fetchAndActivate();
      log('📥 Remote Config fetch result: $fetchSuccess');

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

  // System prompt getters removed - Flash 2.0 image generation model doesn't support them

  /// Get request timeout in seconds
  int get requestTimeoutSeconds {
    if (!_isInitialized)
      return _defaultValues[_requestTimeoutSecondsKey] as int;
    return _remoteConfig.getInt(_requestTimeoutSecondsKey);
  }

  /// Get request timeout as Duration
  Duration get requestTimeout => Duration(seconds: requestTimeoutSeconds);

  /// Check if advanced features are enabled
  bool get enableAdvancedFeatures {
    if (!_isInitialized)
      return _defaultValues[_enableAdvancedFeaturesKey] as bool;
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
      // System prompts removed for Flash 2.0 compatibility
      'requestTimeoutSeconds': requestTimeoutSeconds,
      'enableAdvancedFeatures': enableAdvancedFeatures,
      'debugMode': debugMode,
    };
  }

  void _logCurrentValues() {
    log('🔍 Current AI Remote Config values:');
    log('  Initialized: $_isInitialized');
    log('  Using defaults: ${!_isInitialized || _remoteConfig.lastFetchStatus != RemoteConfigFetchStatus.success}');
    log('  Last fetch status: ${_isInitialized ? _remoteConfig.lastFetchStatus : 'Not initialized'}');
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

  /// Export current config for backup/sharing
  String exportConfig() {
    return jsonEncode(getAllValues());
  }
}

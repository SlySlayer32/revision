import 'dart:developer';

import 'package:revision/core/config/environment_detector.dart';
import 'package:revision/core/services/firebase_ai_remote_config_service.dart';

/// Feature flag service that controls app features and debug tools
///
/// This service extends Firebase Remote Config to manage feature flags
/// and provides environment-aware feature toggles.
class FeatureFlagService {
  static final FeatureFlagService _instance = FeatureFlagService._();
  factory FeatureFlagService() => _instance;
  FeatureFlagService._();

  FirebaseAIRemoteConfigService? _remoteConfigService;
  bool _isInitialized = false;

  /// Feature flag keys
  static const String _showDebugToolsKey = 'show_debug_tools';
  static const String _enableOnboardingKey = 'enable_onboarding';
  static const String _enableAnalyticsKey = 'enable_analytics';
  static const String _enableSecurityNotificationsKey = 'enable_security_notifications';
  static const String _enableUpdatePromptsKey = 'enable_update_prompts';
  static const String _enableAdvancedNavigationKey = 'enable_advanced_navigation';
  static const String _maintenanceModeKey = 'maintenance_mode';
  static const String _forceUpdateKey = 'force_update';

  /// Default feature flag values
  static final Map<String, dynamic> _defaultFlags = {
    _showDebugToolsKey: false, // Never show debug tools by default
    _enableOnboardingKey: true,
    _enableAnalyticsKey: true,
    _enableSecurityNotificationsKey: true,
    _enableUpdatePromptsKey: true,
    _enableAdvancedNavigationKey: true,
    _maintenanceModeKey: false,
    _forceUpdateKey: false,
  };

  /// Initialize feature flag service
  Future<void> initialize(FirebaseAIRemoteConfigService remoteConfigService) async {
    if (_isInitialized) return;

    try {
      _remoteConfigService = remoteConfigService;
      await _remoteConfigService!.initialize();
      
      _isInitialized = true;
      log('✅ Feature flag service initialized');
    } catch (e) {
      log('❌ Failed to initialize feature flag service: $e');
      _isInitialized = true;
    }
  }

  /// Get a feature flag value with environment-aware defaults
  bool _getFeatureFlag(String key, {bool? environmentDefault}) {
    if (!_isInitialized) {
      return environmentDefault ?? (_defaultFlags[key] as bool? ?? false);
    }

    try {
      // First check if remote config is available
      if (_remoteConfigService != null) {
        // For debug tools, apply environment-specific logic
        if (key == _showDebugToolsKey) {
          return _shouldShowDebugTools();
        }
        
        // For other flags, use remote config or default
        return _remoteConfigService!.enableAdvancedFeatures;
      }
      
      // Fallback to environment-aware defaults
      return environmentDefault ?? (_defaultFlags[key] as bool? ?? false);
    } catch (e) {
      log('❌ Failed to get feature flag $key: $e');
      return environmentDefault ?? (_defaultFlags[key] as bool? ?? false);
    }
  }

  /// Environment-aware debug tools visibility
  bool _shouldShowDebugTools() {
    // Debug tools should only be visible in development and staging
    if (EnvironmentDetector.isProduction) {
      return false;
    }
    
    // In development/staging, check remote config
    try {
      if (_remoteConfigService != null) {
        return _remoteConfigService!.enableAdvancedFeatures;
      }
    } catch (e) {
      log('❌ Failed to check debug tools flag: $e');
    }
    
    // Default to true in development, false in staging
    return EnvironmentDetector.isDevelopment;
  }

  /// Check if debug tools should be shown
  bool get showDebugTools => _getFeatureFlag(_showDebugToolsKey);

  /// Check if onboarding should be enabled
  bool get enableOnboarding => _getFeatureFlag(_enableOnboardingKey, environmentDefault: true);

  /// Check if analytics should be enabled
  bool get enableAnalytics => _getFeatureFlag(_enableAnalyticsKey, environmentDefault: true);

  /// Check if security notifications should be enabled
  bool get enableSecurityNotifications => _getFeatureFlag(_enableSecurityNotificationsKey, environmentDefault: true);

  /// Check if update prompts should be enabled
  bool get enableUpdatePrompts => _getFeatureFlag(_enableUpdatePromptsKey, environmentDefault: true);

  /// Check if advanced navigation should be enabled
  bool get enableAdvancedNavigation => _getFeatureFlag(_enableAdvancedNavigationKey, environmentDefault: true);

  /// Check if app is in maintenance mode
  bool get maintenanceMode => _getFeatureFlag(_maintenanceModeKey, environmentDefault: false);

  /// Check if force update is required
  bool get forceUpdate => _getFeatureFlag(_forceUpdateKey, environmentDefault: false);

  /// Refresh feature flags from remote config
  Future<void> refresh() async {
    if (!_isInitialized || _remoteConfigService == null) return;

    try {
      await _remoteConfigService!.refresh();
      log('✅ Feature flags refreshed');
    } catch (e) {
      log('❌ Failed to refresh feature flags: $e');
    }
  }

  /// Get all feature flags for debugging
  Map<String, dynamic> getAllFlags() {
    return {
      'showDebugTools': showDebugTools,
      'enableOnboarding': enableOnboarding,
      'enableAnalytics': enableAnalytics,
      'enableSecurityNotifications': enableSecurityNotifications,
      'enableUpdatePrompts': enableUpdatePrompts,
      'enableAdvancedNavigation': enableAdvancedNavigation,
      'maintenanceMode': maintenanceMode,
      'forceUpdate': forceUpdate,
      'environment': EnvironmentDetector.environmentString,
      'isProduction': EnvironmentDetector.isProduction,
      'isDevelopment': EnvironmentDetector.isDevelopment,
      'isStaging': EnvironmentDetector.isStaging,
    };
  }

  /// Check if a feature should be enabled based on environment
  bool isFeatureEnabledForEnvironment(String featureName) {
    switch (featureName.toLowerCase()) {
      case 'debug_tools':
        return showDebugTools;
      case 'onboarding':
        return enableOnboarding;
      case 'analytics':
        return enableAnalytics;
      case 'security_notifications':
        return enableSecurityNotifications;
      case 'update_prompts':
        return enableUpdatePrompts;
      case 'advanced_navigation':
        return enableAdvancedNavigation;
      default:
        return false;
    }
  }
}
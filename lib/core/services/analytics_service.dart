import 'dart:developer';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:revision/core/config/environment_detector.dart';

/// Analytics service that tracks user behavior and app usage
///
/// This service integrates with Firebase Analytics to provide insights
/// into user behavior, feature usage, and app performance.
/// Analytics are only enabled in production and staging environments.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._();
  factory AnalyticsService() => _instance;
  AnalyticsService._();

  FirebaseAnalytics? _analytics;
  bool _isInitialized = false;
  bool _isEnabled = false;

  /// Initialize analytics service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Only enable analytics in production and staging
      _isEnabled = EnvironmentDetector.isProduction || EnvironmentDetector.isStaging;
      
      if (_isEnabled) {
        _analytics = FirebaseAnalytics.instance;
        await _analytics!.setAnalyticsCollectionEnabled(true);
        
        // Set user properties
        await _analytics!.setUserProperty(
          name: 'environment',
          value: EnvironmentDetector.environmentString,
        );
        
        log('✅ Analytics service initialized and enabled');
      } else {
        log('ℹ️ Analytics service disabled in development environment');
      }
      
      _isInitialized = true;
    } catch (e) {
      log('❌ Failed to initialize analytics service: $e');
      _isEnabled = false;
      _isInitialized = true;
    }
  }

  /// Track page view events
  Future<void> trackPageView(String pageName) async {
    if (!_isEnabled || _analytics == null) return;

    try {
      await _analytics!.logScreenView(screenName: pageName);
      log('📊 Page view tracked: $pageName');
    } catch (e) {
      log('❌ Failed to track page view: $e');
    }
  }

  /// Track button/action events
  Future<void> trackAction(String action, {Map<String, dynamic>? parameters}) async {
    if (!_isEnabled || _analytics == null) return;

    try {
      await _analytics!.logEvent(
        name: action,
        parameters: parameters,
      );
      log('📊 Action tracked: $action');
    } catch (e) {
      log('❌ Failed to track action: $e');
    }
  }

  /// Track user login events
  Future<void> trackLogin(String method) async {
    if (!_isEnabled || _analytics == null) return;

    try {
      await _analytics!.logLogin(loginMethod: method);
      log('📊 Login tracked: $method');
    } catch (e) {
      log('❌ Failed to track login: $e');
    }
  }

  /// Track user signup events
  Future<void> trackSignup(String method) async {
    if (!_isEnabled || _analytics == null) return;

    try {
      await _analytics!.logSignUp(signUpMethod: method);
      log('📊 Signup tracked: $method');
    } catch (e) {
      log('❌ Failed to track signup: $e');
    }
  }

  /// Track feature usage
  Future<void> trackFeatureUsage(String feature, {Map<String, dynamic>? parameters}) async {
    if (!_isEnabled || _analytics == null) return;

    try {
      await _analytics!.logEvent(
        name: 'feature_used',
        parameters: {
          'feature_name': feature,
          ...?parameters,
        },
      );
      log('📊 Feature usage tracked: $feature');
    } catch (e) {
      log('❌ Failed to track feature usage: $e');
    }
  }

  /// Track errors
  Future<void> trackError(String error, {String? context}) async {
    if (!_isEnabled || _analytics == null) return;

    try {
      await _analytics!.logEvent(
        name: 'app_error',
        parameters: {
          'error_message': error,
          if (context != null) 'context': context,
        },
      );
      log('📊 Error tracked: $error');
    } catch (e) {
      log('❌ Failed to track error: $e');
    }
  }

  /// Track app launch
  Future<void> trackAppLaunch() async {
    if (!_isEnabled || _analytics == null) return;

    try {
      await _analytics!.logAppOpen();
      log('📊 App launch tracked');
    } catch (e) {
      log('❌ Failed to track app launch: $e');
    }
  }

  /// Track user onboarding completion
  Future<void> trackOnboardingCompleted(String step) async {
    if (!_isEnabled || _analytics == null) return;

    try {
      await _analytics!.logEvent(
        name: 'onboarding_completed',
        parameters: {
          'step': step,
        },
      );
      log('📊 Onboarding completion tracked: $step');
    } catch (e) {
      log('❌ Failed to track onboarding completion: $e');
    }
  }

  /// Set user properties
  Future<void> setUserProperty(String name, String value) async {
    if (!_isEnabled || _analytics == null) return;

    try {
      await _analytics!.setUserProperty(name: name, value: value);
      log('📊 User property set: $name = $value');
    } catch (e) {
      log('❌ Failed to set user property: $e');
    }
  }

  /// Get analytics instance for custom events
  FirebaseAnalytics? get analytics => _isEnabled ? _analytics : null;

  /// Check if analytics is enabled
  bool get isEnabled => _isEnabled;
}
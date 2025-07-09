import 'dart:developer';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:revision/core/config/environment_detector.dart';

/// Analytics service that tracks user behavior and app usage.
/// Integrates with Firebase Analytics to provide insights into user behavior,
/// feature usage, and app performance. Analytics are only enabled in
/// production and staging environments.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService _instance = AnalyticsService._();
  factory AnalyticsService() => _instance;

  FirebaseAnalytics? _analytics;
  bool _isInitialized = false;
  bool _isEnabled = false;

  /// Initializes analytics service (should be called once at app start).
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      _isEnabled = EnvironmentDetector.isProduction || EnvironmentDetector.isStaging;
      if (_isEnabled) {
        _analytics = FirebaseAnalytics.instance;
        await _analytics!.setAnalyticsCollectionEnabled(true);
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

  /// Tracks when the app is launched.
  Future<void> trackAppLaunch() async {
    if (!_isEnabled || _analytics == null) return;
    try {
      await _analytics!.logAppOpen();
      log('📊 App launch tracked');
    } catch (e) {
      log('❌ Failed to track app launch: $e');
    }
  }

  /// Tracks a page or screen view.
  Future<void> trackPageView(String pageName, {Map<String, dynamic>? parameters}) async {
    if (!_isEnabled || _analytics == null) return;
    try {
      await _analytics!.logScreenView(screenName: pageName);
      log('📊 Page view tracked: $pageName');
    } catch (e) {
      log('❌ Failed to track page view: $e');
    }
  }

  /// Tracks a generic user action.
  Future<void> trackAction(String action, {Map<String, dynamic>? parameters}) async {
    if (!_isEnabled || _analytics == null) return;
    try {
      await _analytics!.logEvent(
        name: action,
        parameters: {
          'timestamp': DateTime.now().toIso8601String(),
          ...?parameters,
        },
      );
      log('📊 Action tracked: $action');
    } catch (e) {
      log('❌ Failed to track action: $e');
    }
  }

  /// Tracks a navigation event.
  Future<void> trackNavigation(String from, String to, {Map<String, dynamic>? parameters}) async {
    if (!_isEnabled || _analytics == null) return;
    try {
      await _analytics!.logEvent(
        name: 'navigation',
        parameters: {
          'from': from,
          'to': to,
          'timestamp': DateTime.now().toIso8601String(),
          ...?parameters,
        },
      );
      log('📊 Navigation tracked: $from -> $to');
    } catch (e) {
      log('❌ Failed to track navigation: $e');
    }
  }

  /// Tracks user login events.
  Future<void> trackLogin(String method) async {
    if (!_isEnabled || _analytics == null) return;
    try {
      await _analytics!.logLogin(loginMethod: method);
      log('📊 Login tracked: $method');
    } catch (e) {
      log('❌ Failed to track login: $e');
    }
  }

  /// Tracks user signup events.
  Future<void> trackSignup(String method) async {
    if (!_isEnabled || _analytics == null) return;
    try {
      await _analytics!.logSignUp(signUpMethod: method);
      log('📊 Signup tracked: $method');
    } catch (e) {
      log('❌ Failed to track signup: $e');
    }
  }

  /// Tracks feature usage.
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

  /// Tracks errors in the app.
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

  /// Tracks completion of onboarding steps.
  Future<void> trackOnboardingCompleted(String step) async {
    if (!_isEnabled || _analytics == null) return;
    try {
      await _analytics!.logEvent(
        name: 'onboarding_completed',
        parameters: {'step': step},
      );
      log('📊 Onboarding completion tracked: $step');
    } catch (e) {
      log('❌ Failed to track onboarding completion: $e');
    }
  }

  /// Sets a user property.
  Future<void> setUserProperty(String name, String value) async {
    if (!_isEnabled || _analytics == null) return;
    try {
      await _analytics!.setUserProperty(name: name, value: value);
      log('📊 User property set: $name = $value');
    } catch (e) {
      log('❌ Failed to set user property: $e');
    }
  }

  /// Expose analytics instance for advanced use.
  FirebaseAnalytics? get analytics => _isEnabled ? _analytics : null;

  /// Returns if analytics is enabled.
  bool get isEnabled => _isEnabled;
}
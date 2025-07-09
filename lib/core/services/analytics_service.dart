import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:revision/core/services/logging_service.dart';

/// Analytics service for tracking user actions and events
class AnalyticsService {
  const AnalyticsService._();

  static const AnalyticsService _instance = AnalyticsService._();
  static AnalyticsService get instance => _instance;

  static FirebaseAnalytics? _analytics;
  static FirebaseAnalyticsObserver? _observer;

  /// Initialize the analytics service
  static Future<void> initialize() async {
    if (kDebugMode) {
      LoggingService.instance.debug('Analytics: Initializing...');
    }
    
    try {
      _analytics = FirebaseAnalytics.instance;
      _observer = FirebaseAnalyticsObserver(analytics: _analytics!);
      
      // Set analytics collection enabled based on environment
      await _analytics!.setAnalyticsCollectionEnabled(!kDebugMode);
      
      LoggingService.instance.info('Analytics: Initialized successfully');
    } catch (e) {
      LoggingService.instance.error(
        'Analytics: Failed to initialize', 
        error: e,
      );
    }
  }

  /// Get the Firebase Analytics observer for navigation
  static FirebaseAnalyticsObserver? get observer => _observer;

  /// Track user action events
  Future<void> trackUserAction(String action, {Map<String, dynamic>? parameters}) async {
    if (_analytics == null) return;

    try {
      await _analytics!.logEvent(
        name: 'user_action',
        parameters: {
          'action': action,
          'timestamp': DateTime.now().toIso8601String(),
          ...?parameters,
        },
      );
      
      LoggingService.instance.userAction(action, data: parameters);
    } catch (e) {
      LoggingService.instance.error(
        'Analytics: Failed to track user action: $action',
        error: e,
      );
    }
  }

  /// Track screen view events
  Future<void> trackScreenView(String screenName, {Map<String, dynamic>? parameters}) async {
    if (_analytics == null) return;

    try {
      await _analytics!.logScreenView(
        screenName: screenName,
        parameters: parameters,
      );
      
      LoggingService.instance.info('Analytics: Screen view tracked: $screenName');
    } catch (e) {
      LoggingService.instance.error(
        'Analytics: Failed to track screen view: $screenName',
        error: e,
      );
    }
  }

  /// Track navigation events
  Future<void> trackNavigation(String from, String to, {Map<String, dynamic>? parameters}) async {
    if (_analytics == null) return;

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
      
      LoggingService.instance.info('Analytics: Navigation tracked: $from -> $to');
    } catch (e) {
      LoggingService.instance.error(
        'Analytics: Failed to track navigation: $from -> $to',
        error: e,
      );
    }
  }

  /// Track authentication events
  Future<void> trackAuthAction(String action, {Map<String, dynamic>? parameters}) async {
    if (_analytics == null) return;

    try {
      await _analytics!.logEvent(
        name: 'auth_action',
        parameters: {
          'action': action,
          'timestamp': DateTime.now().toIso8601String(),
          ...?parameters,
        },
      );
      
      LoggingService.instance.info('Analytics: Auth action tracked: $action');
    } catch (e) {
      LoggingService.instance.error(
        'Analytics: Failed to track auth action: $action',
        error: e,
      );
    }
  }

  /// Set user properties
  Future<void> setUserProperty(String name, String value) async {
    if (_analytics == null) return;

    try {
      await _analytics!.setUserProperty(name: name, value: value);
      LoggingService.instance.info('Analytics: User property set: $name = $value');
    } catch (e) {
      LoggingService.instance.error(
        'Analytics: Failed to set user property: $name',
        error: e,
      );
    }
  }
}
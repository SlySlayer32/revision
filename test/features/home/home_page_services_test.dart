import 'package:flutter_test/flutter_test.dart';
import 'package:revision/core/config/environment_detector.dart';
import 'package:revision/core/services/analytics_service.dart';
import 'package:revision/core/services/feature_flag_service.dart';
import 'package:revision/core/services/firebase_ai_remote_config_service.dart';
import 'package:revision/core/services/onboarding_service.dart';
import 'package:revision/core/services/security_notification_service.dart';

void main() {
  group('Home Page Services', () {
    test('AnalyticsService initializes correctly', () {
      final analyticsService = AnalyticsService();
      expect(analyticsService, isNotNull);
      expect(analyticsService.isEnabled, isFalse); // Should be false without Firebase
    });

    test('FeatureFlagService initializes correctly', () {
      final featureFlagService = FeatureFlagService();
      expect(featureFlagService, isNotNull);
      
      // Test environment-aware debug tools
      final flags = featureFlagService.getAllFlags();
      expect(flags, isNotNull);
      expect(flags.containsKey('showDebugTools'), isTrue);
      expect(flags.containsKey('environment'), isTrue);
    });

    test('OnboardingService initializes correctly', () {
      final onboardingService = OnboardingService();
      expect(onboardingService, isNotNull);
    });

    test('SecurityNotificationService initializes correctly', () {
      final securityService = SecurityNotificationService();
      expect(securityService, isNotNull);
    });

    test('Environment detection works correctly', () {
      final environment = EnvironmentDetector.currentEnvironment;
      expect(environment, isNotNull);
      expect(EnvironmentDetector.environmentString, isNotEmpty);
    });
  });

  group('Feature Flag Logic', () {
    test('Debug tools are hidden in production', () {
      final featureFlagService = FeatureFlagService();
      
      // Should return false in production regardless of remote config
      if (EnvironmentDetector.isProduction) {
        expect(featureFlagService.showDebugTools, isFalse);
      }
    });

    test('Feature flags have sensible defaults', () {
      final featureFlagService = FeatureFlagService();
      
      // These should be enabled by default
      expect(featureFlagService.enableOnboarding, isTrue);
      expect(featureFlagService.enableAnalytics, isTrue);
      expect(featureFlagService.enableSecurityNotifications, isTrue);
      expect(featureFlagService.enableUpdatePrompts, isTrue);
      expect(featureFlagService.enableAdvancedNavigation, isTrue);
      
      // These should be disabled by default
      expect(featureFlagService.maintenanceMode, isFalse);
      expect(featureFlagService.forceUpdate, isFalse);
    });
  });
}
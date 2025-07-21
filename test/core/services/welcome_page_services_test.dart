import 'package:flutter_test/flutter_test.dart';
import 'package:revision/core/services/analytics_service.dart';
import 'package:revision/core/services/app_info_service.dart';
import 'package:revision/core/services/deep_linking_service.dart';
import 'package:revision/core/services/offline_detection_service.dart';
import 'package:revision/core/constants/environment_config.dart';

void main() {
  // group('AnalyticsService', () {
  //   test('should initialize without errors', () async {
  //     await AnalyticsService.initialize();
  //     expect(AnalyticsService.observer, isNotNull);
  //   });

  //   test('should track user actions', () async {
  //     await AnalyticsService.initialize();
      
  //     // Should not throw
  //     expect(
  //       () => AnalyticsService.instance.trackUserAction('test_action'),
  //       returnsNormally,
  //     );
  //   });

  //   test('should track screen views', () async {
  //     await AnalyticsService.initialize();
      
  //     // Should not throw
  //     expect(
  //       () => AnalyticsService.instance.trackScreenView('test_screen'),
  //       returnsNormally,
  //     );
  //   });
  // });

  group('AppInfoService', () {
    test('should initialize with app info', () async {
      await AppInfoService.initialize();
      
      expect(AppInfoService.instance.appName, isNotEmpty);
      expect(AppInfoService.instance.appVersion, isNotEmpty);
      expect(AppInfoService.instance.buildNumber, isNotEmpty);
    });

    test('should provide security warnings', () async {
      await AppInfoService.initialize();
      
      final warnings = AppInfoService.instance.securityWarnings;
      expect(warnings, isA<List<String>>());
      
      // In development mode, should have at least one warning
      if (AppInfoService.instance.isDevelopment) {
        expect(warnings, isNotEmpty);
      }
    });

    test('should format app info correctly', () async {
      await AppInfoService.initialize();
      
      final formatted = AppInfoService.instance.getFormattedAppInfo();
      expect(formatted, contains('App:'));
      expect(formatted, contains('Version:'));
      expect(formatted, contains('Environment:'));
    });

    test('should detect environment correctly', () async {
      await AppInfoService.initialize();
      
      expect(AppInfoService.instance.environment, isA<Environment>());
      expect(AppInfoService.instance.environmentName, isNotEmpty);
    });
  });

  group('OfflineDetectionService', () {
    // test('should initialize connectivity monitoring', () async {
    //   await OfflineDetectionService.initialize();
      
    //   expect(OfflineDetectionService.instance.isOnline, isA<bool>());
    //   expect(OfflineDetectionService.instance.isOffline, equals(!OfflineDetectionService.instance.isOnline));
    // });

    // test('should provide connectivity stream', () async {
    //   await OfflineDetectionService.initialize();
      
    //   final stream = OfflineDetectionService.instance.connectivityStream;
    //   expect(stream, isA<Stream<bool>>());
    // });

    // test('should force connectivity check', () async {
    //   await OfflineDetectionService.initialize();
      
    //   // Should not throw
    //   expect(
    //     () => OfflineDetectionService.instance.forceCheck(),
    //     returnsNormally,
    //   );
    // });

    // test('should provide connectivity info', () async {
    //   await OfflineDetectionService.initialize();
      
    //   final info = OfflineDetectionService.instance.getConnectivityInfo();
    //   expect(info, contains('isOnline'));
    //   expect(info, contains('isOffline'));
    //   expect(info, contains('lastChecked'));
    // });
  });

  group('DeepLinkingService', () {
    test('should initialize deep linking', () async {
      await DeepLinkingService.initialize();
      
      // Should not throw
      expect(
        () => DeepLinkingService.instance.linkStream,
        returnsNormally,
      );
    });

    test('should create deep links', () async {
      await DeepLinkingService.initialize();
      
      final link = DeepLinkingService.instance.createDeepLink('/welcome');
      expect(link, isNotEmpty);
      expect(link, contains('/welcome'));
    });

    test('should create deep links with parameters', () async {
      await DeepLinkingService.initialize();
      
      final link = DeepLinkingService.instance.createDeepLink(
        '/welcome', 
        parameters: {'param': 'value'},
      );
      expect(link, contains('param=value'));
    });

    test('should handle deep links programmatically', () async {
      await DeepLinkingService.initialize();
      
      // Should not throw
      expect(
        () => DeepLinkingService.instance.handleDeepLink('https://revision.app/welcome'),
        returnsNormally,
      );
    });
  });

  group('DeepLinkData', () {
    test('should create deep link data correctly', () {
      const data = DeepLinkData(
        originalLink: 'https://revision.app/welcome',
        route: '/welcome',
        parameters: {'param': 'value'},
      );
      
      expect(data.originalLink, equals('https://revision.app/welcome'));
      expect(data.route, equals('/welcome'));
      expect(data.parameters, equals({'param': 'value'}));
    });

    test('should have proper toString implementation', () {
      const data = DeepLinkData(
        originalLink: 'https://revision.app/welcome',
        route: '/welcome',
        parameters: {'param': 'value'},
      );
      
      final string = data.toString();
      expect(string, contains('DeepLinkData'));
      expect(string, contains('originalLink'));
      expect(string, contains('route'));
      expect(string, contains('parameters'));
    });
  });
}
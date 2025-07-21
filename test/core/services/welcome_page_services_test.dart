import 'package:flutter_test/flutter_test.dart';
import 'package:revision/core/services/analytics_service.dart';
import 'package:revision/core/services/app_info_service.dart';
import 'package:revision/core/services/deep_linking_service.dart';
import 'package:revision/core/services/offline_detection_service.dart';
import 'package:revision/core/constants/environment_config.dart';

void main() {
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

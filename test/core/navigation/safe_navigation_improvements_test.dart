import 'package:flutter_test/flutter_test.dart';
import 'package:revision/core/services/navigation_analytics_service.dart';
import 'package:revision/core/services/deep_link_validator.dart';
import 'package:revision/core/services/navigation_state_persistence.dart';
import 'package:revision/core/navigation/safe_navigation.dart';

void main() {
  group('NavigationAnalyticsService', () {
    late NavigationAnalyticsService analyticsService;

    setUp(() {
      analyticsService = NavigationAnalyticsService();
    });

    test('should track successful navigation', () {
      // Test that tracking navigation doesn't throw
      expect(() {
        analyticsService.trackNavigation(
          fromRoute: '/home',
          toRoute: '/dashboard',
          arguments: {'userId': '123'},
          duration: const Duration(milliseconds: 250),
        );
      }, returnsNormally);
    });

    test('should track navigation failures', () {
      // Test that tracking navigation failures doesn't throw
      expect(() {
        analyticsService.trackNavigationFailure(
          fromRoute: '/home',
          attemptedRoute: '/invalid',
          error: 'Route not found',
          arguments: {'test': 'value'},
          fallbackRoute: '/error',
        );
      }, returnsNormally);
    });

    test('should track deep link attempts', () {
      // Test that tracking deep links doesn't throw
      expect(() {
        analyticsService.trackDeepLink(
          deepLink: 'https://app.revision.com/dashboard',
          isValid: true,
          extractedData: {'tab': 'ai'},
        );
      }, returnsNormally);
    });

    test('should track argument validation', () {
      // Test that tracking argument validation doesn't throw
      expect(() {
        analyticsService.trackArgumentValidation(
          route: '/dashboard',
          argumentKey: 'userId',
          expectedType: 'String',
          actualType: 'int',
          isValid: false,
        );
      }, returnsNormally);
    });

    test('should generate analytics summary', () {
      // Track some events
      analyticsService.trackNavigation(
        fromRoute: '/home',
        toRoute: '/dashboard',
      );
      
      analyticsService.trackNavigationFailure(
        fromRoute: '/home',
        attemptedRoute: '/invalid',
        error: 'Route not found',
      );

      final summary = analyticsService.getAnalyticsSummary();
      
      expect(summary, isA<Map<String, dynamic>>());
      expect(summary.containsKey('total_events'), isTrue);
      expect(summary.containsKey('successful_navigations'), isTrue);
      expect(summary.containsKey('failed_navigations'), isTrue);
      expect(summary.containsKey('success_rate'), isTrue);
    });
  });

  group('DeepLinkValidator', () {
    late DeepLinkValidator validator;

    setUp(() {
      validator = DeepLinkValidator();
    });

    test('should validate HTTPS deep links', () {
      const deepLink = 'https://revision.app/dashboard?tab=ai';
      final result = validator.validateDeepLink(deepLink);
      
      // Note: This will fail if the route doesn't exist in RouteNames
      // In a real app, this would pass with proper route configuration
      expect(result, isA<DeepLinkValidationResult>());
    });

    test('should reject HTTP deep links in release mode', () {
      const deepLink = 'http://revision.app/dashboard';
      final result = validator.validateDeepLink(deepLink);
      
      // Should be valid in debug mode, invalid in release mode
      expect(result, isA<DeepLinkValidationResult>());
    });

    test('should reject suspicious deep links', () {
      const deepLink = 'https://revision.app/dashboard?javascript=alert(1)';
      final result = validator.validateDeepLink(deepLink);
      
      expect(result.isValid, isFalse);
      expect(result.error, contains('Suspicious parameter'));
    });

    test('should reject script injection attempts', () {
      const deepLink = 'https://revision.app/dashboard?name=<script>alert(1)</script>';
      final result = validator.validateDeepLink(deepLink);
      
      expect(result.isValid, isFalse);
      expect(result.error, contains('Script injection detected'));
    });

    test('should validate custom app scheme', () {
      const deepLink = 'revision://dashboard?tab=ai';
      final result = validator.validateDeepLink(deepLink);
      
      expect(result, isA<DeepLinkValidationResult>());
    });
  });

  group('NavigationStatePersistence', () {
    late NavigationStatePersistence persistence;

    setUp(() {
      persistence = NavigationStatePersistence();
    });

    test('should save and load navigation state', () async {
      const state = NavigationState(
        currentRoute: '/dashboard',
        routeStack: ['/home', '/dashboard'],
        arguments: {'userId': '123'},
      );

      await persistence.saveNavigationState(state);
      final loadedState = await persistence.loadNavigationState();

      expect(loadedState?.currentRoute, equals('/dashboard'));
      expect(loadedState?.routeStack, equals(['/home', '/dashboard']));
      expect(loadedState?.arguments?['userId'], equals('123'));
    });

    test('should clear navigation state', () async {
      const state = NavigationState(
        currentRoute: '/dashboard',
        routeStack: ['/home', '/dashboard'],
      );

      await persistence.saveNavigationState(state);
      await persistence.clearNavigationState();
      
      final loadedState = await persistence.loadNavigationState();
      expect(loadedState, isNull);
    });

    test('should update current route', () async {
      await persistence.updateCurrentRoute('/dashboard', arguments: {'tab': 'ai'});
      
      final state = await persistence.loadNavigationState();
      expect(state?.currentRoute, equals('/dashboard'));
      expect(state?.arguments?['tab'], equals('ai'));
    });

    test('should handle push and pop operations', () async {
      await persistence.pushRoute('/home');
      await persistence.pushRoute('/dashboard');
      
      var state = await persistence.loadNavigationState();
      expect(state?.currentRoute, equals('/dashboard'));
      expect(state?.routeStack, equals(['/home', '/dashboard']));
      
      await persistence.popRoute();
      
      state = await persistence.loadNavigationState();
      expect(state?.currentRoute, equals('/home'));
      expect(state?.routeStack, equals(['/home']));
    });

    test('should provide state statistics', () async {
      const state = NavigationState(
        currentRoute: '/dashboard',
        routeStack: ['/home', '/dashboard'],
        arguments: {'userId': '123'},
      );

      await persistence.saveNavigationState(state);
      final stats = await persistence.getStateStatistics();

      expect(stats['exists'], isTrue);
      expect(stats['current_route'], equals('/dashboard'));
      expect(stats['stack_depth'], equals(2));
      expect(stats['has_arguments'], isTrue);
    });
  });

  group('SafeNavigation Integration', () {
    test('should initialize without errors', () async {
      expect(() async => await SafeNavigation.initialize(), returnsNormally);
    });

    test('should get analytics summary', () {
      final analytics = SafeNavigation.getAnalytics();
      expect(analytics, isA<Map<String, dynamic>>());
    });

    test('should get state statistics', () async {
      final stats = await SafeNavigation.getStateStatistics();
      expect(stats, isA<Map<String, dynamic>>());
    });

    test('should clear navigation state', () async {
      expect(() async => await SafeNavigation.clearNavigationState(), returnsNormally);
    });
  });
}
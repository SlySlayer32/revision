import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:revision/core/navigation/route_names.dart';
import 'package:revision/core/services/navigation_analytics_service.dart';
import 'package:revision/core/services/deep_link_validator.dart';
import 'package:revision/core/services/navigation_state_persistence.dart';
import 'package:revision/core/utils/enhanced_logger.dart';

/// Safe navigation utilities that prevent null value errors
///
/// This class implements all the best practices for null-safe navigation
/// as outlined in Flutter's null safety guidelines.
class SafeNavigation {
  SafeNavigation._();

  static final EnhancedLogger _logger = EnhancedLogger();
  static final NavigationAnalyticsService _analytics = NavigationAnalyticsService();
  static final DeepLinkValidator _deepLinkValidator = DeepLinkValidator();
  static final NavigationStatePersistence _statePersistence = NavigationStatePersistence();

  /// Initialize the safe navigation system
  static Future<void> initialize() async {
    _logger.info('Initializing SafeNavigation system', operation: 'SAFE_NAVIGATION');
    
    // Configure logger for production
    _logger.configure(
      minLevel: kDebugMode ? LogLevel.debug : LogLevel.info,
      enableConsole: kDebugMode,
      enableFile: true,
      enableMonitoring: true,
    );
  }

  /// Safely extracts arguments from route with type checking and null safety
  static T? getArguments<T>(BuildContext context) {
    try {
      final route = ModalRoute.of(context);
      if (route == null) {
        _logger.warning(
          'No ModalRoute found in context',
          operation: 'GET_ARGUMENTS',
        );
        return null;
      }

      final settings = route.settings;
      final arguments = settings.arguments;
      if (arguments == null) {
        _logger.debug(
          'No arguments found for route ${settings.name}',
          operation: 'GET_ARGUMENTS',
          context: {'route': settings.name},
        );
        return null;
      }

      // Safe type checking and casting
      if (arguments is T) {
        _logger.debug(
          'Successfully extracted arguments of type $T',
          operation: 'GET_ARGUMENTS',
          context: {'route': settings.name, 'type': T.toString()},
        );
        return arguments as T;
      }

      _logger.warning(
        'Argument type mismatch',
        operation: 'GET_ARGUMENTS',
        context: {
          'route': settings.name,
          'expected_type': T.toString(),
          'actual_type': arguments.runtimeType.toString(),
        },
      );
      
      // Track validation issue
      _analytics.trackArgumentValidation(
        route: settings.name ?? 'unknown',
        argumentKey: 'root',
        expectedType: T.toString(),
        actualType: arguments.runtimeType.toString(),
        isValid: false,
      );
      
      return null;
    } catch (e, stackTrace) {
      _logger.error(
        'Error extracting arguments: $e',
        operation: 'GET_ARGUMENTS',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Safely extracts Map arguments with specific key checking
  static Map<String, dynamic>? getMapArguments(BuildContext context) {
    final args = getArguments<Map<String, dynamic>>(context);
    if (args != null) {
      return Map<String, dynamic>.from(args);
    }

    // Try to extract as Map<String, Object?> and convert safely
    final objectArgs = getArguments<Map<String, Object?>>(context);
    if (objectArgs != null) {
      return Map<String, dynamic>.from(objectArgs);
    }

    // Try to extract as Object and cast
    final rawArgs = getArguments<Object>(context);
    if (rawArgs is Map) {
      try {
        return Map<String, dynamic>.from(rawArgs);
      } catch (e) {
        _logger.warning(
          'Failed to convert Map to Map<String, dynamic>: $e',
          operation: 'GET_MAP_ARGUMENTS',
          error: e,
        );
      }
    }

    return null;
  }

  /// Safely gets a specific value from map arguments
  static T? getArgumentValue<T>(BuildContext context, String key) {
    final args = getMapArguments(context);
    if (args == null) return null;

    final value = args[key];
    if (value is T) {
      return value;
    }

    if (value != null) {
      final currentRoute = getCurrentRouteName(context) ?? 'unknown';
      
      _logger.warning(
        'Argument type mismatch for key "$key"',
        operation: 'GET_ARGUMENT_VALUE',
        context: {
          'key': key,
          'route': currentRoute,
          'expected_type': T.toString(),
          'actual_type': value.runtimeType.toString(),
        },
      );
      
      // Track validation issue
      _analytics.trackArgumentValidation(
        route: currentRoute,
        argumentKey: key,
        expectedType: T.toString(),
        actualType: value.runtimeType.toString(),
        isValid: false,
      );
    }

    return null;
  }

  /// Gets current route name safely
  static String? getCurrentRouteName(BuildContext context) {
    try {
      final route = ModalRoute.of(context);
      final name = route?.settings.name;

      if (name != null) {
        _logger.debug(
          'Current route: $name',
          operation: 'GET_CURRENT_ROUTE',
          context: {'route': name},
        );
      }

      return name;
    } catch (e) {
      _logger.error(
        'Error getting route name: $e',
        operation: 'GET_CURRENT_ROUTE',
        error: e,
      );
      return null;
    }
  }

  /// Checks if current route matches the given name
  static bool isCurrentRoute(BuildContext context, String routeName) {
    return getCurrentRouteName(context) == routeName;
  }

  /// Safely pushes a named route with proper error handling
  static Future<T?> pushNamed<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    final fromRoute = getCurrentRouteName(context) ?? 'unknown';
    final startTime = DateTime.now();
    
    try {
      if (!RouteNames.isValidRoute(routeName)) {
        _logger.warning(
          'Invalid route name: $routeName',
          operation: 'PUSH_NAMED',
          context: {'route': routeName, 'from_route': fromRoute},
        );
        
        // Track navigation failure
        _analytics.trackNavigationFailure(
          fromRoute: fromRoute,
          attemptedRoute: routeName,
          error: 'Invalid route name',
          arguments: arguments is Map<String, dynamic> ? arguments : null,
          fallbackRoute: RouteNames.error,
        );
        
        // Navigate to error page or home instead
        return pushNamed<T>(
          context,
          RouteNames.error,
          arguments: {'error': 'Invalid route: $routeName'},
        );
      }

      _logger.info(
        'Navigating to $routeName',
        operation: 'PUSH_NAMED',
        context: {
          'route': routeName,
          'from_route': fromRoute,
          'has_arguments': arguments != null,
        },
      );

      // Persist navigation state
      await _statePersistence.pushRoute(
        routeName,
        arguments: arguments is Map<String, dynamic> ? arguments : null,
      );

      final result = await Navigator.of(
        context,
      ).pushNamed<T>(routeName, arguments: arguments);

      final duration = DateTime.now().difference(startTime);
      
      // Track successful navigation
      _analytics.trackNavigation(
        fromRoute: fromRoute,
        toRoute: routeName,
        arguments: arguments is Map<String, dynamic> ? arguments : null,
        duration: duration,
      );

      return result;
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      
      _logger.error(
        'Navigation error: $e',
        operation: 'PUSH_NAMED',
        error: e,
        stackTrace: stackTrace,
        context: {
          'route': routeName,
          'from_route': fromRoute,
          'duration_ms': duration.inMilliseconds,
        },
      );

      // Track navigation failure
      _analytics.trackNavigationFailure(
        fromRoute: fromRoute,
        attemptedRoute: routeName,
        error: e.toString(),
        arguments: arguments is Map<String, dynamic> ? arguments : null,
        fallbackRoute: RouteNames.error,
      );

      // Fallback navigation to safe route
      try {
        return await Navigator.of(context).pushNamed<T>(
          RouteNames.error,
          arguments: {'error': 'Navigation failed: $e'},
        );
      } catch (fallbackError) {
        _logger.error(
          'Fallback navigation also failed: $fallbackError',
          operation: 'PUSH_NAMED_FALLBACK',
          error: fallbackError,
        );
        return null;
      }
    }
  }

  /// Safely handles deep link navigation with validation
  static Future<T?> handleDeepLink<T extends Object?>(
    BuildContext context,
    String deepLink,
  ) async {
    final fromRoute = getCurrentRouteName(context) ?? 'unknown';
    
    try {
      // Validate the deep link
      final validationResult = _deepLinkValidator.validateDeepLink(deepLink);
      
      // Track deep link attempt
      _analytics.trackDeepLink(
        deepLink: deepLink,
        isValid: validationResult.isValid,
        error: validationResult.error,
        extractedData: validationResult.arguments,
      );
      
      if (!validationResult.isValid) {
        _logger.warning(
          'Invalid deep link: ${validationResult.error}',
          operation: 'HANDLE_DEEP_LINK',
          context: {
            'deep_link': deepLink,
            'error': validationResult.error,
            'from_route': fromRoute,
          },
        );
        
        // Navigate to error page
        return pushNamed<T>(
          context,
          RouteNames.error,
          arguments: {'error': 'Invalid deep link: ${validationResult.error}'},
        );
      }

      _logger.info(
        'Processing valid deep link',
        operation: 'HANDLE_DEEP_LINK',
        context: {
          'deep_link': deepLink,
          'target_route': validationResult.routePath,
          'from_route': fromRoute,
        },
      );

      // Navigate to the validated route
      return pushNamed<T>(
        context,
        validationResult.routePath!,
        arguments: validationResult.arguments,
      );
      
    } catch (e, stackTrace) {
      _logger.error(
        'Deep link processing error: $e',
        operation: 'HANDLE_DEEP_LINK',
        error: e,
        stackTrace: stackTrace,
        context: {
          'deep_link': deepLink,
          'from_route': fromRoute,
        },
      );
      
      // Track the failure
      _analytics.trackDeepLink(
        deepLink: deepLink,
        isValid: false,
        error: e.toString(),
      );
      
      // Navigate to error page
      return pushNamed<T>(
        context,
        RouteNames.error,
        arguments: {'error': 'Deep link processing failed: $e'},
      );
    }
  }
  /// Safely pushes a route with proper error handling
  static Future<T?> push<T extends Object?>(
    BuildContext context,
    Route<T> route,
  ) async {
    final fromRoute = getCurrentRouteName(context) ?? 'unknown';
    final routeName = route.settings.name ?? 'unnamed';
    
    try {
      _logger.info(
        'Pushing route: $routeName',
        operation: 'PUSH_ROUTE',
        context: {
          'route': routeName,
          'from_route': fromRoute,
        },
      );

      // Persist navigation state
      await _statePersistence.pushRoute(routeName);

      final result = await Navigator.of(context).push<T>(route);
      
      // Track successful navigation
      _analytics.trackNavigation(
        fromRoute: fromRoute,
        toRoute: routeName,
        arguments: route.settings.arguments is Map<String, dynamic> 
          ? route.settings.arguments as Map<String, dynamic>
          : null,
      );
      
      return result;
    } catch (e, stackTrace) {
      _logger.error(
        'Push route error: $e',
        operation: 'PUSH_ROUTE',
        error: e,
        stackTrace: stackTrace,
        context: {
          'route': routeName,
          'from_route': fromRoute,
        },
      );
      
      // Track navigation failure
      _analytics.trackNavigationFailure(
        fromRoute: fromRoute,
        attemptedRoute: routeName,
        error: e.toString(),
      );
      
      return null;
    }
  }

  /// Safely replaces current route
  static Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
    BuildContext context,
    Route<T> newRoute, {
    TO? result,
  }) async {
    final fromRoute = getCurrentRouteName(context) ?? 'unknown';
    final routeName = newRoute.settings.name ?? 'unnamed';
    
    try {
      _logger.info(
        'Replacing with route: $routeName',
        operation: 'PUSH_REPLACEMENT',
        context: {
          'route': routeName,
          'from_route': fromRoute,
        },
      );

      // Update navigation state
      await _statePersistence.updateCurrentRoute(
        routeName,
        arguments: newRoute.settings.arguments is Map<String, dynamic> 
          ? newRoute.settings.arguments as Map<String, dynamic>
          : null,
      );

      final finalResult = await Navigator.of(
        context,
      ).pushReplacement<T, TO>(newRoute, result: result);
      
      // Track successful navigation
      _analytics.trackNavigation(
        fromRoute: fromRoute,
        toRoute: routeName,
        arguments: newRoute.settings.arguments is Map<String, dynamic> 
          ? newRoute.settings.arguments as Map<String, dynamic>
          : null,
      );
      
      return finalResult;
    } catch (e, stackTrace) {
      _logger.error(
        'Push replacement error: $e',
        operation: 'PUSH_REPLACEMENT',
        error: e,
        stackTrace: stackTrace,
        context: {
          'route': routeName,
          'from_route': fromRoute,
        },
      );
      
      // Track navigation failure
      _analytics.trackNavigationFailure(
        fromRoute: fromRoute,
        attemptedRoute: routeName,
        error: e.toString(),
      );
      
      return null;
    }
  }

  /// Safely pops route with error handling
  static void pop<T extends Object?>(BuildContext context, [T? result]) {
    try {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop<T>(result);
        
        // Update navigation state
        _statePersistence.popRoute();

        _logger.debug(
          'Popped route',
          operation: 'POP_ROUTE',
        );
      } else {
        _logger.warning(
          'Cannot pop - no routes to pop',
          operation: 'POP_ROUTE',
        );
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Pop error: $e',
        operation: 'POP_ROUTE',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Safely pops until a specific route
  static void popUntil(BuildContext context, String routeName) {
    try {
      Navigator.of(context).popUntil((route) {
        final currentName = route.settings.name;
        return currentName == routeName;
      });

      // Update navigation state
      _statePersistence.updateCurrentRoute(routeName);

      _logger.debug(
        'Popped until route: $routeName',
        operation: 'POP_UNTIL',
        context: {'target_route': routeName},
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Pop until error: $e',
        operation: 'POP_UNTIL',
        error: e,
        stackTrace: stackTrace,
        context: {'target_route': routeName},
      );
    }
  }

  /// Validates route arguments before navigation
  static bool validateArguments(Object? arguments, Type expectedType) {
    if (arguments == null) {
      return expectedType == Null;
    }

    final isValid = arguments.runtimeType == expectedType;

    if (!isValid) {
      _logger.warning(
        'Argument validation failed',
        operation: 'VALIDATE_ARGUMENTS',
        context: {
          'expected_type': expectedType.toString(),
          'actual_type': arguments.runtimeType.toString(),
        },
      );
    }

    return isValid;
  }

  /// Restores navigation state after app restart
  static Future<void> restoreNavigationState(BuildContext context) async {
    try {
      final savedState = await _statePersistence.loadNavigationState();
      if (savedState != null) {
        _logger.info(
          'Restoring navigation state',
          operation: 'RESTORE_STATE',
          context: {
            'current_route': savedState.currentRoute,
            'stack_depth': savedState.routeStack.length,
          },
        );
        
        // Navigate to the saved route
        await pushNamed(
          context,
          savedState.currentRoute,
          arguments: savedState.arguments,
        );
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to restore navigation state: $e',
        operation: 'RESTORE_STATE',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Clears navigation state (useful for logout)
  static Future<void> clearNavigationState() async {
    try {
      await _statePersistence.clearNavigationState();
      _logger.info(
        'Navigation state cleared',
        operation: 'CLEAR_STATE',
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to clear navigation state: $e',
        operation: 'CLEAR_STATE',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Gets navigation analytics for debugging
  static Map<String, dynamic> getAnalytics() {
    return _analytics.getAnalyticsSummary();
  }

  /// Gets navigation state statistics
  static Future<Map<String, dynamic>> getStateStatistics() async {
    return await _statePersistence.getStateStatistics();
  }

  /// Creates a safe error route for navigation failures
  static MaterialPageRoute<void> createErrorRoute(String error) {
    return MaterialPageRoute<void>(
      settings: RouteSettings(
        name: RouteNames.error,
        arguments: {'error': error},
      ),
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Navigation Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Navigation Error'),
              const SizedBox(height: 8),
              Text(error),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Try to navigate back or to home
                  if (Navigator.canPop(_)) {
                    Navigator.pop(_);
                  } else {
                    Navigator.pushNamedAndRemoveUntil(
                      _,
                      RouteNames.root,
                      (route) => false,
                    );
                  }
                },
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

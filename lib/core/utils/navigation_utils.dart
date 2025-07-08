import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:revision/core/navigation/route_names.dart';
import 'package:revision/core/utils/null_safety_utils.dart';

/// Utilities for safe navigation and route handling
class NavigationUtils {
  // Private constructor to prevent instantiation
  NavigationUtils._();

  /// Safely navigates to a route with null checks
  static Future<T?> safePush<T extends Object?>(
    BuildContext context,
    Route<T> route, {
    String? routeName,
  }) async {
    if (!context.mounted) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ Context not mounted during navigation to ${routeName ?? 'unknown route'}',
        );
      }
      return null;
    }

    try {
      final result = await Navigator.of(context).push(route);
      if (kDebugMode && routeName != null) {
        debugPrint('✅ Successfully navigated to: $routeName');
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Navigation error to ${routeName ?? 'unknown route'}: $e');
      }
      return null;
    }
  }

  /// Safely replaces current route with null checks
  static Future<T?> safeReplacement<T extends Object?, TO extends Object?>(
    BuildContext context,
    Route<T> newRoute, {
    TO? result,
    String? routeName,
  }) async {
    if (!context.mounted) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ Context not mounted during replacement to ${routeName ?? 'unknown route'}',
        );
      }
      return null;
    }

    try {
      final navigationResult = await Navigator.of(
        context,
      ).pushReplacement(newRoute, result: result);
      if (kDebugMode && routeName != null) {
        debugPrint('✅ Successfully replaced route with: $routeName');
      }
      return navigationResult;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '❌ Route replacement error to ${routeName ?? 'unknown route'}: $e',
        );
      }
      return null;
    }
  }

  /// Safely pops the current route with null checks
  static void safePop<T extends Object?>(BuildContext context, [T? result]) {
    if (!context.mounted) {
      if (kDebugMode) {
        debugPrint('⚠️ Context not mounted during pop');
      }
      return;
    }

    try {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(result);
        if (kDebugMode) {
          debugPrint('✅ Successfully popped route');
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ Cannot pop route - no route to pop');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error popping route: $e');
      }
    }
  }

  /// Safely navigates to a named route
  static Future<T?> safePushNamed<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    if (!context.mounted) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ Context not mounted during named navigation to $routeName',
        );
      }
      return null;
    }

    // Validate route name
    if (!RouteNames.isValidRoute(routeName)) {
      if (kDebugMode) {
        debugPrint('⚠️ Invalid route name: $routeName');
      }
      return null;
    }

    try {
      final result = await Navigator.of(
        context,
      ).pushNamed(routeName, arguments: arguments);
      if (kDebugMode) {
        debugPrint('✅ Successfully navigated to named route: $routeName');
      }
      return result as T?;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Named navigation error to $routeName: $e');
      }
      return null;
    }
  }

  /// Safely gets route arguments with type checking
  static T? safeGetRouteArguments<T>(
    BuildContext context, {
    String? expectedType,
  }) {
    try {
      final settings = ModalRoute.of(context)?.settings;
      final arguments = settings?.arguments;

      if (arguments == null) {
        if (kDebugMode && expectedType != null) {
          debugPrint('⚠️ No route arguments found, expected: $expectedType');
        }
        return null;
      }

      if (arguments is T) {
        if (kDebugMode) {
          debugPrint(
            '✅ Successfully retrieved route arguments of type: ${arguments.runtimeType}',
          );
        }
        return arguments as T;
      }

      if (kDebugMode) {
        debugPrint(
          '⚠️ Route arguments type mismatch. Expected: $T, Got: ${arguments.runtimeType}',
        );
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting route arguments: $e');
      }
      return null;
    }
  }

  /// Gets current route name safely
  static String getCurrentRouteName(BuildContext context) {
    try {
      final routeName = ModalRoute.of(context)?.settings.name;
      return NullSafetyUtils.safeString(
        routeName,
        fallback: 'unknown_route',
        context: 'getCurrentRouteName',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting current route name: $e');
      }
      return 'error_route';
    }
  }

  /// Gets current route display name safely
  static String getCurrentRouteDisplayName(BuildContext context) {
    final routeName = getCurrentRouteName(context);
    return RouteNames.getDisplayName(routeName);
  }

  /// Checks if we can pop the current route
  static bool canPop(BuildContext context) {
    try {
      return Navigator.of(context).canPop();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking if can pop: $e');
      }
      return false;
    }
  }

  /// Safely clears navigation stack and pushes new route
  static Future<T?> safePushAndClearStack<T extends Object?>(
    BuildContext context,
    Route<T> newRoute, {
    String? routeName,
  }) async {
    if (!context.mounted) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ Context not mounted during stack clear to ${routeName ?? 'unknown route'}',
        );
      }
      return null;
    }

    try {
      final result = await Navigator.of(
        context,
      ).pushAndRemoveUntil(newRoute, (route) => false);
      if (kDebugMode && routeName != null) {
        debugPrint('✅ Successfully cleared stack and navigated to: $routeName');
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '❌ Stack clear navigation error to ${routeName ?? 'unknown route'}: $e',
        );
      }
      return null;
    }
  }

  /// Safely pops until a specific route
  static void safePopUntil(BuildContext context, String targetRouteName) {
    if (!context.mounted) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ Context not mounted during popUntil to $targetRouteName',
        );
      }
      return;
    }

    try {
      Navigator.of(context).popUntil((route) {
        return route.settings.name == targetRouteName;
      });
      if (kDebugMode) {
        debugPrint('✅ Successfully popped until: $targetRouteName');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error popping until $targetRouteName: $e');
      }
    }
  }

  /// Logs current navigation stack (debug only)
  static void logNavigationStack(BuildContext context) {
    if (!kDebugMode) return;

    try {
      final navigator = Navigator.of(context);
      debugPrint('📍 Current Navigation Stack:');

      // This is a simplified representation since we can't easily access the full stack
      final currentRoute = ModalRoute.of(context);
      if (currentRoute != null) {
        final routeName = currentRoute.settings.name ?? 'unnamed_route';
        final displayName = RouteNames.getDisplayName(routeName);
        debugPrint('  → Current: $routeName ($displayName)');
        debugPrint('  → Can Pop: ${navigator.canPop()}');
      } else {
        debugPrint('  → No current route found');
      }
    } catch (e) {
      debugPrint('❌ Error logging navigation stack: $e');
    }
  }
}

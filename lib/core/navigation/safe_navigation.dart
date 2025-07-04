import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:revision/core/navigation/route_names.dart';

/// Safe navigation utilities that prevent null value errors
/// 
/// This class implements all the best practices for null-safe navigation
/// as outlined in Flutter's null safety guidelines.
class SafeNavigation {
  SafeNavigation._();

  /// Safely extracts arguments from route with type checking and null safety
  static T? getArguments<T>(BuildContext context) {
    try {
      final route = ModalRoute.of(context);
      if (route == null) {
        if (kDebugMode) {
          debugPrint('⚠️ SafeNavigation: No ModalRoute found in context');
        }
        return null;
      }

      final settings = route.settings;
      if (settings == null) {
        if (kDebugMode) {
          debugPrint('⚠️ SafeNavigation: No RouteSettings found');
        }
        return null;
      }

      final arguments = settings.arguments;
      if (arguments == null) {
        if (kDebugMode) {
          debugPrint('⚠️ SafeNavigation: No arguments found for route ${settings.name}');
        }
        return null;
      }

      // Safe type checking and casting
      if (arguments is T) {
        if (kDebugMode) {
          debugPrint('✅ SafeNavigation: Successfully extracted arguments of type $T');
        }
        return arguments;
      }

      if (kDebugMode) {
        debugPrint(
          '⚠️ SafeNavigation: Type mismatch. Expected: $T, Got: ${arguments.runtimeType}',
        );
      }
      return null;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ SafeNavigation: Error extracting arguments: $e');
        debugPrint('❌ Stack trace: $stackTrace');
      }
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
        if (kDebugMode) {
          debugPrint('⚠️ SafeNavigation: Failed to convert Map to Map<String, dynamic>: $e');
        }
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

    if (kDebugMode && value != null) {
      debugPrint(
        '⚠️ SafeNavigation: Argument "$key" type mismatch. Expected: $T, Got: ${value.runtimeType}',
      );
    }

    return null;
  }

  /// Gets current route name safely
  static String? getCurrentRouteName(BuildContext context) {
    try {
      final route = ModalRoute.of(context);
      final name = route?.settings.name;
      
      if (kDebugMode && name != null) {
        debugPrint('🔗 SafeNavigation: Current route: $name');
      }
      
      return name;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ SafeNavigation: Error getting route name: $e');
      }
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
    try {
      if (!RouteNames.isValidRoute(routeName)) {
        if (kDebugMode) {
          debugPrint('⚠️ SafeNavigation: Invalid route name: $routeName');
        }
        // Navigate to error page or home instead
        return pushNamed<T>(context, RouteNames.error, 
          arguments: {'error': 'Invalid route: $routeName'});
      }

      if (kDebugMode) {
        debugPrint('🔗 SafeNavigation: Navigating to $routeName');
        if (arguments != null) {
          debugPrint('🔗 SafeNavigation: With arguments: $arguments');
        }
      }

      return await Navigator.of(context).pushNamed<T>(
        routeName,
        arguments: arguments,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ SafeNavigation: Navigation error: $e');
        debugPrint('❌ Stack trace: $stackTrace');
      }

      // Fallback navigation to safe route
      try {
        return await Navigator.of(context).pushNamed<T>(
          RouteNames.error,
          arguments: {'error': 'Navigation failed: $e'},
        );
      } catch (fallbackError) {
        if (kDebugMode) {
          debugPrint('❌ SafeNavigation: Fallback navigation also failed: $fallbackError');
        }
        return null;
      }
    }
  }

  /// Safely pushes a route with proper error handling
  static Future<T?> push<T extends Object?>(
    BuildContext context,
    Route<T> route,
  ) async {
    try {
      final routeName = route.settings?.name ?? 'unnamed';
      
      if (kDebugMode) {
        debugPrint('🔗 SafeNavigation: Pushing route: $routeName');
      }

      return await Navigator.of(context).push<T>(route);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ SafeNavigation: Push route error: $e');
        debugPrint('❌ Stack trace: $stackTrace');
      }
      return null;
    }
  }

  /// Safely replaces current route
  static Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
    BuildContext context,
    Route<T> newRoute, {
    TO? result,
  }) async {
    try {
      final routeName = newRoute.settings?.name ?? 'unnamed';
      
      if (kDebugMode) {
        debugPrint('🔗 SafeNavigation: Replacing with route: $routeName');
      }

      return await Navigator.of(context).pushReplacement<T, TO>(
        newRoute,
        result: result,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ SafeNavigation: Push replacement error: $e');
        debugPrint('❌ Stack trace: $stackTrace');
      }
      return null;
    }
  }

  /// Safely pops route with error handling
  static void pop<T extends Object?>(BuildContext context, [T? result]) {
    try {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop<T>(result);
        
        if (kDebugMode) {
          debugPrint('🔗 SafeNavigation: Popped route');
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ SafeNavigation: Cannot pop - no routes to pop');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ SafeNavigation: Pop error: $e');
        debugPrint('❌ Stack trace: $stackTrace');
      }
    }
  }

  /// Safely pops until a specific route
  static void popUntil(BuildContext context, String routeName) {
    try {
      Navigator.of(context).popUntil((route) {
        final currentName = route.settings.name;
        return currentName == routeName;
      });
      
      if (kDebugMode) {
        debugPrint('🔗 SafeNavigation: Popped until route: $routeName');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ SafeNavigation: Pop until error: $e');
        debugPrint('❌ Stack trace: $stackTrace');
      }
    }
  }

  /// Validates route arguments before navigation
  static bool validateArguments(Object? arguments, Type expectedType) {
    if (arguments == null) {
      return expectedType == Null;
    }

    final isValid = arguments.runtimeType == expectedType;
    
    if (kDebugMode && !isValid) {
      debugPrint(
        '⚠️ SafeNavigation: Argument validation failed. '
        'Expected: $expectedType, Got: ${arguments.runtimeType}',
      );
    }

    return isValid;
  }

  /// Creates a safe error route for navigation failures
  static MaterialPageRoute<void> createErrorRoute(String error) {
    return MaterialPageRoute<void>(
      settings: RouteSettings(
        name: RouteNames.error,
        arguments: {'error': error},
      ),
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: const Text('Navigation Error'),
        ),
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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Enhanced route factory that ensures all routes have proper settings
/// and prevents null route names in navigation events.
class RouteFactory {
  // Private constructor to prevent instantiation
  RouteFactory._();

  /// Creates a MaterialPageRoute with proper settings
  static MaterialPageRoute<T> createRoute<T>({
    required WidgetBuilder builder,
    required String routeName,
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
    bool allowSnapshotting = true,
    Map<String, dynamic>? arguments,
  }) {
    // Ensure route settings are always provided
    final effectiveSettings = RouteSettings(
      name: routeName,
      arguments: arguments ?? settings?.arguments,
    );

    // Add debug logging in development
    if (kDebugMode) {
      debugPrint('🔗 Creating route: $routeName');
      if (arguments != null) {
        debugPrint('🔗 Route arguments: $arguments');
      }
    }

    return MaterialPageRoute<T>(
      builder: builder,
      settings: effectiveSettings,
      maintainState: maintainState,
      fullscreenDialog: fullscreenDialog,
      allowSnapshotting: allowSnapshotting,
    );
  }

  /// Creates a page route with fade transition
  static PageRoute<T> createFadeRoute<T>({
    required Widget page,
    required String routeName,
    RouteSettings? settings,
    Duration duration = const Duration(milliseconds: 300),
    Map<String, dynamic>? arguments,
  }) {
    final effectiveSettings = RouteSettings(
      name: routeName,
      arguments: arguments ?? settings?.arguments,
    );

    if (kDebugMode) {
      debugPrint('🔗 Creating fade route: $routeName');
    }

    return PageRouteBuilder<T>(
      settings: effectiveSettings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  /// Creates a page route with slide transition
  static PageRoute<T> createSlideRoute<T>({
    required Widget page,
    required String routeName,
    RouteSettings? settings,
    Duration duration = const Duration(milliseconds: 300),
    Offset beginOffset = const Offset(1.0, 0.0),
    Map<String, dynamic>? arguments,
  }) {
    final effectiveSettings = RouteSettings(
      name: routeName,
      arguments: arguments ?? settings?.arguments,
    );

    if (kDebugMode) {
      debugPrint('🔗 Creating slide route: $routeName');
    }

    return PageRouteBuilder<T>(
      settings: effectiveSettings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(begin: beginOffset, end: Offset.zero)
            .chain(CurveTween(curve: Curves.ease));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  /// Creates a route with custom transition
  static PageRoute<T> createCustomRoute<T>({
    required Widget page,
    required String routeName,
    required Widget Function(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) transitionsBuilder,
    RouteSettings? settings,
    Duration duration = const Duration(milliseconds: 300),
    Map<String, dynamic>? arguments,
  }) {
    final effectiveSettings = RouteSettings(
      name: routeName,
      arguments: arguments ?? settings?.arguments,
    );

    if (kDebugMode) {
      debugPrint('🔗 Creating custom route: $routeName');
    }

    return PageRouteBuilder<T>(
      settings: effectiveSettings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: transitionsBuilder,
    );
  }

  /// Helper to extract type-safe arguments from route
  static T? getArguments<T>(BuildContext context) {
    final settings = ModalRoute.of(context)?.settings;
    final arguments = settings?.arguments;
    
    if (arguments is T) {
      return arguments;
    }
    
    if (kDebugMode && arguments != null) {
      debugPrint('⚠️ Route arguments type mismatch. Expected: $T, Got: ${arguments.runtimeType}');
    }
    
    return null;
  }

  /// Helper to get current route name safely
  static String? getCurrentRouteName(BuildContext context) {
    return ModalRoute.of(context)?.settings.name;
  }

  /// Helper to check if current route matches
  static bool isCurrentRoute(BuildContext context, String routeName) {
    return getCurrentRouteName(context) == routeName;
  }
}

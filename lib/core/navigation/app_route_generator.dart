import 'package:flutter/material.dart';
import 'package:revision/core/navigation/navigation_arguments.dart';
import 'package:revision/core/navigation/route_names.dart';
import 'package:revision/core/navigation/safe_navigation.dart';
import 'package:revision/features/ai_processing/presentation/pages/ai_processing_page.dart';
import 'package:revision/features/authentication/presentation/pages/authentication_wrapper.dart';
import 'package:revision/features/authentication/presentation/pages/login_page.dart';
import 'package:revision/features/authentication/presentation/pages/signup_page.dart';
import 'package:revision/features/authentication/presentation/pages/welcome_page.dart';
import 'package:revision/features/dashboard/view/dashboard_page.dart';
import 'package:revision/features/demo/object_removal_demo_page.dart';
import 'package:revision/features/image_selection/presentation/view/image_selection_page.dart';

/// App-wide route generator that provides null-safe navigation
/// 
/// This class ensures all routes have proper settings and handles
/// unknown routes gracefully to prevent navigation errors.
class AppRouteGenerator {
  AppRouteGenerator._();

  /// Generates routes based on RouteSettings with null safety
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final routeName = settings.name ?? RouteNames.root;
    final arguments = settings.arguments;

    debugPrint('🔗 AppRouteGenerator: Generating route: $routeName');
    if (arguments != null) {
      debugPrint('🔗 AppRouteGenerator: Arguments: ${NavigationArguments.debugSummary(arguments)}');
    }

    try {
      switch (routeName) {
        case RouteNames.root:
        case RouteNames.home:
          return _createRoute(
            const AuthenticationWrapper(),
            RouteSettings(
              name: RouteNames.root,
              arguments: settings.arguments,
            ),
          );

        case RouteNames.welcome:
          return _createRoute(
            const WelcomePage(),
            settings,
          );

        case RouteNames.login:
          return _createRoute(
            const LoginPage(),
            settings,
          );

        case RouteNames.signup:
          return _createRoute(
            const SignUpPage(),
            settings,
          );

        case RouteNames.dashboard:
          return _createRoute(
            const DashboardPage(),
            settings,
          );

        case RouteNames.imageSelection:
          return _createRoute(
            const ImageSelectionPage(),
            settings,
          );

        case RouteNames.aiProcessing:
          return _generateAiProcessingRoute(settings);

        case RouteNames.objectRemovalDemo:
          return _createRoute(
            const ObjectRemovalDemoPage(),
            settings,
          );

        case RouteNames.error:
          return _generateErrorRoute(settings);

        default:
          return _generateUnknownRoute(settings);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ AppRouteGenerator: Error generating route $routeName: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      
      return SafeNavigation.createErrorRoute(
        'Failed to generate route: $routeName\nError: $e',
      );
    }
  }

  /// Creates a standard MaterialPageRoute with proper settings
  static MaterialPageRoute<T> _createRoute<T>(
    Widget page,
    RouteSettings settings,
  ) {
    return MaterialPageRoute<T>(
      builder: (_) => page,
      settings: settings,
    );
  }

  /// Generates AI processing route with argument validation
  static Route<dynamic> _generateAiProcessingRoute(RouteSettings settings) {
    final args = NavigationArguments.toSafeMap(settings.arguments);
    
    final selectedImage = NavigationArguments.extractValue(args, 'selectedImage');
    final annotatedImage = NavigationArguments.extractValue(args, 'annotatedImage');

    if (selectedImage == null) {
      debugPrint('⚠️ AppRouteGenerator: AI processing route missing selectedImage');
      return SafeNavigation.createErrorRoute(
        'AI Processing requires a selected image.\nPlease select an image first.',
      );
    }

    return _createRoute(
      AiProcessingPage(
        selectedImage: selectedImage,
        annotatedImage: annotatedImage,
      ),
      settings,
    );
  }

  /// Generates error route with error information
  static Route<dynamic> _generateErrorRoute(RouteSettings settings) {
    final args = NavigationArguments.toSafeMap(settings.arguments);
    final error = NavigationArguments.extractValue<String>(
      args,
      'error',
      defaultValue: 'Unknown error occurred',
    )!;

    return SafeNavigation.createErrorRoute(error);
  }

  /// Generates route for unknown/undefined routes
  static Route<dynamic> _generateUnknownRoute(RouteSettings settings) {
    final routeName = settings.name ?? 'unknown';
    
    debugPrint('⚠️ AppRouteGenerator: Unknown route: $routeName');
    
    return MaterialPageRoute<void>(
      settings: RouteSettings(
        name: RouteNames.notFound,
        arguments: {'requestedRoute': routeName},
      ),
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: const Text('Page Not Found'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'Page Not Found',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Route not found: $routeName'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(_).pushNamedAndRemoveUntil(
                    RouteNames.root,
                    (route) => false,
                  );
                },
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Validates route before generation
  static bool validateRoute(String routeName, Object? arguments) {
    switch (routeName) {
      case RouteNames.aiProcessing:
        final args = NavigationArguments.toSafeMap(arguments);
        return NavigationArguments.validateArguments(args, ['selectedImage']);
      
      case RouteNames.error:
        final args = NavigationArguments.toSafeMap(arguments);
        return NavigationArguments.validateArguments(args, ['error']);
      
      default:
        return true; // Most routes don't require specific arguments
    }
  }

  /// Gets all available routes for debugging
  static List<String> getAllRoutes() {
    return [
      RouteNames.root,
      RouteNames.home,
      RouteNames.welcome,
      RouteNames.login,
      RouteNames.signup,
      RouteNames.dashboard,
      RouteNames.imageSelection,
      RouteNames.aiProcessing,
      RouteNames.objectRemovalDemo,
      RouteNames.error,
      RouteNames.notFound,
    ];
  }
}

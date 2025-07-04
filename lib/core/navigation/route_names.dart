/// Route names constants for the application
/// 
/// This file centralizes all route names to ensure consistency
/// and prevent null route names in navigation events.
class RouteNames {
  // Private constructor to prevent instantiation
  RouteNames._();

  // Root routes
  static const String root = '/';
  static const String home = '/home';
  static const String splash = '/splash';

  // Authentication routes
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String emailVerification = '/email-verification';

  // Main feature routes
  static const String dashboard = '/dashboard';
  static const String imageSelection = '/image-selection';
  static const String aiProcessing = '/ai-processing';
  static const String imageEditing = '/image-editing';
  static const String imageAnnotation = '/image-annotation';

  // Profile and settings routes
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String accountSettings = '/account-settings';

  // Demo and debug routes
  static const String objectRemovalDemo = '/demo/object-removal';
  static const String firebaseDebug = '/debug/firebase';
  static const String aiDebug = '/debug/ai';

  // Error routes
  static const String error = '/error';
  static const String notFound = '/404';

  /// Gets a readable name for a route
  static String getDisplayName(String routeName) {
    switch (routeName) {
      case root:
        return 'Home';
      case welcome:
        return 'Welcome';
      case login:
        return 'Login';
      case signup:
        return 'Sign Up';
      case dashboard:
        return 'Dashboard';
      case imageSelection:
        return 'Image Selection';
      case aiProcessing:
        return 'AI Processing';
      case profile:
        return 'Profile';
      case settings:
        return 'Settings';
      default:
        return routeName.replaceAll('/', '').replaceAll('-', ' ');
    }
  }

  /// Validates if a route name is defined
  static bool isValidRoute(String routeName) {
    return _allRoutes.contains(routeName);
  }

  /// All defined routes for validation
  static const List<String> _allRoutes = [
    root,
    home,
    splash,
    welcome,
    login,
    signup,
    forgotPassword,
    emailVerification,
    dashboard,
    imageSelection,
    aiProcessing,
    imageEditing,
    imageAnnotation,
    profile,
    settings,
    accountSettings,
    objectRemovalDemo,
    firebaseDebug,
    aiDebug,
    error,
    notFound,
  ];
}

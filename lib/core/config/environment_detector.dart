import 'package:flutter/foundation.dart';

/// Environment types for the application
enum AppEnvironment {
  development,
  staging,
  production,
}

/// Detects the current environment at runtime and compile-time
class EnvironmentDetector {
  static AppEnvironment? _cachedEnvironment;

  /// Get the current environment with runtime detection fallback
  static AppEnvironment get currentEnvironment {
    if (_cachedEnvironment != null) {
      return _cachedEnvironment!;
    }

    _cachedEnvironment = _detectEnvironment();
    return _cachedEnvironment!;
  }

  /// Force refresh the environment detection
  static void refresh() {
    _cachedEnvironment = null;
  }

  static AppEnvironment _detectEnvironment() {
    // 1. First check compile-time environment constant
    const compileTimeEnv = String.fromEnvironment('ENVIRONMENT');
    if (compileTimeEnv.isNotEmpty) {
      switch (compileTimeEnv.toLowerCase()) {
        case 'production':
          return AppEnvironment.production;
        case 'staging':
          return AppEnvironment.staging;
        case 'development':
        default:
          return AppEnvironment.development;
      }
    }

    // 2. For web, detect environment from URL
    if (kIsWeb) {
      return _detectWebEnvironment();
    }

    // 3. For mobile, use debug/release mode as fallback
    if (kDebugMode) {
      return AppEnvironment.development;
    } else {
      return AppEnvironment.production;
    }
  }

  static AppEnvironment _detectWebEnvironment() {
    // Get the current URL
    final url = Uri.base;
    final host = url.host.toLowerCase();
    final path = url.path.toLowerCase();

    // Check for specific domain patterns
    if (host.contains('localhost') || 
        host.contains('127.0.0.1') || 
        host.startsWith('192.168.') ||
        host.startsWith('10.0.') ||
        host.contains('dev.') ||
        path.contains('/dev/')) {
      return AppEnvironment.development;
    }
    
    if (host.contains('staging') || 
        host.contains('stage') ||
        host.contains('test') ||
        path.contains('/staging/') ||
        path.contains('/stage/')) {
      return AppEnvironment.staging;
    }

    // Production patterns
    if (host.contains('prod') || 
        host.contains('app.') ||
        host.contains('www.') ||
        (!host.contains('localhost') && !host.contains('dev') && !host.contains('staging'))) {
      return AppEnvironment.production;
    }

    // Default to development for unknown patterns
    return AppEnvironment.development;
  }

  /// Get environment as string
  static String get environmentString {
    switch (currentEnvironment) {
      case AppEnvironment.development:
        return 'development';
      case AppEnvironment.staging:
        return 'staging';
      case AppEnvironment.production:
        return 'production';
    }
  }

  /// Check if current environment is development
  static bool get isDevelopment => currentEnvironment == AppEnvironment.development;

  /// Check if current environment is staging
  static bool get isStaging => currentEnvironment == AppEnvironment.staging;

  /// Check if current environment is production
  static bool get isProduction => currentEnvironment == AppEnvironment.production;

  /// Get debug information about environment detection
  static Map<String, dynamic> getDebugInfo() {
    return {
      'currentEnvironment': environmentString,
      'compileTimeEnv': const String.fromEnvironment('ENVIRONMENT', defaultValue: 'not_set'),
      'isWeb': kIsWeb,
      'isDebugMode': kDebugMode,
      'isReleaseMode': kReleaseMode,
      if (kIsWeb) ...{
        'webHost': Uri.base.host,
        'webPath': Uri.base.path,
        'webQuery': Uri.base.query,
        'fullUrl': Uri.base.toString(),
      },
    };
  }
}

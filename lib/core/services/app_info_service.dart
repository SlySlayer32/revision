import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:revision/core/services/logging_service.dart';
import 'package:revision/core/constants/environment_config.dart';

/// App information service for displaying version and security info
class AppInfoService {
  const AppInfoService._();

  static const AppInfoService _instance = AppInfoService._();
  static AppInfoService get instance => _instance;

  static String? _appName;
  static String? _appVersion;
  static String? _buildNumber;
  static String? _packageName;
  static bool _isRooted = false;
  static bool _isDebugMode = kDebugMode;
  static Environment _environment = Environment.current;

  /// Initialize the app info service
  static Future<void> initialize() async {
    if (kDebugMode) {
      LoggingService.instance.debug('AppInfo: Initializing...');
    }
    
    try {
      // Get app version info
      await _loadAppInfo();
      
      // Check for security risks
      await _checkSecurityStatus();
      
      LoggingService.instance.info('AppInfo: Initialized successfully');
    } catch (e) {
      LoggingService.instance.error(
        'AppInfo: Failed to initialize', 
        error: e,
      );
    }
  }

  /// Load app information from platform
  static Future<void> _loadAppInfo() async {
    try {
      // For Flutter web/desktop, we'll use fallback values
      // In a real app, you would use package_info_plus plugin
      _appName = 'Revision';
      _appVersion = '1.0.0';
      _buildNumber = '1';
      _packageName = 'com.example.revision';
      
      LoggingService.instance.info('AppInfo: App info loaded successfully');
    } catch (e) {
      LoggingService.instance.error('AppInfo: Failed to load app info', error: e);
      // Set fallback values
      _appName = 'Revision';
      _appVersion = 'Unknown';
      _buildNumber = 'Unknown';
      _packageName = 'Unknown';
    }
  }

  /// Check security status of the device
  static Future<void> _checkSecurityStatus() async {
    try {
      // For now, we'll simulate security checks
      // In a real app, you would use plugins like:
      // - flutter_jailbreak_detection
      // - safe_device
      // - trust_fall
      
      _isRooted = false; // Simulated check
      _isDebugMode = kDebugMode;
      _environment = Environment.current;
      
      LoggingService.instance.info('AppInfo: Security status checked');
    } catch (e) {
      LoggingService.instance.error('AppInfo: Failed to check security status', error: e);
    }
  }

  /// Get app name
  String get appName => _appName ?? 'Unknown';

  /// Get app version
  String get appVersion => _appVersion ?? 'Unknown';

  /// Get build number
  String get buildNumber => _buildNumber ?? 'Unknown';

  /// Get package name
  String get packageName => _packageName ?? 'Unknown';

  /// Get full version string
  String get fullVersion => '$appVersion+$buildNumber';

  /// Check if device is rooted/jailbroken
  bool get isRooted => _isRooted;

  /// Check if app is in debug mode
  bool get isDebugMode => _isDebugMode;

  /// Get current environment
  Environment get environment => _environment;

  /// Get environment name
  String get environmentName => _environment.name;

  /// Check if app is running in production
  bool get isProduction => _environment == Environment.production;

  /// Check if app is running in development
  bool get isDevelopment => _environment == Environment.development;

  /// Get security warnings
  List<String> get securityWarnings {
    final warnings = <String>[];
    
    if (_isRooted) {
      warnings.add('Device is rooted - Security may be compromised');
    }
    
    if (_isDebugMode && _environment == Environment.production) {
      warnings.add('Debug mode enabled in production');
    }
    
    if (_environment == Environment.development) {
      warnings.add('Running in development mode');
    }
    
    return warnings;
  }

  /// Get app info map for analytics
  Map<String, dynamic> getAppInfoMap() {
    return {
      'appName': appName,
      'appVersion': appVersion,
      'buildNumber': buildNumber,
      'packageName': packageName,
      'isRooted': isRooted,
      'isDebugMode': isDebugMode,
      'environment': environmentName,
      'securityWarnings': securityWarnings,
    };
  }

  /// Get formatted app info for display
  String getFormattedAppInfo() {
    final buffer = StringBuffer();
    buffer.writeln('App: $appName');
    buffer.writeln('Version: $fullVersion');
    buffer.writeln('Environment: ${environmentName.toUpperCase()}');
    
    if (securityWarnings.isNotEmpty) {
      buffer.writeln('Security Warnings:');
      for (final warning in securityWarnings) {
        buffer.writeln('• $warning');
      }
    }
    
    return buffer.toString();
  }
}
import 'package:flutter/foundation.dart';
import 'package:revision/core/navigation/route_names.dart';
import 'package:revision/core/utils/enhanced_logger.dart';

/// Service for validating deep links and ensuring security
class DeepLinkValidator {
  static final DeepLinkValidator _instance = DeepLinkValidator._internal();
  factory DeepLinkValidator() => _instance;
  DeepLinkValidator._internal();

  final EnhancedLogger _logger = EnhancedLogger();

  /// Validates a deep link URL for security and correctness
  DeepLinkValidationResult validateDeepLink(String deepLink) {
    try {
      // Parse the URI
      final uri = Uri.parse(deepLink);
      
      // Basic URI validation
      if (uri.scheme.isEmpty || uri.path.isEmpty) {
        return DeepLinkValidationResult.invalid(
          'Invalid URI format: missing scheme or path',
          deepLink,
        );
      }

      // Validate scheme (only allow specific schemes)
      if (!_isValidScheme(uri.scheme)) {
        return DeepLinkValidationResult.invalid(
          'Invalid URI scheme: ${uri.scheme}',
          deepLink,
        );
      }

      // Validate host for external deep links
      if (uri.hasAuthority && !_isValidHost(uri.host)) {
        return DeepLinkValidationResult.invalid(
          'Invalid or untrusted host: ${uri.host}',
          deepLink,
        );
      }

      // Extract route path
      final routePath = uri.path.startsWith('/') ? uri.path : '/$uri.path';
      
      // Validate route exists
      if (!RouteNames.isValidRoute(routePath)) {
        return DeepLinkValidationResult.invalid(
          'Route not found: $routePath',
          deepLink,
        );
      }

      // Validate query parameters
      final queryValidation = _validateQueryParameters(uri.queryParameters);
      if (!queryValidation.isValid) {
        return DeepLinkValidationResult.invalid(
          'Invalid query parameters: ${queryValidation.error}',
          deepLink,
        );
      }

      // Extract and validate arguments
      final extractedArgs = _extractArguments(uri);
      final argValidation = _validateArguments(routePath, extractedArgs);
      if (!argValidation.isValid) {
        return DeepLinkValidationResult.invalid(
          'Invalid arguments: ${argValidation.error}',
          deepLink,
        );
      }

      return DeepLinkValidationResult.valid(
        routePath,
        extractedArgs,
        deepLink,
      );

    } catch (e, stackTrace) {
      _logger.error(
        'Deep link validation error: $e',
        operation: 'DEEP_LINK_VALIDATION',
        error: e,
        stackTrace: stackTrace,
        context: {'deep_link': deepLink},
      );

      return DeepLinkValidationResult.invalid(
        'Validation error: $e',
        deepLink,
      );
    }
  }

  /// Validates if the URI scheme is allowed
  bool _isValidScheme(String scheme) {
    const allowedSchemes = [
      'https',
      'http', // Only for development
      'revision', // Custom app scheme
    ];
    
    // In production, only allow HTTPS and custom scheme
    if (kReleaseMode) {
      return scheme == 'https' || scheme == 'revision';
    }
    
    return allowedSchemes.contains(scheme.toLowerCase());
  }

  /// Validates if the host is trusted
  bool _isValidHost(String host) {
    const trustedHosts = [
      'revision.app',
      'www.revision.app',
      'api.revision.app',
      'localhost', // Only for development
    ];
    
    // In production, only allow specific trusted hosts
    if (kReleaseMode) {
      return trustedHosts.where((h) => h != 'localhost').contains(host.toLowerCase());
    }
    
    return trustedHosts.contains(host.toLowerCase());
  }

  /// Validates query parameters for security issues
  _ValidationResult _validateQueryParameters(Map<String, String> params) {
    for (final entry in params.entries) {
      final key = entry.key;
      final value = entry.value;

      // Check for suspicious parameters
      if (_isSuspiciousParameter(key, value)) {
        return _ValidationResult.invalid('Suspicious parameter: $key');
      }

      // Check parameter length limits
      if (key.length > 50 || value.length > 1000) {
        return _ValidationResult.invalid('Parameter too long: $key');
      }

      // Check for script injection attempts
      if (_containsScriptInjection(value)) {
        return _ValidationResult.invalid('Script injection detected in: $key');
      }
    }

    return _ValidationResult.valid();
  }

  /// Checks if a parameter looks suspicious
  bool _isSuspiciousParameter(String key, String value) {
    const suspiciousKeys = [
      'javascript',
      'script',
      'eval',
      'onload',
      'onerror',
      'onclick',
    ];

    return suspiciousKeys.any((suspicious) => 
      key.toLowerCase().contains(suspicious) ||
      value.toLowerCase().contains(suspicious)
    );
  }

  /// Checks for script injection attempts
  bool _containsScriptInjection(String value) {
    const scriptPatterns = [
      '<script',
      'javascript:',
      'onload=',
      'onerror=',
      'eval(',
      'alert(',
      'document.cookie',
      'window.location',
    ];

    final lowerValue = value.toLowerCase();
    return scriptPatterns.any((pattern) => lowerValue.contains(pattern));
  }

  /// Extracts arguments from URI
  Map<String, dynamic> _extractArguments(Uri uri) {
    final args = <String, dynamic>{};
    
    // Add query parameters
    args.addAll(uri.queryParameters);
    
    // Add fragment data if present
    if (uri.fragment.isNotEmpty) {
      args['fragment'] = uri.fragment;
    }
    
    // Add path parameters (if any custom parsing is needed)
    final pathSegments = uri.pathSegments;
    if (pathSegments.length > 1) {
      args['path_segments'] = pathSegments;
    }
    
    return args;
  }

  /// Validates arguments for a specific route
  _ValidationResult _validateArguments(String route, Map<String, dynamic> arguments) {
    // Route-specific validation rules
    switch (route) {
      case RouteNames.aiProcessing:
        return _validateAiProcessingArguments(arguments);
      case RouteNames.error:
        return _validateErrorArguments(arguments);
      case RouteNames.dashboard:
        return _validateDashboardArguments(arguments);
      default:
        return _ValidationResult.valid(); // No specific validation needed
    }
  }

  /// Validates AI processing route arguments
  _ValidationResult _validateAiProcessingArguments(Map<String, dynamic> arguments) {
    if (arguments.containsKey('selectedImage')) {
      // Validate image data is not suspicious
      final imageData = arguments['selectedImage'];
      if (imageData is String && imageData.contains('javascript:')) {
        return _ValidationResult.invalid('Suspicious image data');
      }
    }
    
    return _ValidationResult.valid();
  }

  /// Validates error route arguments
  _ValidationResult _validateErrorArguments(Map<String, dynamic> arguments) {
    if (arguments.containsKey('error')) {
      final error = arguments['error'];
      if (error is String && error.length > 500) {
        return _ValidationResult.invalid('Error message too long');
      }
    }
    
    return _ValidationResult.valid();
  }

  /// Validates dashboard route arguments
  _ValidationResult _validateDashboardArguments(Map<String, dynamic> arguments) {
    if (arguments.containsKey('tab')) {
      final tab = arguments['tab'];
      if (tab is String && !_isValidTabName(tab)) {
        return _ValidationResult.invalid('Invalid tab name: $tab');
      }
    }
    
    return _ValidationResult.valid();
  }

  /// Validates tab names for dashboard
  bool _isValidTabName(String tabName) {
    const validTabs = ['home', 'ai', 'settings', 'profile'];
    return validTabs.contains(tabName.toLowerCase());
  }
}

/// Result of deep link validation
class DeepLinkValidationResult {
  const DeepLinkValidationResult._({
    required this.isValid,
    required this.originalUrl,
    this.routePath,
    this.arguments,
    this.error,
  });

  final bool isValid;
  final String originalUrl;
  final String? routePath;
  final Map<String, dynamic>? arguments;
  final String? error;

  factory DeepLinkValidationResult.valid(
    String routePath,
    Map<String, dynamic> arguments,
    String originalUrl,
  ) {
    return DeepLinkValidationResult._(
      isValid: true,
      originalUrl: originalUrl,
      routePath: routePath,
      arguments: arguments,
    );
  }

  factory DeepLinkValidationResult.invalid(
    String error,
    String originalUrl,
  ) {
    return DeepLinkValidationResult._(
      isValid: false,
      originalUrl: originalUrl,
      error: error,
    );
  }
}

/// Internal validation result helper
class _ValidationResult {
  const _ValidationResult._({
    required this.isValid,
    this.error,
  });

  final bool isValid;
  final String? error;

  factory _ValidationResult.valid() => const _ValidationResult._(isValid: true);
  factory _ValidationResult.invalid(String error) => _ValidationResult._(isValid: false, error: error);
}
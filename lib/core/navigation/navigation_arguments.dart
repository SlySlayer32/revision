import 'package:flutter/foundation.dart';

/// Type-safe argument handling for navigation
/// 
/// This class provides utilities for safely handling route arguments
/// with proper null checking and type validation.
class NavigationArguments {
  NavigationArguments._();

  /// Creates arguments for image selection
  static Map<String, dynamic> imageSelection({
    String? sourceType,
    Map<String, dynamic>? config,
  }) {
    return {
      'sourceType': sourceType,
      'config': config,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Creates arguments for AI processing
  static Map<String, dynamic> aiProcessing({
    required dynamic selectedImage,
    dynamic annotatedImage,
    Map<String, dynamic>? processingConfig,
  }) {
    return {
      'selectedImage': selectedImage,
      'annotatedImage': annotatedImage,
      'processingConfig': processingConfig,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Creates arguments for authentication
  static Map<String, dynamic> authentication({
    String? email,
    String? redirectRoute,
    Map<String, dynamic>? metadata,
  }) {
    return {
      'email': email,
      'redirectRoute': redirectRoute,
      'metadata': metadata,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Creates arguments for error handling
  static Map<String, dynamic> error({
    required String message,
    String? code,
    dynamic originalError,
    String? stackTrace,
  }) {
    return {
      'message': message,
      'code': code,
      'originalError': originalError?.toString(),
      'stackTrace': stackTrace,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Validates argument structure
  static bool validateArguments(
    Map<String, dynamic>? arguments,
    List<String> requiredKeys,
  ) {
    if (arguments == null) {
      if (kDebugMode) {
        debugPrint('⚠️ NavigationArguments: Arguments are null');
      }
      return false;
    }

    for (final key in requiredKeys) {
      if (!arguments.containsKey(key)) {
        if (kDebugMode) {
          debugPrint('⚠️ NavigationArguments: Missing required key: $key');
        }
        return false;
      }
    }

    return true;
  }

  /// Safely extracts a typed value from arguments
  static T? extractValue<T>(
    Map<String, dynamic>? arguments,
    String key, {
    T? defaultValue,
  }) {
    if (arguments == null) return defaultValue;
    
    final value = arguments[key];
    if (value is T) {
      return value;
    }

    if (kDebugMode && value != null) {
      debugPrint(
        '⚠️ NavigationArguments: Type mismatch for key "$key". '
        'Expected: $T, Got: ${value.runtimeType}',
      );
    }

    return defaultValue;
  }

  /// Converts arguments to a safe map
  static Map<String, dynamic> toSafeMap(Object? arguments) {
    if (arguments == null) return <String, dynamic>{};
    
    if (arguments is Map<String, dynamic>) {
      return Map<String, dynamic>.from(arguments);
    }
    
    if (arguments is Map) {
      try {
        return Map<String, dynamic>.from(arguments);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ NavigationArguments: Failed to convert Map: $e');
        }
        return <String, dynamic>{};
      }
    }

    // Try to convert other types to map
    try {
      if (arguments is String) {
        return {'data': arguments};
      }
      
      if (arguments is num || arguments is bool) {
        return {'value': arguments};
      }

      // For complex objects, convert to string representation
      return {'data': arguments.toString()};
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ NavigationArguments: Failed to convert to map: $e');
      }
      return <String, dynamic>{};
    }
  }

  /// Creates a debug summary of arguments
  static String debugSummary(Object? arguments) {
    if (arguments == null) return 'null';
    
    final safeMap = toSafeMap(arguments);
    final keys = safeMap.keys.toList();
    
    if (keys.isEmpty) return 'empty map';
    
    return 'Map with keys: ${keys.join(', ')}';
  }
}

import 'package:flutter/foundation.dart';

/// Utility class for sanitizing sensitive debug information
class DebugInfoSanitizer {
  DebugInfoSanitizer._();

  /// Sanitizes debug information to hide sensitive data
  static Map<String, dynamic> sanitizeDebugInfo(Map<String, dynamic> debugInfo) {
    final sanitized = <String, dynamic>{};
    
    for (final entry in debugInfo.entries) {
      final key = entry.key;
      final value = entry.value;
      
      // Sanitize API keys and sensitive configuration
      if (_isSensitiveKey(key)) {
        sanitized[key] = maskSensitiveValue(value.toString());
      } else {
        sanitized[key] = value;
      }
    }
    
    return sanitized;
  }

  /// Sanitizes Firebase information to hide sensitive data
  static Map<String, dynamic> sanitizeFirebaseInfo(Map<String, dynamic> firebaseInfo) {
    final sanitized = <String, dynamic>{};
    
    for (final entry in firebaseInfo.entries) {
      final key = entry.key;
      final value = entry.value;
      
      // Sanitize API keys and sensitive identifiers
      if (_isSensitiveKey(key)) {
        sanitized[key] = maskSensitiveValue(value.toString());
      } else if (key == 'projectId' || key == 'appId') {
        // Partially mask project and app IDs
        sanitized[key] = maskSensitiveValue(value.toString());
      } else {
        sanitized[key] = value;
      }
    }
    
    return sanitized;
  }

  /// Masks sensitive values by showing only first and last few characters
  static String maskSensitiveValue(String value) {
    if (value.length <= 8) {
      return '*' * value.length;
    }
    
    final start = value.substring(0, 3);
    final end = value.substring(value.length - 3);
    final middle = '*' * (value.length - 6);
    
    return '$start$middle$end';
  }

  /// Checks if a key contains sensitive information
  static bool _isSensitiveKey(String key) {
    final lowerKey = key.toLowerCase();
    return lowerKey.contains('key') || 
           lowerKey.contains('secret') ||
           lowerKey.contains('token') ||
           lowerKey.contains('password') ||
           lowerKey.contains('credential');
  }

  /// Logs debug actions for audit purposes
  static void logDebugAction(String action) {
    if (kDebugMode) {
      debugPrint('🔧 Debug action performed: $action');
      debugPrint('🔧 Action timestamp: ${DateTime.now().toIso8601String()}');
    }
  }

  /// Logs debug page access for audit purposes
  static void logDebugPageAccess(String pageName) {
    if (kDebugMode) {
      debugPrint('🔍 Debug page accessed: $pageName');
      debugPrint('🔍 Access timestamp: ${DateTime.now().toIso8601String()}');
    }
  }
}
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:revision/core/config/env_config.dart';

/// Exception thrown when API key security validation fails
class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}

/// Secure API key management service
/// Handles API key validation, masking, and security checks
class SecureAPIKeyManager {
  static const int _minKeyLength = 30;
  static const String _expectedPrefix = 'AIza';
  static const String _maskChar = '*';
  static DateTime? _lastValidation;
  static const Duration _validationCacheDuration = Duration(minutes: 5);

  /// Get API key with security validation. Throws [SecurityException] if invalid.
  static String? getSecureApiKey() {
    final apiKey = EnvConfig.geminiApiKey;

    if (apiKey == null || apiKey.isEmpty) {
      return null;
    }

    // Cache validation for performance
    if (_lastValidation != null &&
        DateTime.now().difference(_lastValidation!) < _validationCacheDuration) {
      return apiKey;
    }

    // Validate API key format
    if (!_validateApiKeyFormat(apiKey)) {
      // You may want to log or audit here (optional)
      throw SecurityException('Invalid API key format detected');
    }

    _lastValidation = DateTime.now();
    return apiKey;
  }

  /// Checks if API key is properly configured and valid.
  static bool isApiKeyConfigured() {
    final apiKey = EnvConfig.geminiApiKey;
    return apiKey != null && apiKey.isNotEmpty && _validateApiKeyFormat(apiKey);
  }

  /// Validate API key format without exposing the key
  static bool _validateApiKeyFormat(String apiKey) {
    if (apiKey.length < _minKeyLength) return false;
    if (!apiKey.startsWith(_expectedPrefix)) return false;
    final lower = apiKey.toLowerCase();
    if (lower.contains('test') || lower.contains('fake') || lower.contains('demo') || lower.contains('example')) {
      return false;
    }
    return true;
  }

  /// Returns a masked version of the API key for logging (e.g., AIza****abcd)
  static String getMaskedApiKey(String apiKey) {
    if (apiKey.length < 8) {
      return _maskChar * apiKey.length;
    }
    final prefix = apiKey.substring(0, 4);
    final suffix = apiKey.substring(apiKey.length - 4);
    final middleLength = apiKey.length - 8;
    return '$prefix${_maskChar * middleLength}$suffix';
  }

  /// Generate a secure hash of the API key for audit purposes (SHA-256, shortened to 16 chars)
  static String generateApiKeyHash(String apiKey) {
    final bytes = utf8.encode(apiKey);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  /// Get secure debug information without exposing the key content.
  static Map<String, dynamic> getSecureDebugInfo() {
    final apiKey = EnvConfig.geminiApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      return {
        'configured': false,
        'error': 'API key not found',
      };
    }
    return {
      'configured': true,
      'length': apiKey.length,
      'hasValidPrefix': apiKey.startsWith(_expectedPrefix),
      'meetsMinLength': apiKey.length >= _minKeyLength,
      'keyHash': generateApiKeyHash(apiKey),
      'maskedKey': getMaskedApiKey(apiKey),
    };
  }

  /// Placeholder for API key refresh (not implemented for Gemini API)
  static Future<String?> refreshApiKey() async {
    // For Gemini API keys, this is typically not needed as they don't expire.
    throw UnimplementedError('API key refresh not implemented for Gemini API');
  }
}
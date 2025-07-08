import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:revision/core/config/env_config.dart';

/// Secure API key management service
/// Handles API key validation, masking, and security checks
class SecureAPIKeyManager {
  static const int _minKeyLength = 30;
  static const String _expectedPrefix = 'AIza';
  static const String _maskChar = '*';

  /// Get API key with security validation
  static String? getSecureApiKey() {
    final apiKey = EnvConfig.geminiApiKey;
    
    if (apiKey == null || apiKey.isEmpty) {
      return null;
    }

    // Validate API key format
    if (!_validateApiKeyFormat(apiKey)) {
      throw SecurityException('Invalid API key format detected');
    }

    return apiKey;
  }

  /// Validate API key format without exposing the key
  static bool _validateApiKeyFormat(String apiKey) {
    // Check length
    if (apiKey.length < _minKeyLength) {
      return false;
    }

    // Check expected prefix
    if (!apiKey.startsWith(_expectedPrefix)) {
      return false;
    }

    // Check for common patterns that might indicate a test/fake key
    if (apiKey.contains('test') || 
        apiKey.contains('fake') || 
        apiKey.contains('demo') ||
        apiKey.contains('example')) {
      return false;
    }

    return true;
  }

  /// Get masked API key for logging purposes
  static String getMaskedApiKey(String apiKey) {
    if (apiKey.length < 8) {
      return _maskChar * apiKey.length;
    }
    
    // Show first 4 and last 4 characters
    final prefix = apiKey.substring(0, 4);
    final suffix = apiKey.substring(apiKey.length - 4);
    final middleLength = apiKey.length - 8;
    
    return '$prefix${'*' * middleLength}$suffix';
  }

  /// Generate a secure hash of the API key for audit purposes
  static String generateApiKeyHash(String apiKey) {
    final bytes = utf8.encode(apiKey);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16); // First 16 chars for brevity
  }

  /// Validate if API key is properly configured
  static bool isApiKeyConfigured() {
    final apiKey = EnvConfig.geminiApiKey;
    return apiKey != null && apiKey.isNotEmpty && _validateApiKeyFormat(apiKey);
  }

  /// Get secure debug information without exposing the key
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
}

/// Exception thrown when API key security validation fails
class SecurityException implements Exception {
  final String message;
  
  SecurityException(this.message);
  
  @override
  String toString() => 'SecurityException: $message';
}

import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Provides secure API key management, validation, and masked logging.
/// Exception thrown when an API key is invalid or missing.
class APIKeyException implements Exception {
  final String message;
  final String? code;
  const APIKeyException(this.message, [this.code]);

  @override
  String toString() => 'APIKeyException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Provides secure API key management, validation, and masked logging.
class SecureAPIKeyManager {
  /// The API key to manage. Must not be null.
  final String apiKey;

  /// Creates a new [SecureAPIKeyManager] with the given [apiKey].
  ///
  /// Throws [APIKeyException] if [apiKey] is null or empty.
  SecureAPIKeyManager(this.apiKey) {
    if (apiKey.isEmpty) {
      throw const APIKeyException('API key must not be empty', 'empty_key');
    }
  }

  /// Validates the API key format (length, prefix, not a test/fake key).
  ///
  /// @returns [bool] true if the API key is valid, false otherwise.
  bool isValid() {
    return apiKey.isNotEmpty &&
        apiKey.length >= 30 &&
        apiKey.startsWith('AIza') &&
        !apiKey.toLowerCase().contains('test') &&
        !apiKey.toLowerCase().contains('fake');
  }

  /// Returns a masked version of the API key for logging.
  ///
  /// @returns [String] Masked API key (e.g., AIza****abcd)
  String masked() {
    if (apiKey.length < 8) return '****';
    return apiKey.substring(0, 4) + '****' + apiKey.substring(apiKey.length - 4);
  }

  /// Returns a secure hash of the API key for audit logging.
  ///
  /// @returns [String] SHA-256 hash of the API key.
  String hash() {
    final bytes = utf8.encode(apiKey);
    return sha256.convert(bytes).toString();
  }
}

import 'package:crypto/crypto.dart';

/// Provides secure API key management, validation, and masked logging.
class SecureAPIKeyManager {
  final String apiKey;

  SecureAPIKeyManager(this.apiKey);

  /// Validates the API key format (length, prefix, not a test/fake key).
  bool isValid() {
    return apiKey.isNotEmpty &&
        apiKey.length >= 30 &&
        apiKey.startsWith('AIza') &&
        !apiKey.toLowerCase().contains('test') &&
        !apiKey.toLowerCase().contains('fake');
  }

  /// Returns a masked version of the API key for logging.
  String masked() {
    if (apiKey.length < 8) return '****';
    return apiKey.substring(0, 4) + '****' + apiKey.substring(apiKey.length - 4);
  }

  /// Returns a secure hash of the API key for audit logging.
  String hash() {
    final bytes = utf8.encode(apiKey);
    return sha256.convert(bytes).toString();
  }
}

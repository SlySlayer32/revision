import 'dart:convert';


/// Utility for encrypting and decrypting request payloads.
class RequestEncryptionUtil {
  final String secret;

  RequestEncryptionUtil(this.secret);

  /// Encrypts the payload using a simple XOR cipher (for demonstration).
  /// In production, use a proper encryption algorithm.
  String encrypt(String data) {
    final key = utf8.encode(secret);
    final bytes = utf8.encode(data);
    final encrypted = List<int>.generate(bytes.length, (i) => bytes[i] ^ key[i % key.length]);
    return base64Encode(encrypted);
  }

  /// Decrypts the payload.
  String decrypt(String encrypted) {
    final key = utf8.encode(secret);
    final bytes = base64Decode(encrypted);
    final decrypted = List<int>.generate(bytes.length, (i) => bytes[i] ^ key[i % key.length]);
    return utf8.decode(decrypted);
  }
}

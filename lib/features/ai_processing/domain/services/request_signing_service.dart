import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:revision/core/utils/security_utils.dart';
import 'package:revision/core/config/env_config.dart';
import 'dart:math';

/// Service for signing API requests to ensure security and authenticity
class RequestSigningService {
  static const String _signatureHeader = 'X-Signature';
  static const String _timestampHeader = 'X-Timestamp';
  static const String _nonceHeader = 'X-Nonce';
  static const String _authHeader = 'Authorization';

  /// Signs an API request with HMAC authentication
  static Map<String, String> signRequest({
    required String method,
    required String path,
    required Map<String, String> headers,
    required String body,
    String? customSecret,
  }) {
    // Use custom secret or derive from API key
    final secret = customSecret ?? _deriveSecret();
    
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final nonce = _generateNonce();
    
    // Create the signature
    final signature = SecurityUtils.generateHmacSignature(
      secret,
      method,
      path,
      headers,
      body,
    );
    
    // Create signed headers
    final signedHeaders = Map<String, String>.from(headers);
    signedHeaders[_signatureHeader] = signature;
    signedHeaders[_timestampHeader] = timestamp;
    signedHeaders[_nonceHeader] = nonce;
    
    // Add authorization header if API key is available
    final apiKey = EnvConfig.geminiApiKey;
    if (apiKey != null) {
      signedHeaders[_authHeader] = 'Bearer $apiKey';
    }
    
    return signedHeaders;
  }

  /// Validates a signed request
  static bool validateSignature({
    required String method,
    required String path,
    required Map<String, String> headers,
    required String body,
    String? customSecret,
  }) {
    try {
      final receivedSignature = headers[_signatureHeader];
      final timestamp = headers[_timestampHeader];
      final nonce = headers[_nonceHeader];
      
      if (receivedSignature == null || timestamp == null || nonce == null) {
        return false;
      }
      
      // Check timestamp (prevent replay attacks)
      final requestTime = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
      final now = DateTime.now();
      const maxAge = Duration(minutes: 5);
      
      if (now.difference(requestTime).abs() > maxAge) {
        return false;
      }
      
      // Regenerate signature and compare
      final secret = customSecret ?? _deriveSecret();
      final expectedSignature = SecurityUtils.generateHmacSignature(
        secret,
        method,
        path,
        headers,
        body,
      );
      
      return receivedSignature == expectedSignature;
    } catch (e) {
      return false;
    }
  }

  /// Encrypts image data for secure transmission
  static Uint8List encryptImageData(Uint8List imageData, String? encryptionKey) {
    if (encryptionKey == null || encryptionKey.isEmpty) {
      return imageData; // No encryption if key not provided
    }
    
    try {
      // Simple encryption for demo - use proper AES in production
      final keyBytes = sha256.convert(utf8.encode(encryptionKey)).bytes;
      final encrypted = <int>[];
      
      for (int i = 0; i < imageData.length; i++) {
        encrypted.add(imageData[i] ^ keyBytes[i % keyBytes.length]);
      }
      
      return Uint8List.fromList(encrypted);
    } catch (e) {
      throw Exception('Failed to encrypt image data: $e');
    }
  }

  /// Decrypts image data after secure transmission
  static Uint8List decryptImageData(Uint8List encryptedData, String? encryptionKey) {
    if (encryptionKey == null || encryptionKey.isEmpty) {
      return encryptedData; // No decryption if key not provided
    }
    
    try {
      // Simple decryption for demo - use proper AES in production
      final keyBytes = sha256.convert(utf8.encode(encryptionKey)).bytes;
      final decrypted = <int>[];
      
      for (int i = 0; i < encryptedData.length; i++) {
        decrypted.add(encryptedData[i] ^ keyBytes[i % keyBytes.length]);
      }
      
      return Uint8List.fromList(decrypted);
    } catch (e) {
      throw Exception('Failed to decrypt image data: $e');
    }
  }

  /// Generates a secure request ID for tracking
  static String generateRequestId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = _generateNonce();
    return '$timestamp-$random';
  }

  /// Derives a secret key from the API key
  static String _deriveSecret() {
    final apiKey = EnvConfig.geminiApiKey;
    if (apiKey == null) {
      throw Exception('API key not configured');
    }
    
    // Derive a secret from the API key
    final bytes = utf8.encode(apiKey);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generates a cryptographically secure nonce
  static String _generateNonce() {
    final random = Random.secure();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(32, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// Creates a secure request context
  static Map<String, dynamic> createRequestContext({
    required String operation,
    required String userId,
    Map<String, dynamic>? metadata,
  }) {
    return {
      'requestId': generateRequestId(),
      'operation': operation,
      'userId': userId,
      'timestamp': DateTime.now().toIso8601String(),
      'metadata': metadata ?? {},
    };
  }
}

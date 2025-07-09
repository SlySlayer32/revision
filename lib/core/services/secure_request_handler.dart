import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Adds request signing, metadata, and security headers.
class SecureRequestHandler {
  final String apiKey;
  final String secret;

  SecureRequestHandler({required this.apiKey, required this.secret});

  /// Signs the request body using HMAC-SHA256.
  String signRequest(Map<String, dynamic> body) {
    final jsonBody = jsonEncode(body);
    final hmac = Hmac(sha256, utf8.encode(secret));
    return hmac.convert(utf8.encode(jsonBody)).toString();
  }

  /// Returns security headers for the request.
  Map<String, String> getSecurityHeaders() {
    return {
      'X-Request-Signature': signRequest({}),
      'X-Request-Id': DateTime.now().millisecondsSinceEpoch.toString(),
    };
  }
}

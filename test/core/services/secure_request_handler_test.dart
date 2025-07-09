import 'package:flutter_test/flutter_test.dart';
import 'package:revision/core/services/secure_request_handler.dart';

void main() {
  test('signs request body with HMAC', () {
    final handler = SecureRequestHandler(apiKey: 'key', secret: 'secret');
    final signature = handler.signRequest({'foo': 'bar'});
    expect(signature.length, 64);
  });

  test('provides security headers', () {
    final handler = SecureRequestHandler(apiKey: 'key', secret: 'secret');
    final headers = handler.getSecurityHeaders();
    expect(headers, contains('X-Request-Signature'));
    expect(headers, contains('X-Request-Id'));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:revision/core/services/rate_limiting_service.dart';

void main() {
  test('rate limiting allows up to maxRequests in window', () async {
    final limiter = RateLimitingService(maxRequests: 2, window: Duration(seconds: 1));
    expect(limiter.allow('test'), isTrue);
    expect(limiter.allow('test'), isTrue);
    expect(limiter.allow('test'), isFalse);
    await Future.delayed(Duration(seconds: 1));
    expect(limiter.allow('test'), isTrue);
  });
}

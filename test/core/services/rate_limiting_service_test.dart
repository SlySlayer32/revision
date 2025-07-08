import 'package:flutter_test/flutter_test.dart';
import 'package:revision/core/services/rate_limiting_service.dart';

void main() {
  group('RateLimitingService', () {
    late RateLimitingService rateLimitingService;

    setUp(() {
      rateLimitingService = RateLimitingService.instance;
    });

    group('isRateLimited', () {
      test('returns false for new operation', () {
        expect(rateLimitingService.isRateLimited('test_operation'), isFalse);
      });

      test('returns true when rate limit is exceeded', () {
        final limiter = rateLimitingService.getLimiter('test_operation');
        
        // Simulate exceeding rate limit
        for (int i = 0; i < limiter.maxRequests; i++) {
          limiter.recordRequest();
        }
        
        expect(rateLimitingService.isRateLimited('test_operation'), isTrue);
      });
    });

    group('executeWithRateLimit', () {
      test('executes function when rate limit is not exceeded', () async {
        var executed = false;
        
        await rateLimitingService.executeWithRateLimit(
          'test_operation',
          () async {
            executed = true;
            return 'success';
          },
        );
        
        expect(executed, isTrue);
      });

      test('throws RateLimitExceededException when rate limit is exceeded', () async {
        final limiter = rateLimitingService.getLimiter('test_operation');
        
        // Exceed rate limit
        for (int i = 0; i < limiter.maxRequests; i++) {
          limiter.recordRequest();
        }
        
        expect(
          () => rateLimitingService.executeWithRateLimit(
            'test_operation',
            () async => 'should not execute',
          ),
          throwsA(isA<RateLimitExceededException>()),
        );
      });
    });

    group('resetLimiter', () {
      test('resets rate limiter for operation', () {
        final limiter = rateLimitingService.getLimiter('test_operation');
        
        // Exceed rate limit
        for (int i = 0; i < limiter.maxRequests; i++) {
          limiter.recordRequest();
        }
        
        expect(rateLimitingService.isRateLimited('test_operation'), isTrue);
        
        // Reset limiter
        rateLimitingService.resetLimiter('test_operation');
        
        expect(rateLimitingService.isRateLimited('test_operation'), isFalse);
      });
    });
  });

  group('RateLimiter', () {
    late RateLimiter rateLimiter;

    setUp(() {
      rateLimiter = RateLimiter(
        maxRequests: 3,
        window: const Duration(seconds: 1),
        operation: 'test',
      );
    });

    group('isLimited', () {
      test('returns false when under limit', () {
        expect(rateLimiter.isLimited(), isFalse);
        
        rateLimiter.recordRequest();
        expect(rateLimiter.isLimited(), isFalse);
      });

      test('returns true when at limit', () {
        for (int i = 0; i < rateLimiter.maxRequests; i++) {
          rateLimiter.recordRequest();
        }
        
        expect(rateLimiter.isLimited(), isTrue);
      });
    });

    group('getRetryAfter', () {
      test('returns zero duration when no requests recorded', () {
        expect(rateLimiter.getRetryAfter(), equals(Duration.zero));
      });

      test('returns duration until rate limit resets', () {
        rateLimiter.recordRequest();
        final retryAfter = rateLimiter.getRetryAfter();
        
        expect(retryAfter.inMilliseconds, greaterThan(0));
        expect(retryAfter.inMilliseconds, lessThanOrEqualTo(1000));
      });
    });

    group('reset', () {
      test('clears all recorded requests', () {
        for (int i = 0; i < rateLimiter.maxRequests; i++) {
          rateLimiter.recordRequest();
        }
        
        expect(rateLimiter.isLimited(), isTrue);
        
        rateLimiter.reset();
        
        expect(rateLimiter.isLimited(), isFalse);
      });
    });
  });
}
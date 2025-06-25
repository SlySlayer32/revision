// VGV-compliant circuit breaker tests
// Following Very Good Ventures testing patterns

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:revision/core/error/exceptions.dart';
import 'package:revision/core/services/circuit_breaker.dart';

void main() {
  group('CircuitBreaker', () {
    late CircuitBreaker circuitBreaker;

    setUp(() {
      circuitBreaker = CircuitBreaker(
        failureThreshold: 3,
        timeout: const Duration(seconds: 5),
        resetTimeout: const Duration(seconds: 60),
      );
    });

    tearDown(() {
      circuitBreaker.dispose();
    });

    group('Closed State', () {
      test('should be in closed state initially', () {
        expect(circuitBreaker.state, CircuitBreakerState.closed);
        expect(circuitBreaker.failureCount, 0);
      });

      test('should execute operation when circuit is closed', () async {
        final result = await circuitBreaker.execute(() async => 'test result');

        expect(result, 'test result');
        expect(circuitBreaker.state, CircuitBreakerState.closed);
      });

      test('should increment failure count on failure', () async {
        try {
          await circuitBreaker.execute(() async {
            throw Exception('Test failure');
          });
        } catch (e) {
          // Expected to fail
        }

        expect(circuitBreaker.failureCount, 1);
        expect(circuitBreaker.state, CircuitBreakerState.closed);
      });
    });

    group('Open State', () {
      test('should open circuit after threshold failures', () async {
        // Exceed failure threshold
        for (var i = 0; i < 3; i++) {
          try {
            await circuitBreaker.execute(() async {
              throw Exception('Test failure $i');
            });
          } catch (e) {
            // Expected to fail
          }
        }

        expect(circuitBreaker.state, CircuitBreakerState.open);
      });

      test('should throw NetworkException with specific message when open',
          () async {
        // Force circuit to open
        for (var i = 0; i < 3; i++) {
          try {
            await circuitBreaker.execute(() async {
              throw Exception('Test failure $i');
            });
          } catch (e) {
            // Expected to fail
          }
        }

        expect(
          () => circuitBreaker.execute(() async => 'success'),
          throwsA(
            isA<NetworkException>().having(
              (e) => e.message,
              'message',
              'Circuit breaker is open',
            ),
          ),
        );
      });

      test('should open circuit when failures meet threshold exactly',
          () async {
        // Re-initialize with a lower threshold for this specific test
        circuitBreaker = CircuitBreaker(
          failureThreshold: 2,
          timeout: const Duration(seconds: 5),
          resetTimeout: const Duration(seconds: 60),
        );
        try {
          await circuitBreaker.execute(() async => throw Exception('Fail 1'));
        } catch (_) {}
        try {
          await circuitBreaker.execute(() async => throw Exception('Fail 2'));
        } catch (_) {}

        expect(circuitBreaker.state, CircuitBreakerState.open);
        expect(circuitBreaker.failureCount, 2);
      });
    });

    group('Half-Open State', () {
      setUp(() {
        // Re-initialize with shorter reset timeout for these tests
        circuitBreaker = CircuitBreaker(
          failureThreshold: 1,
          timeout: const Duration(milliseconds: 100),
          resetTimeout: const Duration(milliseconds: 200),
        );
      });

      test(
          'should transition to half-open after resetTimeout and allow one trial request (success)',
          () async {
        // 1. Force circuit to open
        try {
          await circuitBreaker.execute(() async => throw Exception('Failure'));
        } catch (e) {
          // Expected
        }
        expect(circuitBreaker.state, CircuitBreakerState.open);

        // 2. Wait for resetTimeout to elapse
        await Future<void>.delayed(const Duration(milliseconds: 250));

        // 3. Circuit should be half-open and allow a trial request
        // This execute call should make it half-open internally
        final result =
            await circuitBreaker.execute(() async => 'trial success');
        expect(result, 'trial success');
        expect(circuitBreaker.state, CircuitBreakerState.closed);
        expect(circuitBreaker.failureCount, 0);
      });

      test(
          'should transition to half-open and then back to open if trial request fails',
          () async {
        // 1. Force circuit to open
        try {
          await circuitBreaker.execute(() async => throw Exception('Failure'));
        } catch (e) {
          // Expected
        }
        expect(circuitBreaker.state, CircuitBreakerState.open);

        // 2. Wait for resetTimeout to elapse
        await Future<void>.delayed(const Duration(milliseconds: 250));

        // 3. Circuit should be half-open, attempt a trial request that fails
        try {
          await circuitBreaker
              .execute(() async => throw Exception('Trial failure'));
        } catch (e) {
          // Expected
        }
        expect(circuitBreaker.state, CircuitBreakerState.open);
        expect(
          circuitBreaker.failureCount,
          1,
        ); // Resets to 1 after trial failure

        // 4. Subsequent requests should still be blocked
        expect(
          () => circuitBreaker.execute(() async => 'another attempt'),
          throwsA(isA<NetworkException>()),
        );
      });

      test(
          'should remain open if requests are made before resetTimeout elapses',
          () async {
        // 1. Force circuit to open
        try {
          await circuitBreaker.execute(() async => throw Exception('Failure'));
        } catch (e) {
          // Expected
        }
        expect(circuitBreaker.state, CircuitBreakerState.open);

        // 2. Attempt request before resetTimeout
        await Future<void>.delayed(
          const Duration(milliseconds: 50),
        ); // Less than resetTimeout
        expect(
          () => circuitBreaker.execute(() async => 'early attempt'),
          throwsA(isA<NetworkException>()),
        );
        expect(circuitBreaker.state, CircuitBreakerState.open);
      });
    });

    group('Success Handling', () {
      test('should reset failure count on success', () async {
        // Add some failures
        try {
          await circuitBreaker.execute(() async {
            throw Exception('Test failure');
          });
        } catch (e) {
          // Expected to fail
        }

        expect(circuitBreaker.failureCount, 1);

        // Execute successful operation
        final result = await circuitBreaker.execute(() async => 'success');

        expect(result, 'success');
        expect(circuitBreaker.failureCount, 0);
        expect(circuitBreaker.state, CircuitBreakerState.closed);
      });
    });

    group('Reset Functionality', () {
      test('should reset circuit breaker manually', () async {
        // Force circuit to open
        for (var i = 0; i < 3; i++) {
          try {
            await circuitBreaker.execute(() async {
              throw Exception('Test failure $i');
            });
          } catch (e) {
            // Expected to fail
          }
        }

        expect(circuitBreaker.state, CircuitBreakerState.open);

        // Reset manually
        circuitBreaker.reset();

        expect(circuitBreaker.state, CircuitBreakerState.closed);
        expect(circuitBreaker.failureCount, 0);
      });
    });

    group('Timeout Handling', () {
      test('should handle operation timeout', () async {
        expect(
          () => circuitBreaker.execute(() async {
            await Future<void>.delayed(const Duration(seconds: 10));
            return 'delayed result';
          }),
          throwsA(isA<TimeoutException>()),
        );
      });

      test('should complete if operation finishes just within timeout',
          () async {
        circuitBreaker =
            CircuitBreaker(timeout: const Duration(milliseconds: 200));
        final result = await circuitBreaker.execute(() async {
          await Future<void>.delayed(const Duration(milliseconds: 150));
          return 'fast enough';
        });
        expect(result, 'fast enough');
      });

      test('should timeout if operation finishes just after timeout', () async {
        circuitBreaker =
            CircuitBreaker(timeout: const Duration(milliseconds: 100));
        expect(
          () => circuitBreaker.execute(() async {
            await Future<void>.delayed(const Duration(milliseconds: 150));
            return 'too slow';
          }),
          throwsA(isA<TimeoutException>()),
        );
      });
    });

    group('Edge Cases', () {
      test('should handle concurrent executions safely', () async {
        final futures = List.generate(
          5,
          (index) => circuitBreaker.execute(() async => 'result $index'),
        );

        final results = await Future.wait(futures);

        expect(results.length, 5);
        for (var i = 0; i < 5; i++) {
          expect(results[i], 'result $i');
        }
      });

      test('should handle zero failure threshold', () {
        final circuitBreaker = CircuitBreaker(
          failureThreshold: 0,
          resetTimeout: const Duration(seconds: 1),
        );

        expect(circuitBreaker.failureThreshold, 0);
        circuitBreaker.dispose();
      });
    });

    group('Resource Management', () {
      test('should dispose resources properly', () {
        final circuitBreaker = CircuitBreaker();

        expect(circuitBreaker.dispose, returnsNormally);
      });
    });
  });
}

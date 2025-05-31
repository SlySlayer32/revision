import 'package:flutter_test/flutter_test.dart';
import 'package:revision/core/utils/result.dart';

void main() {
  group('Result', () {
    group('Success', () {
      test('should create success result with value', () {
        const value = 'test value';
        const result = Success<String>(value);

        expect(result.value, equals(value));
        expect(result.isSuccess, isTrue);
        expect(result.isFailure, isFalse);
      });

      test('should support value comparisons', () {
        const value = 'test value';
        const result1 = Success<String>(value);
        const result2 = Success<String>(value);

        expect(result1.data, equals(result2.data));
      });

      test('should return value from valueOrNull', () {
        const value = 'test value';
        const result = Success<String>(value);

        expect(result.valueOrNull, equals(value));
      });
      test('should return null from exceptionOrNull', () {
        const value = 'test value';
        const result = Success<String>(value);

        expect(result.exceptionOrNull, isNull);
      });

      test('should execute success callback in when', () {
        const value = 'test value';
        const result = Success<String>(value);
        var successCalled = false;
        var failureCalled = false;

        result.when(
          success: (v) {
            successCalled = true;
            expect(v, equals(value));
          },
          failure: (_) => failureCalled = true,
        );

        expect(successCalled, isTrue);
        expect(failureCalled, isFalse);
      });

      test('should return success result from fold', () {
        const value = 'test value';
        const result = Success<String>(value);

        final mapped = result.fold<String>(
          success: (value) => value.toUpperCase(),
          failure: (exception) => 'error',
        );

        expect(mapped, equals('TEST VALUE'));
      });
    });

    group('Failure', () {
      test('should create failure result with exception', () {
        final exception = Exception('test error');
        final result = Failure<String>(exception);

        expect(result.exception, equals(exception));
        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
      });

      test('should support exception comparisons', () {
        final exception = Exception('test error');
        final result1 = Failure<String>(exception);
        final result2 = Failure<String>(exception);

        expect(result1.exception, equals(result2.exception));
      });

      test('should return null from valueOrNull', () {
        final exception = Exception('test error');
        final result = Failure<String>(exception);

        expect(result.valueOrNull, isNull);
      });

      test('should return exception from exceptionOrNull', () {
        final exception = Exception('test error');
        final result = Failure<String>(exception);

        expect(result.exceptionOrNull, equals(exception));
      });

      test('should execute failure callback in when', () {
        final exception = Exception('test error');
        final result = Failure<String>(exception);
        var successCalled = false;
        var failureCalled = false;

        result.when(
          success: (_) => successCalled = true,
          failure: (e) {
            failureCalled = true;
            expect(e, equals(exception));
          },
        );

        expect(successCalled, isFalse);
        expect(failureCalled, isTrue);
      });

      test('should return failure result from fold', () {
        final exception = Exception('test error');
        final result = Failure<String>(exception);

        final mapped = result.fold<String>(
          success: (value) => value.toUpperCase(),
          failure: (exception) => 'error',
        );

        expect(mapped, equals('error'));
      });
    });
    group('map', () {
      test('should transform success value', () {
        const value = 'test';
        const result = Success<String>(value);

        final mapped = result.map<String>((value) => value.toUpperCase());

        expect(mapped, isA<Success<String>>());
        expect(mapped.valueOrNull, equals('TEST'));
      });

      test('should preserve failure when mapping', () {
        final exception = Exception('test error');
        final result = Failure<String>(exception);

        final mapped = result.map<String>((value) => value.toUpperCase());

        expect(mapped, isA<Failure<String>>());
        expect(mapped.exceptionOrNull, equals(exception));
      });
    });

    group('mapError', () {
      test('should preserve success when mapping error', () {
        const value = 'test';
        const result = Success<String>(value);

        final mapped = result.mapError(
          (exception) => Exception('new error'),
        );

        expect(mapped, isA<Success<String>>());
        expect(mapped.valueOrNull, equals(value));
      });

      test('should transform failure exception', () {
        final originalException = Exception('original error');
        final result = Failure<String>(originalException);
        final newException = Exception('new error');

        final mapped = result.mapError((_) => newException);

        expect(mapped, isA<Failure<String>>());
        expect(mapped.exceptionOrNull, equals(newException));
      });
    });

    group('flatMap', () {
      test('should chain success results', () {
        const value = 'test';
        const result = Success<String>(value);

        final chained = result.flatMap<String>(
          (value) => Success<String>(value.toUpperCase()),
        );

        expect(chained, isA<Success<String>>());
        expect(chained.valueOrNull, equals('TEST'));
      });

      test('should preserve failure when chaining', () {
        final exception = Exception('test error');
        final result = Failure<String>(exception);

        final chained = result.flatMap<String>(
          (value) => Success<String>(value.toUpperCase()),
        );

        expect(chained, isA<Failure<String>>());
        expect(chained.exceptionOrNull, equals(exception));
      });

      test('should propagate chained failure', () {
        const value = 'test';
        const result = Success<String>(value);
        final exception = Exception('chain error');

        final chained = result.flatMap<String>(
          (_) => Failure<String>(exception),
        );

        expect(chained, isA<Failure<String>>());
        expect(chained.exceptionOrNull, equals(exception));
      });
    });
  });
}

// VGV-compliant either extensions tests
// Following Very Good Ventures testing patterns

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revision/core/error/failures.dart';
import 'package:revision/core/utils/either_extensions.dart';

void main() {
  group('EitherExtensions', () {
    group('isLeft', () {
      test('should return true for Left values', () {
        const either = Left<Failure, String>(AuthenticationFailure('error'));
        expect(either.isLeft(), isTrue);
      });

      test('should return false for Right values', () {
        const either = Right<Failure, String>('success');
        expect(either.isLeft(), isFalse);
      });
    });

    group('isRight', () {
      test('should return true for Right values', () {
        const either = Right<Failure, String>('success');
        expect(either.isRight(), isTrue);
      });

      test('should return false for Left values', () {
        const either = Left<Failure, String>(AuthenticationFailure('error'));
        expect(either.isRight(), isFalse);
      });
    });

    group('leftOrNull', () {
      test('should return left value for Left instances', () {
        const failure = AuthenticationFailure('test error');
        const either = Left<Failure, String>(failure);
        expect(either.leftOrNull, equals(failure));
      });

      test('should return null for Right instances', () {
        const either = Right<Failure, String>('success');
        expect(either.leftOrNull, isNull);
      });
    });

    group('rightOrNull', () {
      test('should return right value for Right instances', () {
        const either = Right<Failure, String>('success');
        expect(either.rightOrNull, equals('success'));
      });

      test('should return null for Left instances', () {
        const either = Left<Failure, String>(AuthenticationFailure('error'));
        expect(either.rightOrNull, isNull);
      });
    });

    group('mapLeft', () {
      test('should transform left value for Left instances', () {
        const either = Left<Failure, String>(AuthenticationFailure('error'));
        final result = either.mapLeft(
          (failure) => const ValidationFailure('transformed'),
        );
        expect(result.isLeft(), isTrue);
        expect(result.leftOrNull, isA<ValidationFailure>());
        expect(result.leftOrNull?.message, equals('transformed'));
      });

      test('should not transform Right instances', () {
        const either = Right<Failure, String>('success');
        final result = either.mapLeft(
          (failure) => const ValidationFailure('transformed'),
        );

        expect(result, equals(either));
      });
    });

    group('mapRight', () {
      test('should transform right value for Right instances', () {
        const either = Right<Failure, String>('success');
        final result = either.mapRight((value) => value.toUpperCase());

        expect(result.isRight(), isTrue);
        expect(result.rightOrNull, equals('SUCCESS'));
      });

      test('should not transform Left instances', () {
        const either = Left<Failure, String>(AuthenticationFailure('error'));
        final result = either.mapRight((value) => value.toUpperCase());

        expect(result, equals(either));
      });
    });

    group('flatMapRight', () {
      test('should chain operations for Right instances', () {
        const either = Right<Failure, int>(5);
        final result = either.flatMapRight(
          (value) => Right<Failure, String>(value.toString()),
        );
        expect(result.isRight(), isTrue);
        expect(result.rightOrNull, equals('5'));
      });

      test('should propagate Left instances', () {
        const either = Left<Failure, int>(AuthenticationFailure('error'));
        final result = either.flatMapRight(
          (value) => Right<Failure, String>(value.toString()),
        );

        expect(result.isLeft(), isTrue);
        expect(result.leftOrNull, isA<AuthenticationFailure>());
      });

      test('should chain Left results', () {
        const either = Right<Failure, int>(5);
        final result = either.flatMapRight(
          (value) =>
              const Left<Failure, String>(ValidationFailure('chain error')),
        );

        expect(result.isLeft(), isTrue);
        expect(result.leftOrNull, isA<ValidationFailure>());
      });
    });

    group('flatMapLeft', () {
      test('should transform left value for Left instances', () {
        const either = Left<Failure, String>(AuthenticationFailure('error'));
        final result = either.flatMapLeft(
          (failure) => const Left<ValidationFailure, String>(
              ValidationFailure('transformed')),
        );
        expect(result.isLeft(), isTrue);
        expect(result.leftOrNull, isA<ValidationFailure>());
      });

      test('should not transform Right instances', () {
        const either = Right<Failure, String>('success');
        final result = either.flatMapLeft(
          (failure) => const Left<ValidationFailure, String>(
              ValidationFailure('transformed')),
        );

        expect(result.isRight(), isTrue);
        expect(result.rightOrNull, equals('success'));
      });
    });

    group('when', () {
      test('should call left function for Left instances', () {
        const either = Left<Failure, String>(AuthenticationFailure('error'));
        var leftCalled = false;
        var rightCalled = false;

        either.when(
          left: (failure) => leftCalled = true,
          right: (value) => rightCalled = true,
        );

        expect(leftCalled, isTrue);
        expect(rightCalled, isFalse);
      });

      test('should call right function for Right instances', () {
        const either = Right<Failure, String>('success');
        var leftCalled = false;
        var rightCalled = false;

        either.when(
          left: (failure) => leftCalled = true,
          right: (value) => rightCalled = true,
        );

        expect(leftCalled, isFalse);
        expect(rightCalled, isTrue);
      });

      test('should pass correct values to callbacks', () {
        const failure = AuthenticationFailure('test error');
        const either = Left<Failure, String>(failure);
        Failure? receivedFailure;

        either.when(
          left: (f) => receivedFailure = f,
          right: (value) {},
        );

        expect(receivedFailure, equals(failure));
      });
    });

    group('type safety', () {
      test('should maintain type safety with complex types', () {
        const either = Right<Failure, List<Map<String, int>>>([
          {'key1': 1, 'key2': 2},
          {'key3': 3},
        ]);

        expect(either.isRight(), isTrue);
        expect(either.rightOrNull?.length, equals(2));
        expect(either.rightOrNull?[0]['key1'], equals(1));
      });

      test('should handle null values in Right', () {
        const either = Right<Failure, String?>(null);
        expect(either.isRight(), isTrue);
        expect(either.rightOrNull, isNull);
      });

      test('should maintain type through transformations', () {
        const either = Right<Failure, String>('test');
        final mapped = either.mapRight((value) => value.length);

        expect(mapped.rightOrNull, isA<int>());
        expect(mapped.rightOrNull, equals(4));
      });
    });

    group('chaining operations', () {
      test('should chain multiple transformations', () {
        const either = Right<Failure, int>(5);

        final result = either
            .mapRight((value) => value * 2)
            .flatMapRight((value) => Right<Failure, String>('Number: $value'))
            .mapRight((value) => value.toUpperCase());
        expect(result.isRight(), isTrue);
        expect(result.rightOrNull, equals('NUMBER: 10'));
      });

      test('should stop chain on first Left', () {
        const either = Right<Failure, int>(5);

        final result = either
            .mapRight((value) => value * 2)
            .flatMapRight((value) =>
                const Left<Failure, String>(ValidationFailure('error')))
            .mapRight((value) => value.toUpperCase());

        expect(result.isLeft(), isTrue);
        expect(result.leftOrNull, isA<ValidationFailure>());
      });
    });
    group('edge cases', () {
      test('should handle empty strings', () {
        const either = Right<Failure, String>('');
        expect(either.isRight(), isTrue);
        expect(either.rightOrNull, equals(''));
      });

      test('should handle zero values', () {
        const either = Right<Failure, int>(0);
        expect(either.isRight(), isTrue);
        expect(either.rightOrNull, equals(0));
      });

      test('should handle boolean values', () {
        const leftEither = Right<Failure, bool>(false);
        const rightEither = Right<Failure, bool>(true);

        expect(leftEither.rightOrNull, isFalse);
        expect(rightEither.rightOrNull, isTrue);
      });
    });
  });
}

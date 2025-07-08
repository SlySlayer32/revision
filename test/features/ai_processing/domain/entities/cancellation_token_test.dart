import 'package:flutter_test/flutter_test.dart';
import 'package:revision/features/ai_processing/domain/entities/cancellation_token.dart';

void main() {
  group('CancellationToken', () {
    test('should be created in non-cancelled state', () {
      final token = CancellationToken();
      
      expect(token.isCancelled, isFalse);
      expect(token.reason, isNull);
      expect(token.cancelledAt, isNull);
    });

    test('should be cancelled when cancel is called', () {
      final token = CancellationToken();
      
      token.cancel('Test cancellation');
      
      expect(token.isCancelled, isTrue);
      expect(token.reason, equals('Test cancellation'));
      expect(token.cancelledAt, isNotNull);
    });

    test('should use default reason when none provided', () {
      final token = CancellationToken();
      
      token.cancel();
      
      expect(token.isCancelled, isTrue);
      expect(token.reason, equals('Operation cancelled'));
    });

    test('should not cancel multiple times', () {
      final token = CancellationToken();
      
      token.cancel('First reason');
      final firstCancelledAt = token.cancelledAt;
      
      token.cancel('Second reason');
      
      expect(token.reason, equals('First reason'));
      expect(token.cancelledAt, equals(firstCancelledAt));
    });

    test('should complete future when cancelled', () async {
      final token = CancellationToken();
      
      final futureCancelled = token.future;
      token.cancel('Test');
      
      await expectLater(futureCancelled, completes);
    });

    test('should throw when cancelled', () {
      final token = CancellationToken();
      
      token.cancel('Test cancellation');
      
      expect(
        () => token.throwIfCancelled(),
        throwsA(isA<OperationCancelledException>()),
      );
    });

    test('should not throw when not cancelled', () {
      final token = CancellationToken();
      
      expect(() => token.throwIfCancelled(), returnsNormally);
    });

    test('should create timeout token that cancels after duration', () async {
      final token = CancellationToken.timeout(Duration(milliseconds: 50));
      
      expect(token.isCancelled, isFalse);
      
      await Future.delayed(Duration(milliseconds: 100));
      
      expect(token.isCancelled, isTrue);
      expect(token.reason, equals('Operation timed out'));
    });

    test('should create combined token from multiple tokens', () {
      final token1 = CancellationToken();
      final token2 = CancellationToken();
      final token3 = CancellationToken();
      
      final combinedToken = CancellationToken.any([token1, token2, token3]);
      
      expect(combinedToken.isCancelled, isFalse);
      
      token2.cancel('Token 2 cancelled');
      
      expect(combinedToken.isCancelled, isTrue);
      expect(combinedToken.reason, equals('Token 2 cancelled'));
    });

    test('should create combined token from pre-cancelled token', () {
      final token1 = CancellationToken();
      final token2 = CancellationToken();
      
      token1.cancel('Pre-cancelled');
      
      final combinedToken = CancellationToken.any([token1, token2]);
      
      expect(combinedToken.isCancelled, isTrue);
      expect(combinedToken.reason, equals('Pre-cancelled'));
    });
  });

  group('CancellationTokenSource', () {
    test('should create token source with initial token', () {
      final source = CancellationTokenSource();
      
      expect(source.token, isNotNull);
      expect(source.isCancelled, isFalse);
    });

    test('should cancel token when source is cancelled', () {
      final source = CancellationTokenSource();
      final token = source.token;
      
      source.cancel('Source cancelled');
      
      expect(source.isCancelled, isTrue);
      expect(token.isCancelled, isTrue);
      expect(token.reason, equals('Source cancelled'));
    });

    test('should create new token when reset', () {
      final source = CancellationTokenSource();
      final originalToken = source.token;
      
      source.cancel('Test');
      source.reset();
      
      expect(source.token, isNot(equals(originalToken)));
      expect(source.isCancelled, isFalse);
      expect(originalToken.isCancelled, isTrue);
    });

    test('should cancel and reset in one operation', () {
      final source = CancellationTokenSource();
      final originalToken = source.token;
      
      source.cancelAndReset('Cancel and reset');
      
      expect(source.token, isNot(equals(originalToken)));
      expect(source.isCancelled, isFalse);
      expect(originalToken.isCancelled, isTrue);
      expect(originalToken.reason, equals('Cancel and reset'));
    });
  });

  group('OperationCancelledException', () {
    test('should create exception with message', () {
      const exception = OperationCancelledException('Test message');
      
      expect(exception.message, equals('Test message'));
      expect(exception.toString(), equals('OperationCancelledException: Test message'));
    });
  });
}
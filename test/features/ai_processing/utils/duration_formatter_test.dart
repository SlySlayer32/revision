import 'package:flutter_test/flutter_test.dart';
import 'package:revision/features/ai_processing/utils/duration_formatter.dart';

void main() {
  group('DurationFormatter', () {
    group('formatTimeRemaining', () {
      test('formats seconds only', () {
        const duration = Duration(seconds: 45);
        expect(DurationFormatter.formatTimeRemaining(duration), equals('45s'));
      });

      test('formats minutes and seconds', () {
        const duration = Duration(minutes: 2, seconds: 30);
        expect(
            DurationFormatter.formatTimeRemaining(duration), equals('2m 30s'));
      });

      test('formats zero duration', () {
        const duration = Duration.zero;
        expect(DurationFormatter.formatTimeRemaining(duration), equals('0s'));
      });

      test('formats exactly one minute', () {
        const duration = Duration(minutes: 1);
        expect(
            DurationFormatter.formatTimeRemaining(duration), equals('1m 0s'));
      });

      test('formats large durations in minutes and seconds', () {
        const duration = Duration(hours: 1, minutes: 30, seconds: 45);
        expect(
            DurationFormatter.formatTimeRemaining(duration), equals('90m 45s'));
      });
    });

    group('formatVerbose', () {
      test('formats hours, minutes, and seconds', () {
        const duration = Duration(hours: 1, minutes: 5, seconds: 30);
        expect(DurationFormatter.formatVerbose(duration), equals('1h 5m 30s'));
      });

      test('formats minutes and seconds only', () {
        const duration = Duration(minutes: 5, seconds: 30);
        expect(DurationFormatter.formatVerbose(duration), equals('5m 30s'));
      });

      test('formats seconds only', () {
        const duration = Duration(seconds: 30);
        expect(DurationFormatter.formatVerbose(duration), equals('30s'));
      });

      test('formats zero duration', () {
        const duration = Duration.zero;
        expect(DurationFormatter.formatVerbose(duration), equals('0s'));
      });
    });

    group('formatCompact', () {
      test('formats hours with padding', () {
        const duration = Duration(hours: 1, minutes: 5, seconds: 30);
        expect(DurationFormatter.formatCompact(duration), equals('1:05:30'));
      });

      test('formats minutes and seconds with padding', () {
        const duration = Duration(minutes: 5, seconds: 30);
        expect(DurationFormatter.formatCompact(duration), equals('5:30'));
      });

      test('formats with zero seconds', () {
        const duration = Duration(minutes: 5);
        expect(DurationFormatter.formatCompact(duration), equals('5:00'));
      });

      test('formats zero duration', () {
        const duration = Duration.zero;
        expect(DurationFormatter.formatCompact(duration), equals('0:00'));
      });

      test('formats large durations', () {
        const duration = Duration(hours: 10, minutes: 25, seconds: 5);
        expect(DurationFormatter.formatCompact(duration), equals('10:25:05'));
      });
    });
  });
}

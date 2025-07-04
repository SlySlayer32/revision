import 'package:flutter_test/flutter_test.dart';
import 'package:revision/core/navigation/route_names.dart';
import 'package:revision/core/navigation/route_factory.dart';
import 'package:revision/core/utils/null_safety_utils.dart';
import 'package:revision/core/utils/navigation_utils.dart';

void main() {
  group('Null Safety Fixes Verification', () {
    test('RouteNames should have valid route definitions', () {
      expect(RouteNames.login, equals('/login'));
      expect(RouteNames.signup, equals('/signup'));
      expect(RouteNames.dashboard, equals('/dashboard'));
      expect(RouteNames.welcome, equals('/welcome'));
      expect(RouteNames.imageSelection, equals('/image-selection'));
      expect(RouteNames.aiProcessing, equals('/ai-processing'));
    });

    test('RouteNames validation should work correctly', () {
      expect(RouteNames.isValidRoute('/login'), isTrue);
      expect(RouteNames.isValidRoute('/invalid-route'), isFalse);
      expect(RouteNames.isValidRoute(''), isFalse);
    });

    test('RouteNames display names should be generated correctly', () {
      expect(RouteNames.getDisplayName('/login'), equals('Login'));
      expect(RouteNames.getDisplayName('/dashboard'), equals('Dashboard'));
      expect(RouteNames.getDisplayName('/image-selection'), equals('Image Selection'));
      expect(RouteNames.getDisplayName('/unknown-route'), equals('unknown route'));
    });

    test('NullSafetyUtils should handle null strings correctly', () {
      expect(NullSafetyUtils.safeString(null), equals(''));
      expect(NullSafetyUtils.safeString(null, fallback: 'default'), equals('default'));
      expect(NullSafetyUtils.safeString('test'), equals('test'));
    });

    test('NullSafetyUtils should handle null numbers correctly', () {
      expect(NullSafetyUtils.safeInt(null), equals(0));
      expect(NullSafetyUtils.safeInt(null, fallback: 42), equals(42));
      expect(NullSafetyUtils.safeInt(123), equals(123));

      expect(NullSafetyUtils.safeDouble(null), equals(0.0));
      expect(NullSafetyUtils.safeDouble(null, fallback: 3.14), equals(3.14));
      expect(NullSafetyUtils.safeDouble(2.5), equals(2.5));
    });

    test('NullSafetyUtils should handle null booleans correctly', () {
      expect(NullSafetyUtils.safeBool(null), equals(false));
      expect(NullSafetyUtils.safeBool(null, fallback: true), equals(true));
      expect(NullSafetyUtils.safeBool(true), equals(true));
    });

    test('NullSafetyUtils should handle null collections correctly', () {
      expect(NullSafetyUtils.safeList<String>(null), equals(<String>[]));
      expect(NullSafetyUtils.safeList<int>([1, 2, 3]), equals([1, 2, 3]));

      expect(NullSafetyUtils.safeMap<String, int>(null), equals(<String, int>{}));
      expect(NullSafetyUtils.safeMap<String, int>({'a': 1}), equals({'a': 1}));
    });

    test('NullSafetyUtils should validate null checks correctly', () {
      expect(NullSafetyUtils.isStringNullOrEmpty(null), isTrue);
      expect(NullSafetyUtils.isStringNullOrEmpty(''), isTrue);
      expect(NullSafetyUtils.isStringNullOrEmpty('test'), isFalse);

      expect(NullSafetyUtils.isNullOrWhitespace(null), isTrue);
      expect(NullSafetyUtils.isNullOrWhitespace(''), isTrue);
      expect(NullSafetyUtils.isNullOrWhitespace('   '), isTrue);
      expect(NullSafetyUtils.isNullOrWhitespace('test'), isFalse);

      expect(NullSafetyUtils.isCollectionNullOrEmpty<String>(null), isTrue);
      expect(NullSafetyUtils.isCollectionNullOrEmpty<String>([]), isTrue);
      expect(NullSafetyUtils.isCollectionNullOrEmpty<String>(['test']), isFalse);
    });

    test('NullSafetyUtils should handle parsing correctly', () {
      expect(NullSafetyUtils.parseInt('123'), equals(123));
      expect(NullSafetyUtils.parseInt(null), equals(0));
      expect(NullSafetyUtils.parseInt('invalid'), equals(0));
      expect(NullSafetyUtils.parseInt('invalid', fallback: -1), equals(-1));

      expect(NullSafetyUtils.parseDouble('3.14'), equals(3.14));
      expect(NullSafetyUtils.parseDouble(null), equals(0.0));
      expect(NullSafetyUtils.parseDouble('invalid'), equals(0.0));
      expect(NullSafetyUtils.parseDouble('invalid', fallback: -1.0), equals(-1.0));
    });

    test('NullSafetyUtils should find first non-null value', () {
      expect(NullSafetyUtils.firstNonNull([null, null, 'found']), equals('found'));
      expect(NullSafetyUtils.firstNonNull([null, 'first', 'second']), equals('first'));
      expect(NullSafetyUtils.firstNonNull([null, null, null]), isNull);
    });

    test('NullSafetyUtils should format values for display', () {
      expect(NullSafetyUtils.formatForDisplay(null), equals('N/A'));
      expect(NullSafetyUtils.formatForDisplay(123), equals('123'));
      expect(NullSafetyUtils.formatForDisplay(null, nullDisplay: 'None'), equals('None'));
      expect(
        NullSafetyUtils.formatForDisplay(
          'test',
          formatter: (s) => s.toUpperCase(),
        ),
        equals('TEST'),
      );
    });

    test('NullSafetyUtils should safely convert to string', () {
      expect(NullSafetyUtils.safeToString(null), equals(''));
      expect(NullSafetyUtils.safeToString(123), equals('123'));
      expect(NullSafetyUtils.safeToString(null, fallback: 'default'), equals('default'));
    });

    test('NullSafetyUtils should require non-null values', () {
      expect(() => NullSafetyUtils.requireNonNull(null, message: 'Test error'), throwsArgumentError);
      expect(NullSafetyUtils.requireNonNull('value', message: 'Test error'), equals('value'));
    });
  });
}

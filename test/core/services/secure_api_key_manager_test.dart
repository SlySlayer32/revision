import 'package:flutter_test/flutter_test.dart';
import 'package:revision/core/services/secure_api_key_manager.dart';

void main() {
  group('SecureAPIKeyManager', () {
    test('validates correct API key', () {
      final manager = SecureAPIKeyManager('AIza123456789012345678901234567890');
      expect(manager.isValid(), isTrue);
    });

    test('invalidates short API key', () {
      final manager = SecureAPIKeyManager('short');
      expect(manager.isValid(), isFalse);
    });

    test('masks API key', () {
      final manager = SecureAPIKeyManager('AIza123456789012345678901234567890');
      expect(manager.masked(), startsWith('AIza'));
      expect(manager.masked(), endsWith('7890'));
    });

    test('hashes API key', () {
      final manager = SecureAPIKeyManager('AIza123456789012345678901234567890');
      expect(manager.hash().length, 64);
    });
  });
}

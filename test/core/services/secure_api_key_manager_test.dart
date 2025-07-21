import 'package:flutter_test/flutter_test.dart';
import 'package:revision/core/services/secure_api_key_manager.dart';
import 'package:revision/core/config/env_config.dart';

void main() {
  group('SecureAPIKeyManager', () {
    group('getSecureApiKey', () {
      test('returns null when API key is not configured', () {
        expect(SecureAPIKeyManager.getSecureApiKey(), isNull);
      });
    });

    group('getMaskedApiKey', () {
      test('masks short API key completely', () {
        const shortKey = 'ABC123';
        final masked = SecureAPIKeyManager.getMaskedApiKey(shortKey);
        expect(masked, equals('******'));
      });

      test('masks long API key with prefix and suffix visible', () {
        const longKey = 'AIzaSyDummyKeyFor32CharactersLong12345';
        final masked = SecureAPIKeyManager.getMaskedApiKey(longKey);
        expect(masked, startsWith('AIza'));
        expect(masked, endsWith('2345'));
        expect(masked, contains('*'));
      });
    });

    group('generateApiKeyHash', () {
      test('generates consistent hash for same key', () {
        const key = 'AIzaSyDummyKeyFor32CharactersLong12345';
        final hash1 = SecureAPIKeyManager.generateApiKeyHash(key);
        final hash2 = SecureAPIKeyManager.generateApiKeyHash(key);
        expect(hash1, equals(hash2));
      });

      test('generates different hash for different keys', () {
        const key1 = 'AIzaSyDummyKeyFor32CharactersLong12345';
        const key2 = 'AIzaSyAnotherKeyFor32CharactersLong678';
        final hash1 = SecureAPIKeyManager.generateApiKeyHash(key1);
        final hash2 = SecureAPIKeyManager.generateApiKeyHash(key2);
        expect(hash1, isNot(equals(hash2)));
      });
    });

    group('isApiKeyConfigured', () {
      test('returns false when no API key is set', () {
        expect(SecureAPIKeyManager.isApiKeyConfigured(), isFalse);
      });
    });

    group('getSecureDebugInfo', () {
      test('returns error info when API key is not configured', () {
        final info = SecureAPIKeyManager.getSecureDebugInfo();
        expect(info['configured'], isFalse);
        expect(info['error'], isNotNull);
      });
    });
  });
}

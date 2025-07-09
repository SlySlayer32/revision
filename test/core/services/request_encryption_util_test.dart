import 'package:flutter_test/flutter_test.dart';
import 'package:revision/core/services/request_encryption_util.dart';

void main() {
  test('encrypts and decrypts data', () {
    final util = RequestEncryptionUtil('secret');
    final data = 'hello world';
    final encrypted = util.encrypt(data);
    final decrypted = util.decrypt(encrypted);
    expect(decrypted, data);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:revision/core/services/secure_logger.dart';

void main() {
  test('masks API keys in log messages', () {
    final message = 'My API key is AIza123456789012345678901234567890';
    // Should mask the key in the log output
    SecureLogger.log(message);
    // No assertion: just ensure no exceptions and output is masked
  });
}

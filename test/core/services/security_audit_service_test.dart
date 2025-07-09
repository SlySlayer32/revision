import 'package:flutter_test/flutter_test.dart';
import 'package:revision/core/services/security_audit_service.dart';

void main() {
  test('logs security events', () {
    final audit = SecurityAuditService();
    audit.logEvent('API_KEY_VALIDATION', context: 'init', hash: 'abc123');
    expect(audit.events.length, 1);
    expect(audit.events.first, contains('API_KEY_VALIDATION'));
    expect(audit.events.first, contains('init'));
    expect(audit.events.first, contains('abc123'));
  });
}

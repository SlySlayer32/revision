import 'package:flutter_test/flutter_test.dart';
import 'package:revision/core/utils/validators.dart';
import 'package:revision/core/utils/security_utils.dart';

void main() {
  group('Enhanced Signup Validation Tests', () {
    test('validateEmail should use SecurityUtils', () {
      expect(Validators.validateEmail('test@example.com'), isNull);
      expect(Validators.validateEmail('invalid-email'), isNotNull);
      expect(Validators.validateEmail(''), isNotNull);
    });

    test('validatePassword should check strength', () {
      expect(Validators.validatePassword('password123'), isNotNull); // Should be too weak
      expect(Validators.validatePassword('Password123!'), isNull); // Should be strong enough
      expect(Validators.validatePassword(''), isNotNull); // Should be required
    });

    test('validatePhoneNumber should handle optional field', () {
      expect(Validators.validatePhoneNumber(null), isNull); // Optional
      expect(Validators.validatePhoneNumber(''), isNull); // Optional
      expect(Validators.validatePhoneNumber('123'), isNotNull); // Too short
      expect(Validators.validatePhoneNumber('1234567890'), isNull); // Valid
    });

    test('validateAge should require adult status', () {
      expect(Validators.validateAge(false), isNotNull);
      expect(Validators.validateAge(true), isNull);
    });

    test('validateTermsAcceptance should require acceptance', () {
      expect(Validators.validateTermsAcceptance(false), isNotNull);
      expect(Validators.validateTermsAcceptance(true), isNull);
    });

    test('validatePrivacyAcceptance should require acceptance', () {
      expect(Validators.validatePrivacyAcceptance(false), isNotNull);
      expect(Validators.validatePrivacyAcceptance(true), isNull);
    });

    test('validateSecurityQuestion should handle optional requirement', () {
      expect(Validators.validateSecurityQuestion(null, false), isNull);
      expect(Validators.validateSecurityQuestion(null, true), isNotNull);
      expect(Validators.validateSecurityQuestion('What is your pet?', true), isNull);
    });

    test('validateSecurityAnswer should handle optional requirement', () {
      expect(Validators.validateSecurityAnswer(null, false), isNull);
      expect(Validators.validateSecurityAnswer(null, true), isNotNull);
      expect(Validators.validateSecurityAnswer('My cat', true), isNull);
      expect(Validators.validateSecurityAnswer('AB', true), isNotNull); // Too short
    });

    test('SecurityUtils rate limiting should work', () {
      // This is a basic test - in real scenarios, you'd mock the time
      final identifier = 'test_${DateTime.now().millisecondsSinceEpoch}';
      
      // First few attempts should not be rate limited
      expect(SecurityUtils.isRateLimited(identifier, maxRequests: 3), isFalse);
      expect(SecurityUtils.isRateLimited(identifier, maxRequests: 3), isFalse);
      expect(SecurityUtils.isRateLimited(identifier, maxRequests: 3), isFalse);
      
      // Fourth attempt should be rate limited
      expect(SecurityUtils.isRateLimited(identifier, maxRequests: 3), isTrue);
    });

    test('SecurityUtils password strength should work correctly', () {
      expect(SecurityUtils.validatePasswordStrength('password'), PasswordStrength.weak);
      expect(SecurityUtils.validatePasswordStrength('Password123'), PasswordStrength.medium);
      expect(SecurityUtils.validatePasswordStrength('Password123!'), PasswordStrength.strong);
    });
  });
}
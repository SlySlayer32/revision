import 'package:flutter_test/flutter_test.dart';
import 'package:revision/core/utils/auth_security_utils.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';

void main() {
  group('AuthSecurityUtils', () {
    test('should categorize authentication errors correctly', () {
      // Test network errors
      expect(
        AuthSecurityUtils.categorizeAuthError(Exception('network error')),
        equals(AuthErrorCategory.network),
      );
      
      // Test timeout errors
      expect(
        AuthSecurityUtils.categorizeAuthError(Exception('timeout')),
        equals(AuthErrorCategory.network),
      );
      
      // Test credential errors
      expect(
        AuthSecurityUtils.categorizeAuthError(Exception('user-not-found')),
        equals(AuthErrorCategory.credential),
      );
      
      // Test rate limit errors
      expect(
        AuthSecurityUtils.categorizeAuthError(Exception('too-many-requests')),
        equals(AuthErrorCategory.rateLimit),
      );
      
      // Test unknown errors
      expect(
        AuthSecurityUtils.categorizeAuthError(Exception('unknown error')),
        equals(AuthErrorCategory.unknown),
      );
    });

    test('should sanitize user data for logging', () {
      // Test with null user
      final nullUserData = AuthSecurityUtils.sanitizeUserData(null);
      expect(nullUserData['hasUser'], equals(false));
      
      // Test with valid user
      const testUser = User(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
        photoUrl: null,
        isEmailVerified: true,
        createdAt: '2023-01-01T00:00:00.000Z',
        customClaims: {},
      );
      
      final userData = AuthSecurityUtils.sanitizeUserData(testUser);
      expect(userData['hasUser'], equals(true));
      expect(userData['userId'], equals('test-id'));
      expect(userData['userEmailHash'], equals('t***@example.com'));
      expect(userData['isEmailVerified'], equals(true));
    });

    test('should provide appropriate error messages', () {
      expect(
        AuthErrorCategory.network.userMessage,
        contains('Network connection issue'),
      );
      
      expect(
        AuthErrorCategory.credential.userMessage,
        contains('Invalid credentials'),
      );
      
      expect(
        AuthErrorCategory.rateLimit.userMessage,
        contains('Too many attempts'),
      );
    });

    test('should provide appropriate retry delays', () {
      expect(
        AuthErrorCategory.network.retryDelay,
        equals(const Duration(seconds: 5)),
      );
      
      expect(
        AuthErrorCategory.rateLimit.retryDelay,
        equals(const Duration(minutes: 1)),
      );
    });

    test('should check session timeout correctly', () {
      // Test recent activity
      final recentActivity = DateTime.now().subtract(const Duration(minutes: 5));
      expect(
        AuthSecurityUtils.isSessionTimedOut(recentActivity),
        equals(false),
      );
      
      // Test old activity
      final oldActivity = DateTime.now().subtract(const Duration(hours: 1));
      expect(
        AuthSecurityUtils.isSessionTimedOut(oldActivity),
        equals(true),
      );
      
      // Test null activity
      expect(
        AuthSecurityUtils.isSessionTimedOut(null),
        equals(true),
      );
    });
  });
}
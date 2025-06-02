// VGV-compliant test data factory
// Following Very Good Ventures testing patterns for consistent test data

import 'package:revision/features/authentication/domain/entities/user.dart';

/// VGV Test data factory for generating consistent test data
/// Uses static values for deterministic testing as per VGV standards
class VGVTestDataFactory {
  // VGV Pattern: Use const values for deterministic testing
  static const String testUserId = 'test-user-id-123';
  static const String testEmail = 'test@vgv.example.com';
  static const String testPassword = 'TestPass123!';
  static const String testDisplayName = 'VGV Test User';
  static const String testPhotoUrl = 'https://example.com/photo.jpg';
  static const String testCreatedAt = '2024-01-01T00:00:00.000Z';

  // Alternative test values
  static const String testUserId2 = 'test-user-id-456';
  static const String testEmail2 = 'test2@vgv.example.com';
  static const String testDisplayName2 = 'VGV Test User 2';

  /// Creates a VGV-compliant test user with default values
  static User createTestUser({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isEmailVerified,
    String? createdAt,
    Map<String, dynamic>? customClaims,
  }) {
    return User(
      id: id ?? testUserId,
      email: email ?? testEmail,
      displayName: displayName ?? testDisplayName,
      photoUrl: photoUrl ?? testPhotoUrl,
      isEmailVerified: isEmailVerified ?? true,
      createdAt: createdAt ?? testCreatedAt,
      customClaims: customClaims ?? const {'role': 'user'},
    );
  }

  /// Creates a second test user for testing multiple users
  static User createSecondTestUser({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isEmailVerified,
    String? createdAt,
    Map<String, dynamic>? customClaims,
  }) {
    return User(
      id: id ?? testUserId2,
      email: email ?? testEmail2,
      displayName: displayName ?? testDisplayName2,
      photoUrl: photoUrl ?? testPhotoUrl,
      isEmailVerified: isEmailVerified ?? true,
      createdAt: createdAt ?? testCreatedAt,
      customClaims: customClaims ?? const {'role': 'user'},
    );
  }

  /// Creates a user with unverified email for testing
  static User createUnverifiedUser({
    String? id,
    String? email,
    String? displayName,
  }) {
    return User(
      id: id ?? 'unverified-user-id',
      email: email ?? 'unverified@vgv.example.com',
      displayName: displayName ?? 'Unverified User',
      photoUrl: testPhotoUrl,
      isEmailVerified: false,
      createdAt: testCreatedAt,
      customClaims: const {'role': 'unverified'},
    );
  }

  /// Creates a user with admin role for testing
  static User createAdminUser({
    String? id,
    String? email,
    String? displayName,
  }) {
    return User(
      id: id ?? 'admin-user-id',
      email: email ?? 'admin@vgv.example.com',
      displayName: displayName ?? 'VGV Admin User',
      photoUrl: testPhotoUrl,
      isEmailVerified: true,
      createdAt: testCreatedAt,
      customClaims: const {
        'role': 'admin',
        'permissions': ['read', 'write', 'admin'],
      },
    );
  }

  /// Creates a list of test users
  static List<User> createTestUsers({int count = 3}) {
    final users = <User>[];
    for (var i = 0; i < count; i++) {
      users.add(
        createTestUser(
          id: 'test-user-id-$i',
          email: 'test$i@vgv.example.com',
          displayName: 'VGV Test User $i',
        ),
      );
    }
    return users;
  }

  // VGV Pattern: Exception test data
  static Exception createTestException([
    String message = 'VGV test exception',
  ]) {
    return Exception(message);
  }

  // VGV Pattern: Error messages for testing
  static const String errorInvalidEmail = 'Invalid email format';
  static const String errorWeakPassword = 'Password too weak';
  static const String errorUserNotFound = 'User not found';
  static const String errorEmailAlreadyInUse = 'Email already in use';
  static const String errorNetworkError = 'Network connection error';
  static const String errorUnknown = 'An unknown error occurred';
}

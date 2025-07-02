// VGV-compliant test data factory for creating test objects
// Following Very Good Ventures testing patterns

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:mocktail/mocktail.dart';
import 'package:revision/features/authentication/data/models/user_model.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';

class MockFirebaseUser extends Mock implements firebase_auth.User {}

/// VGV Test Data Factory for creating consistent test data
/// Provides factory methods for creating test objects following VGV patterns
class VGVTestDataFactory {
  /// Creates a test User entity with default or custom values
  static User createTestUser({
    String id = 'test-user-id',
    String email = 'test@example.com',
    String? displayName = 'Test User',
    bool isEmailVerified = true,
    String? photoUrl,
    String createdAt = '2023-01-01T00:00:00Z',
    Map<String, dynamic> customClaims = const {},
  }) {
    return User(
      id: id,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      isEmailVerified: isEmailVerified,
      createdAt: createdAt,
      customClaims: customClaims,
    );
  }

  /// Creates a test UserModel with default or custom values
  static UserModel createTestUserModel({
    String id = 'test-user-id',
    String email = 'test@example.com',
    String? displayName = 'Test User',
    bool isEmailVerified = true,
    String? photoUrl,
    String createdAt = '2023-01-01T00:00:00Z',
    Map<String, dynamic> customClaims = const {},
  }) {
    return UserModel(
      id: id,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      isEmailVerified: isEmailVerified,
      createdAt: createdAt,
      customClaims: customClaims,
    );
  }

  /// Creates a list of test users for bulk testing
  static List<User> createTestUserList([int count = 3]) {
    return List.generate(
      count,
      (index) => createTestUser(
        id: 'test-user-$index',
        email: 'user$index@example.com',
        displayName: 'Test User $index',
      ),
    );
  }

  /// Creates a mock Firebase User for testing
  static firebase_auth.User createMockFirebaseUser({
    String uid = 'test-user-id',
    String? email = 'test@example.com',
    String? displayName = 'Test User',
    bool emailVerified = true,
    String? photoURL,
    DateTime? creationTime,
  }) {
    final user = MockFirebaseUser();
    final metadata = MockUserMetadata();

    when(() => user.uid).thenReturn(uid);
    when(() => user.email).thenReturn(email);
    when(() => user.displayName).thenReturn(displayName);
    when(() => user.emailVerified).thenReturn(emailVerified);
    when(() => user.photoURL).thenReturn(photoURL);
    when(() => user.metadata).thenReturn(metadata);
    when(() => metadata.creationTime)
        .thenReturn(creationTime ?? DateTime.parse('2023-01-01T00:00:00Z'));

    return user;
  }

  /// Creates test authentication credentials
  static Map<String, String> createTestCredentials({
    String email = 'test@example.com',
    String password = 'testPassword123',
    String? displayName = 'Test User',
  }) {
    return {
      'email': email,
      'password': password,
      if (displayName != null) 'displayName': displayName,
    };
  }

  /// Creates test email/password combinations for various test scenarios
  static Map<String, String> createValidCredentials() {
    return createTestCredentials();
  }

  static Map<String, String> createInvalidEmailCredentials() {
    return createTestCredentials(email: 'invalid-email');
  }

  static Map<String, String> createWeakPasswordCredentials() {
    return createTestCredentials(password: '123');
  }

  /// Creates test user with admin role
  static User createTestAdminUser() {
    return createTestUser(
      id: 'admin-user-id',
      email: 'admin@example.com',
      displayName: 'Admin User',
      customClaims: {'role': 'admin'},
    );
  }

  /// Creates test user with standard role
  static User createTestStandardUser() {
    return createTestUser(
      id: 'standard-user-id',
      email: 'user@example.com',
      displayName: 'Standard User',
      customClaims: {'role': 'user'},
    );
  }

  /// Creates a user without email verification
  static User createUnverifiedUser() {
    return createTestUser(
      isEmailVerified: false,
      email: 'unverified@example.com',
    );
  }

  /// Creates a user with minimal data (only required fields)
  static User createMinimalUser() {
    return createTestUser(
      displayName: null,
      customClaims: {},
    );
  }

  /// VGV Test Constants
  static const String testEmail = 'test@example.com';
  static const String testPassword = 'testPassword123';
  static const String testDisplayName = 'Test User';
  static const String testUserId = 'test-user-id';
  static const String adminEmail = 'admin@example.com';
  static const String adminPassword = 'adminPassword123';
}

/// Mock UserMetadata class for Firebase Auth testing
class MockUserMetadata extends Mock implements firebase_auth.UserMetadata {}

import 'package:revision/features/authentication/domain/entities/user.dart';

class VGVTestDataFactory {
  static User createTestUser({
    String id = 'test-id',
    String email = 'test@example.com',
    String displayName = 'Test User',
    String? photoUrl,
    bool isEmailVerified = false,
    String? createdAt,
    Map<String, dynamic> customClaims = const {},
  }) {
    return User(
      id: id,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      isEmailVerified: isEmailVerified,
      createdAt: createdAt ?? DateTime.now().toIso8601String(),
      customClaims: customClaims,
    );
  }
}

import 'package:equatable/equatable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';

void main() {
  group('User Entity', () {
    const tUser = User(
      id: 'test-id',
      email: 'test@example.com',
      displayName: 'Test User',
      photoUrl: 'https://example.com/photo.jpg',
      isEmailVerified: true,
      createdAt: '2024-01-01T00:00:00Z',
      customClaims: {},
    );

    test('should be a subclass of Equatable', () {
      expect(tUser, isA<Equatable>());
    });

    test('should have correct props for equality', () {
      const otherUser = User(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
        photoUrl: 'https://example.com/photo.jpg',
        isEmailVerified: true,
        createdAt: '2024-01-01T00:00:00Z',
        customClaims: {},
      );

      expect(tUser, equals(otherUser));
      expect(tUser.hashCode, equals(otherUser.hashCode));
    });

    test('should return correct props', () {
      expect(
        tUser.props,
        equals([
          'test-id',
          'test@example.com',
          'Test User',
          'https://example.com/photo.jpg',
          true,
          '2024-01-01T00:00:00Z',
          const {},
        ]),
      );
    });

    test('should handle null values correctly', () {
      const userWithNulls = User(
        id: 'test-id',
        email: 'test@example.com',
        displayName: null,
        photoUrl: null,
        isEmailVerified: false,
        createdAt: '2024-01-01T00:00:00Z',
        customClaims: {},
      );

      expect(userWithNulls.displayName, isNull);
      expect(userWithNulls.photoUrl, isNull);
      expect(userWithNulls.isEmailVerified, isFalse);
    });

    test('should validate email format', () {
      expect(tUser.hasValidEmail, isTrue);

      const invalidEmailUser = User(
        id: 'test-id',
        email: 'invalid-email',
        displayName: 'Test User',
        photoUrl: null,
        isEmailVerified: false,
        createdAt: '2024-01-01T00:00:00Z',
        customClaims: {},
      );

      expect(invalidEmailUser.hasValidEmail, isFalse);
    });

    test('should check if user profile is complete', () {
      expect(tUser.isProfileComplete, isTrue);

      const incompleteUser = User(
        id: 'test-id',
        email: 'test@example.com',
        displayName: null,
        photoUrl: null,
        isEmailVerified: false,
        createdAt: '2024-01-01T00:00:00Z',
        customClaims: {},
      );

      expect(incompleteUser.isProfileComplete, isFalse);
    });
  });
}

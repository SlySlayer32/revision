import 'package:flutter_test/flutter_test.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';

void main() {
  group('User', () {
    const id = 'test-id';
    const email = 'test@example.com';
    const displayName = 'John Doe';
    const photoUrl = 'https://example.com/photo.jpg';

    test('supports value comparisons', () {
      const user1 = User(
        id: id,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        isEmailVerified: true,
      );

      const user2 = User(
        id: id,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        isEmailVerified: true,
      );

      expect(user1, equals(user2));
    });

    test('creates a user with required properties', () {
      const user = User(
        id: id,
        email: email,
      );

      expect(user.id, equals(id));
      expect(user.email, equals(email));
      expect(user.displayName, isNull);
      expect(user.photoUrl, isNull);
      expect(user.isEmailVerified, isFalse);
    });

    test('creates a user with all properties', () {
      const user = User(
        id: id,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        isEmailVerified: true,
      );

      expect(user.id, equals(id));
      expect(user.email, equals(email));
      expect(user.displayName, equals(displayName));
      expect(user.photoUrl, equals(photoUrl));
      expect(user.isEmailVerified, isTrue);
    });

    test('props returns correct list', () {
      const user = User(
        id: id,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        isEmailVerified: true,
      );

      expect(
        user.props,
        equals([id, email, displayName, photoUrl, true]),
      );
    });
  });
}

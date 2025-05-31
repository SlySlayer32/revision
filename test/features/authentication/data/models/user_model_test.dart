import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/features/authentication/data/models/user_model.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';

class MockFirebaseUser extends Mock implements firebase_auth.User {}

void main() {
  group('UserModel', () {
    const id = 'test-id';
    const email = 'test@example.com';
    const displayName = 'John Doe';
    const photoUrl = 'https://example.com/photo.jpg';

    test('should be a subclass of User entity', () {
      const userModel = UserModel(id: id, email: email);
      expect(userModel, isA<User>());
    });

    test('should create UserModel with required properties', () {
      const userModel = UserModel(id: id, email: email);

      expect(userModel.id, equals(id));
      expect(userModel.email, equals(email));
      expect(userModel.displayName, isNull);
      expect(userModel.photoUrl, isNull);
      expect(userModel.isEmailVerified, isFalse);
    });

    test('should create UserModel with all properties', () {
      const userModel = UserModel(
        id: id,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        isEmailVerified: true,
      );

      expect(userModel.id, equals(id));
      expect(userModel.email, equals(email));
      expect(userModel.displayName, equals(displayName));
      expect(userModel.photoUrl, equals(photoUrl));
      expect(userModel.isEmailVerified, isTrue);
    });

    test('should convert from Firebase User', () {
      // Arrange
      final firebaseUser = MockFirebaseUser();
      when(() => firebaseUser.uid).thenReturn(id);
      when(() => firebaseUser.email).thenReturn(email);
      when(() => firebaseUser.displayName).thenReturn(displayName);
      when(() => firebaseUser.photoURL).thenReturn(photoUrl);
      when(() => firebaseUser.emailVerified).thenReturn(true);

      // Act
      final userModel = UserModel.fromFirebaseUser(firebaseUser);

      // Assert
      expect(userModel.id, equals(id));
      expect(userModel.email, equals(email));
      expect(userModel.displayName, equals(displayName));
      expect(userModel.photoUrl, equals(photoUrl));
      expect(userModel.isEmailVerified, isTrue);
    });

    test('should handle null email from Firebase User', () {
      // Arrange
      final firebaseUser = MockFirebaseUser();
      when(() => firebaseUser.uid).thenReturn(id);
      when(() => firebaseUser.email).thenReturn(null);
      when(() => firebaseUser.displayName).thenReturn(null);
      when(() => firebaseUser.photoURL).thenReturn(null);
      when(() => firebaseUser.emailVerified).thenReturn(false);

      // Act & Assert
      expect(
        () => UserModel.fromFirebaseUser(firebaseUser),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should support value comparisons', () {
      const userModel1 = UserModel(
        id: id,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        isEmailVerified: true,
      );

      const userModel2 = UserModel(
        id: id,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        isEmailVerified: true,
      );

      expect(userModel1, equals(userModel2));
    });

    test('should convert to JSON', () {
      const userModel = UserModel(
        id: id,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        isEmailVerified: true,
      );

      final json = userModel.toJson();

      expect(
        json,
        equals({
          'id': id,
          'email': email,
          'displayName': displayName,
          'photoUrl': photoUrl,
          'isEmailVerified': true,
        }),
      );
    });

    test('should create from JSON', () {
      final json = {
        'id': id,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'isEmailVerified': true,
      };

      final userModel = UserModel.fromJson(json);

      expect(userModel.id, equals(id));
      expect(userModel.email, equals(email));
      expect(userModel.displayName, equals(displayName));
      expect(userModel.photoUrl, equals(photoUrl));
      expect(userModel.isEmailVerified, isTrue);
    });

    test('should handle null values in JSON', () {
      final json = {
        'id': id,
        'email': email,
        'displayName': null,
        'photoUrl': null,
        'isEmailVerified': false,
      };

      final userModel = UserModel.fromJson(json);

      expect(userModel.id, equals(id));
      expect(userModel.email, equals(email));
      expect(userModel.displayName, isNull);
      expect(userModel.photoUrl, isNull);
      expect(userModel.isEmailVerified, isFalse);
    });
  });
}

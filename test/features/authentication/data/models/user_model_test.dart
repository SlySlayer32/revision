import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/features/authentication/data/models/user_model.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';

import '../../../../helpers/helpers.dart';

class MockFirebaseUser extends Mock implements firebase_auth.User {}

class MockUserMetadata extends Mock implements firebase_auth.UserMetadata {}

void main() {
  // Ensure Firebase is initialized before tests run
  setUpAll(() async {
    try {
      await setupFirebaseAuthMocks();
    } catch (e) {
      // Skip Firebase initialization errors in test environment
      print('Firebase mock setup failed: $e (continuing with tests)');
    }
  });

  group('UserModel', () {
    const id = 'test-id';
    const email = 'test@example.com';
    const displayName = 'John Doe';
    const photoUrl = 'https://example.com/photo.jpg';
    const createdAt = '2023-01-01T12:00:00.000Z';
    const customClaims = <String, dynamic>{};

    test('should be a subclass of User entity', () {
      const userModel = UserModel(
        id: id,
        email: email,
        createdAt: createdAt,
        customClaims: customClaims,
        isEmailVerified: false,
      );
      expect(userModel, isA<User>());
    });

    test('should create UserModel with required properties', () {
      const userModel = UserModel(
        id: id,
        email: email,
        createdAt: createdAt,
        customClaims: customClaims,
        isEmailVerified: false,
      );

      expect(userModel.id, equals(id));
      expect(userModel.email, equals(email));
      expect(userModel.displayName, isNull);
      expect(userModel.photoUrl, isNull);
      expect(userModel.isEmailVerified, isFalse);
      expect(userModel.createdAt, equals(createdAt));
      expect(userModel.customClaims, equals(customClaims));
    });

    test('should create UserModel with all properties', () {
      const userModel = UserModel(
        id: id,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        isEmailVerified: true,
        createdAt: createdAt,
        customClaims: <String, dynamic>{'role': 'admin'},
      );

      expect(userModel.id, equals(id));
      expect(userModel.email, equals(email));
      expect(userModel.displayName, equals(displayName));
      expect(userModel.photoUrl, equals(photoUrl));
      expect(userModel.isEmailVerified, isTrue);
      expect(userModel.createdAt, equals(createdAt));
      expect(
        userModel.customClaims,
        equals(<String, dynamic>{'role': 'admin'}),
      );
    });

    test('should convert from Firebase User', () {
      // Arrange
      final firebaseUser = MockFirebaseUser();
      final mockMetadata = MockUserMetadata();
      when(() => firebaseUser.uid).thenReturn(id);
      when(() => firebaseUser.email).thenReturn(email);
      when(() => firebaseUser.displayName).thenReturn(displayName);
      when(() => firebaseUser.photoURL).thenReturn(photoUrl);
      when(() => firebaseUser.emailVerified).thenReturn(true);
      when(() => firebaseUser.metadata).thenReturn(mockMetadata);
      when(() => mockMetadata.creationTime)
          .thenReturn(DateTime.parse(createdAt));

      // Act
      final userModel = UserModel.fromFirebaseUser(firebaseUser);

      // Assert
      expect(userModel.id, equals(id));
      expect(userModel.email, equals(email));
      expect(userModel.displayName, equals(displayName));
      expect(userModel.photoUrl, equals(photoUrl));
      expect(userModel.isEmailVerified, isTrue);
      expect(userModel.createdAt, equals(createdAt));
      expect(userModel.customClaims, equals(const <String, dynamic>{}));
    });

    test('should handle null email from Firebase User', () {
      // Arrange
      final firebaseUser = MockFirebaseUser();
      final mockMetadata = MockUserMetadata();
      when(() => firebaseUser.uid).thenReturn(id);
      when(() => firebaseUser.email).thenReturn(
        null,
      ); // email is non-nullable in UserModel constructor fromFirebaseUser
      when(() => firebaseUser.displayName).thenReturn(null);
      when(() => firebaseUser.photoURL).thenReturn(null);
      when(() => firebaseUser.emailVerified).thenReturn(false);
      when(() => firebaseUser.metadata).thenReturn(mockMetadata);
      when(() => mockMetadata.creationTime)
          .thenReturn(DateTime.parse(createdAt));

      // Act
      final userModel = UserModel.fromFirebaseUser(firebaseUser);

      // Assert
      expect(userModel.email, ''); // Defaults to empty string
      expect(userModel.isEmailVerified, isFalse);
      expect(userModel.createdAt, createdAt);
    });

    test('should support value comparisons', () {
      const userModel1 = UserModel(
        id: id,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        isEmailVerified: true,
        createdAt: createdAt,
        customClaims: customClaims,
      );

      const userModel2 = UserModel(
        id: id,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        isEmailVerified: true,
        createdAt: createdAt,
        customClaims: customClaims,
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
        createdAt: createdAt,
        customClaims: <String, dynamic>{'role': 'user'},
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
          'customClaims': <String, dynamic>{'role': 'user'},
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
        'createdAt': createdAt,
        'customClaims': {'type': 'tester'},
      };

      final userModel = UserModel.fromJson(json);

      expect(userModel.id, equals(id));
      expect(userModel.email, equals(email));
      expect(userModel.displayName, equals(displayName));
      expect(userModel.photoUrl, equals(photoUrl));
      expect(userModel.isEmailVerified, isTrue);
      expect(userModel.createdAt, equals(createdAt));
      expect(userModel.customClaims, equals({'type': 'tester'}));
    });

    test('should handle null values in JSON', () {
      final json = {
        'id': id,
        'email': email,
        'displayName': null,
        'photoUrl': null,
        'isEmailVerified': false,
        'createdAt':
            createdAt, // Assuming createdAt would still be present or defaulted
        'customClaims':
            null, // or an empty map depending on desired behavior fromMap
      };

      final userModel = UserModel.fromJson(json);

      expect(userModel.id, equals(id));
      expect(userModel.email, equals(email));
      expect(userModel.displayName, isNull);
      expect(userModel.photoUrl, isNull);
      expect(userModel.isEmailVerified, isFalse);
      expect(userModel.createdAt, equals(createdAt));
      expect(
        userModel.customClaims,
        equals(<String, dynamic>{}),
      ); // Defaults to empty map if null
    });
  });
}

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:revision/features/authentication/domain/usecases/get_auth_state_changes_usecase.dart';

class MockAuthenticationRepository extends Mock
    implements AuthenticationRepository {}

void main() {
  group('GetAuthStateChangesUseCase', () {
    late GetAuthStateChangesUseCase useCase;
    late MockAuthenticationRepository mockRepository;
    late StreamController<User?> streamController;

    setUp(() {
      mockRepository = MockAuthenticationRepository();
      useCase = GetAuthStateChangesUseCase(mockRepository);
      streamController = StreamController<User?>();
    });

    tearDown(() {
      streamController.close();
    });

    test('should return stream of auth state changes', () {
      // Arrange
      when(() => mockRepository.authStateChanges)
          .thenAnswer((_) => streamController.stream);

      // Act
      final stream = useCase();

      // Assert
      expect(stream, equals(streamController.stream));
      verify(() => mockRepository.authStateChanges).called(1);
    });

    test('should emit user when user signs in', () async {
      // Arrange
      const user = User(
        id: '1',
        email: 'test@example.com',
        displayName: 'Test User 1',
        photoUrl: null,
        isEmailVerified: true,
        createdAt: '2023-01-01T00:00:00Z',
        customClaims: {},
      );
      when(() => mockRepository.authStateChanges)
          .thenAnswer((_) => streamController.stream);

      // Act
      final stream = useCase();
      streamController.add(user);

      // Assert
      await expectLater(stream, emits(user));
    });

    test('should emit null when user signs out', () async {
      // Arrange
      when(() => mockRepository.authStateChanges)
          .thenAnswer((_) => streamController.stream);

      // Act
      final stream = useCase();
      streamController.add(null);

      // Assert
      await expectLater(stream, emits(null));
    });

    test('should emit multiple state changes', () async {
      // Arrange
      const user1 = User(
        id: '1',
        email: 'test1@example.com',
        displayName: 'Test User 1',
        photoUrl: null,
        isEmailVerified: true,
        createdAt: '2023-01-01T00:00:00Z',
        customClaims: {},
      );
      const user2 = User(
        id: '2',
        email: 'test2@example.com',
        displayName: 'Test User 2',
        photoUrl: null,
        isEmailVerified: true,
        createdAt: '2023-01-02T00:00:00Z',
        customClaims: {},
      );
      when(() => mockRepository.authStateChanges)
          .thenAnswer((_) => streamController.stream); // Act
      final stream = useCase();
      streamController
        ..add(user1)
        ..add(null)
        ..add(user2);

      // Assert
      await expectLater(
        stream,
        emitsInOrder([user1, null, user2]),
      );
    });
  });
}

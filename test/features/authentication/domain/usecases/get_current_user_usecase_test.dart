import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/core/error/failures.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/repositories/auth_repository.dart';
import 'package:revision/features/authentication/domain/usecases/get_current_user_usecase.dart';

class MockAuthenticationRepository extends Mock implements AuthRepository {}

void main() {
  group('GetCurrentUserUseCase', () {
    late GetCurrentUserUseCase useCase;
    late MockAuthenticationRepository mockRepository;

    setUp(() {
      mockRepository = MockAuthenticationRepository();
      useCase = GetCurrentUserUseCase(mockRepository);
    });

    test('should return current user when user is signed in', () async {
      // Arrange
      const user = User(
        id: '1',
        email: 'test@example.com',
        displayName: 'Test User',
        photoUrl: null,
        isEmailVerified: true,
        createdAt: '2023-01-01T00:00:00Z',
        customClaims: <String, dynamic>{},
      );
      when(() => mockRepository.getCurrentUser())
          .thenAnswer((_) async => const Right<Failure, User?>(user));

      // Act
      final result = await useCase();

      // Assert
      expect(result, equals(const Right<Failure, User?>(user)));
      verify(() => mockRepository.getCurrentUser()).called(1);
    });

    test('should return null when no user is signed in', () async {
      // Arrange
      when(() => mockRepository.getCurrentUser())
          .thenAnswer((_) async => const Right<Failure, User?>(null));

      // Act
      final result = await useCase();

      // Assert
      expect(result, equals(const Right<Failure, User?>(null)));
      verify(() => mockRepository.getCurrentUser()).called(1);
    });
  });
}

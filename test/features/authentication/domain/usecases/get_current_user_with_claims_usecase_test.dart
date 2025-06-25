import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/core/error/failures.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/repositories/auth_repository.dart';
import 'package:revision/features/authentication/domain/usecases/get_current_user_with_claims_usecase.dart';

class MockAuthenticationRepository extends Mock implements AuthRepository {}

void main() {
  group('GetCurrentUserWithClaimsUseCase', () {
    late GetCurrentUserWithClaimsUseCase useCase;
    late MockAuthenticationRepository mockRepository;

    setUp(() {
      mockRepository = MockAuthenticationRepository();
      useCase = GetCurrentUserWithClaimsUseCase(mockRepository);
    });

    const userWithClaims = User(
      id: '1',
      email: 'test@example.com',
      displayName: 'Admin User',
      photoUrl: null,
      isEmailVerified: true,
      createdAt: '2023-01-01T00:00:00Z',
      customClaims: {'role': 'admin', 'premium': true},
    );

    const userWithoutClaims = User(
      id: '2',
      email: 'test2@example.com',
      displayName: 'Regular User',
      photoUrl: null,
      isEmailVerified: true,
      createdAt: '2023-01-02T00:00:00Z',
      customClaims: <String, dynamic>{},
    );

    test(
        'should return user from repository (claims handling is not part of this use case currently)',
        () async {
      // Arrange
      when(() => mockRepository.getCurrentUser())
          .thenAnswer((_) async => const Right<Failure, User?>(userWithClaims));

      // Act
      final result = await useCase();

      // Assert
      expect(result, equals(const Right<Failure, User?>(userWithClaims)));
      verify(() => mockRepository.getCurrentUser()).called(1);
    });

    test('should return null when no user is authenticated', () async {
      // Arrange
      when(() => mockRepository.getCurrentUser())
          .thenAnswer((_) async => const Right<Failure, User?>(null));

      // Act
      final result = await useCase();

      // Assert
      expect(result, equals(const Right<Failure, User?>(null)));
      verify(() => mockRepository.getCurrentUser()).called(1);
    });

    test('should return failure when repository returns failure', () async {
      // Arrange
      const failure = AuthenticationFailure('Failed to get user with claims');
      when(() => mockRepository.getCurrentUser())
          .thenAnswer((_) async => const Left<Failure, User?>(failure));

      // Act
      final result = await useCase();

      // Assert
      expect(result, equals(const Left<Failure, User?>(failure)));
      verify(() => mockRepository.getCurrentUser()).called(1);
    });

    test(
        'should return user without claims from repository (claims handling is not part of this use case currently)',
        () async {
      // Arrange
      when(() => mockRepository.getCurrentUser()).thenAnswer(
        (_) async => const Right<Failure, User?>(userWithoutClaims),
      );

      // Act
      final result = await useCase();

      // Assert
      expect(result, equals(const Right<Failure, User?>(userWithoutClaims)));
      verify(() => mockRepository.getCurrentUser()).called(1);
    });
  });
}

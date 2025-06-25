import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:revision/core/error/failures.dart';
import 'package:revision/features/authentication/domain/entities/user.dart';
import 'package:revision/features/authentication/domain/repositories/auth_repository.dart';
import 'package:revision/features/authentication/domain/usecases/get_custom_claims_usecase.dart';

class MockAuthenticationRepository extends Mock implements AuthRepository {}

void main() {
  group('GetCustomClaimsUseCase', () {
    late GetCustomClaimsUseCase useCase;
    late MockAuthenticationRepository mockRepository;

    setUp(() {
      mockRepository = MockAuthenticationRepository();
      useCase = GetCustomClaimsUseCase(mockRepository);
    });

    const tUserWithClaims = User(
      id: '1',
      email: 'test@example.com',
      displayName: 'Admin User',
      photoUrl: null,
      isEmailVerified: true,
      createdAt: '2023-01-01T00:00:00Z',
      customClaims: {'role': 'admin', 'premium': true},
    );
    const tUserWithoutClaims = User(
      id: '2',
      email: 'test2@example.com',
      displayName: 'Regular User',
      photoUrl: null,
      isEmailVerified: true,
      createdAt: '2023-01-02T00:00:00Z',
      customClaims: <String, dynamic>{},
    );
    // tUserNull is represented by Right<Failure, User?>(null) directly in the test

    test(
        'should return custom claims from user when repository returns user with claims',
        () async {
      // Arrange
      when(() => mockRepository.getCurrentUser()).thenAnswer(
        (_) async => const Right<Failure, User?>(tUserWithClaims),
      );

      // Act
      final result = await useCase();

      // Assert
      expect(
        result,
        equals(
          const Right<Failure, Map<String, dynamic>>(
            {'role': 'admin', 'premium': true},
          ),
        ),
      );
      verify(() => mockRepository.getCurrentUser()).called(1);
    });

    test('should return empty map when repository returns user without claims',
        () async {
      // Arrange
      when(() => mockRepository.getCurrentUser()).thenAnswer(
        (_) async => const Right<Failure, User?>(tUserWithoutClaims),
      );

      // Act
      final result = await useCase();

      // Assert
      expect(result, equals(const Right<Failure, Map<String, dynamic>>({})));
      verify(() => mockRepository.getCurrentUser()).called(1);
    });
    test('should return empty map when repository returns null user', () async {
      // Arrange
      when(() => mockRepository.getCurrentUser())
          .thenAnswer((_) async => const Right<Failure, User?>(null));

      // Act
      final result = await useCase();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right but got Left: $failure'),
        (claims) => expect(claims, isEmpty),
      );
      verify(() => mockRepository.getCurrentUser()).called(1);
    });

    test('should return failure when repository returns failure', () async {
      // Arrange
      const tFailure = AuthenticationFailure('Failed to get user');
      when(() => mockRepository.getCurrentUser())
          .thenAnswer((_) async => const Left<Failure, User?>(tFailure));

      // Act
      final result = await useCase();

      // Assert
      expect(
        result,
        equals(const Left<Failure, Map<String, dynamic>>(tFailure)),
      );
      verify(() => mockRepository.getCurrentUser()).called(1);
    });
  });
}
